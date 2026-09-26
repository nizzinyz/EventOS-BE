# Event Marketplace MVP checklist

Source: `Event_Marketplace_MVP_V1_Feature_List.pdf`, supplied by the user.
Reviewed against `EventOS-BE/eos-venues-be` and `EventOS-FE/roam-web` on 2026-09-26.

Checked means the stated scope is implemented. Partial items remain unchecked.
Backend integration tests cover the new flows. Browser tests exercise registration, listing creation, checkout, retry recovery, ticket QR codes, check-in and map markers. Local preview defers email confirmation and enables mock checkout; production cannot enable preview mode.

## Authentication

- [x] User registration - API and browser-tested. Local preview allows immediate login without falsely marking email verified.
- [x] Login — existing JWT flow.
- [ ] Google Sign-In (optional) — existing OAuth code; provider configuration and end-to-end testing remain.
- [ ] Password reset — existing API; frontend reset screens and email-link completion remain.
- [ ] Role-based access (Attendee, Organizer, Venue Owner, Admin) — resource ownership is enforced; explicit roles and admin permissions remain. Any authenticated user can create listings.

## Venue marketplace

- [x] Venue listings — persisted API connected to discovery and creation.
- [ ] Photo gallery — one image URL supported; multiple images and uploads remain.
- [x] Venue details — connected API, details, and upcoming published events.
- [x] Availability calendar — venue owners set opening days, hours, slot length and blocked dates; guests select live slots and completed bookings prevent overlaps.
- [x] Search & filters — discovery searches names, descriptions and cities, with category/city filters and sorting.
- [x] Instant venue booking — guests choose a day, available slot and guest count, then use checkout. Historical enquiries remain available for venues that still need them.

## Event management

- [x] Create/Edit/Delete events — creators can create, reschedule, edit admission and ticketing, publish/cancel and delete their events. Ticketed events cannot be deleted or returned to draft.
- [x] Event page — live event details, venue link, availability and reservation action.
- [x] Categories — creation and discovery filters.
- [x] Capacity — persisted, validated against venue capacity, enforced during ticket issuance.
- [x] Draft/Publish — organizer controls in profile; drafts hidden from other users; cancellation supported. Ticketed events cannot be deleted or returned to draft.

## Ticketing

- [ ] Ticket types — general admission only; named tiers, separate inventory and pricing remain.
- [ ] Secure checkout — mock checkout supports ticket and venue purchases with server-priced records, success/decline/cancel outcomes and safe retry recovery. Real payment integration, verified callbacks, refunds and inventory holds remain.
- [x] QR code tickets - downloadable QR images and organizer-only one-time check-in by scanned text or ticket reference. Built-in camera scanning remains an enhancement.
- [x] Digital tickets - themed entry-pass wallet, QR downloads, check-in status, directions, order history and venue booking confirmations.
- [ ] Confirmation emails — not implemented for tickets.

## Event discovery

- [x] Browse events — published events from the API; Explore now uses the discovery screen.
- [x] Search — discovery and top navigation search connected via URL query.
- [x] Categories — event filters include the creation categories.
- [x] Nearby events - Leaflet/OpenStreetMap, exact pins, event/venue filters, city search, optional geolocation and distance filters. City-only legacy listings are labelled approximate and excluded from distance filtering.
- [ ] Featured events — existing featured records are displayed/sorted; trusted curation controls remain. Clients cannot grant themselves featured status.

## Dashboards

- [ ] Organizer dashboard — basic owned-event listing, ticket counts, edit/publish/cancel/delete controls in profile; revenue, attendee management and reporting remain.
- [x] Venue dashboard — venue owners configure instant booking, ticket/pass option, opening days/hours, slot duration and blocked dates. Reporting remains.
- [x] Upcoming bookings — private customer booking wallet and owner booking list with confirmed slot inventory.
- [x] Upcoming events — ticket wallet, profile event dates and upcoming events at each venue.

## Notifications

- [ ] Booking confirmations — status visible in profile; notification delivery remains.
- [ ] Ticket confirmations — immediate success and ticket wallet; email/push/in-app inbox remains.
- [ ] Event reminders — not implemented.

## Admin

- [ ] User management.
- [ ] Venue moderation.
- [ ] Event moderation.

## Additional frontend integrations

- [x] Profile: name, bio, city, avatar URL, interests and email preference persisted to the user API.
- [x] Settings: device appearance, verification status, connected-provider summary, member date and sign out.
- [x] Account navigation uses the authenticated user's initials and opens the profile.
- [x] Saved events and likes persist per account; saved page loads from the API.
- [ ] Saved venues.
- [ ] Account email/password changes, deletion UI and notification delivery preferences beyond the stored opt-in.

## Verification and running locally

- Frontend: `npm run build` succeeds.
- Backend: 25 integration tests, 160 assertions, zero failures/errors; Rails autoload check succeeds.
- New Ruby files pass the configured RuboCop checks.
- Frontend: repository-wide npm run lint succeeds after cleaning up context exports and mobile navigation lifecycle.
- Playwright covers signup/login, event and venue checkout, slot collision handling, mock decline/cancel/success, retry recovery, optional ticketing, QR display, check-in, map markers and responsive discovery. Map tiles are stubbed in automated tests. External OAuth, outbound email, real payments and concurrent load testing remain.

See [marketplace API and local verification](marketplace_api.md) for endpoints and test commands.

## Suggested next work

1. Add ticket tiers, then connect existing orders to the custom-paystack-sdk with verified payments, inventory holds and webhook idempotency.
2. Add built-in camera scanning, ticket tiers, transfers and attendee management.
3. Complete venue reservation inventory, conflict prevention and calendar UI.
4. Add email delivery and reminders, explicit roles, and moderation tools.

## Local preview guide

See [testing signup, mock checkout and maps](LOCAL_TESTING.md). Email delivery, real payments and hosting remain deferred.
