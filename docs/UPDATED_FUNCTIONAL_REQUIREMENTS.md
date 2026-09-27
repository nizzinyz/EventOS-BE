# ROAM functional requirements — event operations baseline

Reviewed and aligned with the implementation on 2026-09-27. This is the product baseline; it separates delivered foundations from work that remains before a production release.

## Delivered foundation

- Accounts can own events and venues, buy/reserve tickets, save events and hold independent venue bookings.
- Events now have explicit `access_type` (`ticketed`, `invitation`, `guest_list`), age rating, and public/private/unlisted visibility.
- A confirmed `VenueBooking` can be attached to an event only by its booker, for the same venue, and only when the event fits inside its booking window.
- Venues support date blocks, precise blocked periods, and setup/cleanup buffers when calculating bookable slots.
- Events have event-scoped members: event manager, ticket manager, scanner and viewer. Scanners can check in tickets but cannot edit events or financial settings.
- QR check-in remains one-time and is available to the organizer, event managers and scanners.

## Required next increments

1. **Access fulfilment:** model ticket categories and inventory, plus invitations, RSVP answers, guest allowances and guest-list entries. `access_type` is deliberately in place now so these do not become a boolean retrofit.
2. **Invitation/staff delivery:** email invitations, acceptance flows, expiring staff invitations and revocation/audit records. Current staff assignment intentionally requires an existing ROAM account.
3. **Payments:** payment-provider callbacks, booking deposits/policies, refunds, fee/tax breakdowns and a ledger. Never trust a browser-supplied payment result.
4. **Availability:** multi-slot durations, overnight venue hours, owner approval/request-to-book state, and a PostgreSQL exclusion constraint to provide a database-level final guarantee against overlapping confirmed reservations.
5. **Entry operations:** store the checking-in staff member/device/time, offline scan reconciliation, age/DOB validation, ticket transfer and cancellation states.
6. **Privacy/safety:** unlisted share tokens, role-aware private-event guest access, consent-aware attendee export, rate limits, audit logs and media upload validation.

## Acceptance rules

- Date/time must be known before venue availability is shown.
- A completed booking reserves its setup + event + cleanup window; blocks reserve their exact period.
- An event is not a booking: the booking exists independently and may later be linked to exactly one event.
- Private events are visible only to their organizer and assigned staff until guest-access rules are implemented.
- Only a server-authorized scanner or manager may consume a QR credential, and the second scan must report it as already used.
