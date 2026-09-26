# Testing signup, ticket checkout and maps

## Start the app

Backend (`EventOS-BE/eos-venues-be`):

```sh
docker compose up -d --build
```

Frontend (`EventOS-FE/roam-web`):

```sh
npm install
npm run dev
```

Open `http://localhost:5173`. The default API is `http://localhost:3000`.

Development defaults to `LOCAL_PREVIEW=true`. The app displays a local preview banner. New accounts can sign in immediately and existing unconfirmed accounts can also sign in. Their email remains **unverified**. No confirmation email is sent in preview mode.

Set `LOCAL_PREVIEW=false` and restart Rails to restore the confirmation requirement. Production always requires normal confirmation and rejects mock checkout, even if this environment variable is accidentally enabled. Email delivery and real payment integration are still future work.

## Try buying a ticket

1. Register a new account and choose **Continue to sign in**.
2. Create a venue. Select the city and click the map to set its exact location.
3. Create an event at that venue with a future date, capacity, and a price greater than zero. Save the draft.
4. Open **Profile → Your events** and publish it.
5. Open the event, choose a quantity and a test payment result:
   - **Successful payment:** creates one order and individual QR tickets.
   - **Declined payment:** records the attempt without issuing tickets.
   - **Cancelled checkout:** records cancellation without issuing tickets.
6. Click **Complete mock purchase**. No card details or money are involved.
7. Open **My tickets** for QR downloads, order history, directions and mock-payment labels.
8. As the organizer, open the event and paste a ticket reference or QR contents into **Organizer check-in**. A second check-in is rejected.

Free events use the same order flow without simulated payment outcomes. Tickets from a mock order are permanently labelled `mock`; they never become evidence of a real payment. Mock tickets can only check in while local preview is enabled. Built-in camera scanning is not included; a QR reader can supply the text to the check-in form.

If a checkout response is lost, **Retry checkout** recovers the same order. Pending attempts survive reloads in the same browser tab. Quantities and payment outcomes are locked while recovering that attempt. Check the ticket wallet before starting a new checkout in another tab/device.

## Checkout API

```json
{
  "order": {
    "event_id": "123",
    "request_key": "550e8400-e29b-41d4-a716-446655440000",
    "quantity": 2,
    "payment_mode": "mock",
    "outcome": "completed",
    "expected_unit_amount_cents": 12500
  }
}
```

Send to `POST /api/orders` using the normal JWT. `payment_mode` is `free` or `mock`; `outcome` is `completed`, `declined` or `cancelled`. Free orders only accept `completed`. The server reads the real price from the event, snapshots it on the order, validates the expected price, locks capacity and atomically creates tickets. Quantities are integers from 1 to 10. A repeated request key returns the original order; a changed event/quantity/mode/outcome with that key is rejected. A failed/cancelled attempt uses a new key when trying again.

`GET /api/orders` returns only the caller's orders. `POST /api/events/:id/check_ins` accepts `{ "code": "roam-ticket:<ticket-code>" }` or a bare ticket code. Only that event's organizer is authorized, and cancelled events and already-used tickets are rejected.

## Maps

The app uses [Leaflet](https://leafletjs.com/examples/quick-start/) with [OpenStreetMap tiles](https://operations.osmfoundation.org/policies/tiles/). No API key is required for this development setup. Attribution remains visible and tiles are requested only as the map is viewed, using normal browser caching.

- Create an event/venue with a pin, or use **Edit map pin** on a listing you own.
- Events at listed venues inherit the venue's current coordinates.
- Existing listings without coordinates show an approximate city marker when the city is recognized. Unknown cities remain in results with a missing-pin notice.
- **Map → Near me** requests browser location permission. Distance filters use exact pins only. Denying permission leaves normal city search available.
- Coordinates can also be supplied through the API; both are required together and validated against geographic bounds.
- Pin selection does not geocode or change the written address. Hosts should keep the address and pin consistent.

Before hosting, review the tile provider's usage policy and traffic needs. A different provider can be configured in the frontend with `VITE_MAP_TILE_URL` and `VITE_MAP_ATTRIBUTION`. The provider URL must use Leaflet's `{z}/{x}/{y}` tile placeholders. There is no background geocoding or offline tile download.

## Automated verification

Backend integration suite (separate test database):

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:password@db:5432/roam_marketplace_test web bin/rails db:prepare
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:password@db:5432/roam_marketplace_test web bin/rails test
```

Browser test API (separate from development and the integration-test database):

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:password@db:5432/roam_browser_test web bin/rails db:prepare
docker compose run -d --name roam-browser-test -p 3001:3000 -e RAILS_ENV=test -e LOCAL_PREVIEW=true -e CORS_ALLOWED_ORIGINS=http://localhost:5174 -e DATABASE_URL=postgres://postgres:password@db:5432/roam_browser_test web bin/rails server -b 0.0.0.0 -P /tmp/roam-browser.pid
```

Then in the frontend:

```sh
npx playwright install chromium
npm run test:e2e
```

Playwright starts Vite on port 5174 and runs desktop/mobile flows. Test listings and users stay in `roam_browser_test`. Screenshots and failure traces go to ignored `test-results/`. Community map tiles are replaced with a local image during tests; marker behavior and coordinates are tested without downloading tiles. Stop the isolated API afterward with `docker stop roam-browser-test`; remove the stopped test container before recreating it.
