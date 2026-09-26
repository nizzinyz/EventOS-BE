# Marketplace integration

All routes require the existing JWT (`Authorization: Bearer …`). User IDs in responses are public UUIDs. Event and venue responses use camelCase to match the existing frontend services. Request fields use snake_case.

| Endpoint | Behavior |
| --- | --- |
| `GET /api/events` | Published events and the caller's own drafts/cancelled events |
| `GET /api/events?saved=true` | Visible events saved by the caller |
| `GET /api/events/:id` | Published event or organizer's own event |
| `POST /api/events` | Create an event owned by the caller; default status is draft |
| `PATCH /api/events/:id` | Owner-only edits, publish or cancel |
| `DELETE /api/events/:id` | Owner-only; rejects events with issued tickets |
| `GET /api/events/:event_id/reaction` | Caller-specific liked/saved flags |
| `PATCH /api/events/:event_id/reaction` | Update `{ reaction: { saved: true, liked: true } }` |
| `GET /api/venues`, `GET /api/venues/:id` | Venue listings/details |
| `POST /api/venues` | Create a venue owned by the caller |
| `PATCH /api/venues/:id`, `DELETE /api/venues/:id` | Owner-only; deletion blocked by linked events/enquiries |
| `GET /api/config` | Public runtime capabilities: local preview and mock checkout |
| `GET /api/orders`, `POST /api/orders` | Private order history and free/mock checkout |
| `POST /api/events/:event_id/check_ins` | Organizer-only one-time check-in using ticket code |
| `GET /api/tickets` | Only the caller's tickets, including event/venue details |
| `POST /api/tickets` | Reserve one free general-admission ticket |
| `GET /api/booking_requests` | Caller's enquiries plus enquiries for venues they own |
| `POST /api/booking_requests` | Request venue availability |
| `PATCH /api/booking_requests/:id` | Venue owner accepts/declines a pending enquiry |
| `PATCH /api/users/:public_id` | Existing owner-only profile API, extended with bio/city/interests/email_updates |

## Ticket reservation

```json
{ "event_id": "123", "request_key": "550e8400-e29b-41d4-a716-446655440000" }
```

Keep the same UUID when retrying a request. An event row lock serializes reservations and event edits; the server checks publication, date, price and capacity. A unique user/request-key index prevents repeat issuance. This legacy endpoint is retained for compatibility. The app uses orders with a pending request saved in session storage so retries survive reloads in the same tab. Multiple tickets per attendee are permitted.

The legacy single-ticket endpoint still rejects paid ticket issuance. The app now uses `/api/orders` for free and mock paid checkout. Tickets have QR payloads `roam-ticket:<code>`; only the owning organizer can consume them through the check-in endpoint. No payment or refund is performed.

## Venue enquiry

```json
{
  "booking_request": {
    "venue_id": "12",
    "event_date": "2027-01-20",
    "guests": 50,
    "message": "An evening community meetup."
  }
}
```

Reply with `{ "booking_request": { "status": "accepted" } }` or `declined`.
Enquiries validate the date, venue availability and guest count. Acceptance does not lock a calendar date, approve an event's use of the venue, charge a customer, or send an email.

## Local setup

```sh
docker compose up -d --build
```

The normal startup runs `db:prepare`. `ruby-vips` is included because the installed `image_processing` version requires it at boot.

The existing local database had events/venues absent from the committed migration history. The marketplace migration preserves those tables and adds the missing event capacity. New databases create the complete marketplace schema. Legacy records with missing owners are displayed without assigning ownership to another user. Existing venue capacities and data are retained; constraints on legacy tables are added without validating old rows. New writes must satisfy the constraints. Rolling this migration back is deliberately unsupported because the tables may predate this change.

Tests were run against a separate database to avoid resetting existing development/test data:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:password@db:5432/roam_marketplace_test web bin/rails db:prepare
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:password@db:5432/roam_marketplace_test web bin/rails test
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:password@db:5432/roam_marketplace_test web bin/rails zeitwerk:check
```

## Manual acceptance flow

1. Sign in, edit profile/preferences, save, reload and verify persistence.
2. Create a venue, then create a free event linked to it with capacity within the venue limit.
3. Open Profile, publish the draft, and view it through discovery and its venue page.
4. Reserve a ticket; verify My tickets, event/venue links and directions. Fill capacity and check sold-out behavior.
5. Save/like an event, reload, and verify the saved page.
6. From another account, submit a venue enquiry; as owner accept/decline in Profile; verify the requester's status.
7. Verify another account cannot edit a listing, see a draft, read another user's tickets or answer a venue owner's enquiries.

Full scope and remaining work: [MVP checklist](MVP_CHECKLIST.md).

## Checkout and map additions

See [local testing](LOCAL_TESTING.md) for checkout payloads, local confirmation behavior and map configuration. Events and venues accept optional `latitude`/`longitude` together. Events linked to venues use the venue pin.
