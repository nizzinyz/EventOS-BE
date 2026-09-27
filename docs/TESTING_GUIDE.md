# ROAM acceptance test guide

Use this checklist against the local environment. Record the date, browser/device, account, expected result, actual result, and a screenshot/reference for every failure. Reset to a known state with `docker compose exec web bin/rails db:seed` between destructive tests.

## Test accounts

| Persona | Account | Password | Purpose |
|---|---|---|---|
| Platform admin | `nizhar123mna@gmail.com` | your normal password | Admin assignment and venue review |
| Organizer | `demo.organizer@roam.local` | `Password123!` | Events, bookings, staff |
| Attendee | `demo.attendee@roam.local` | `Password123!` | Discovery, tickets, saved items |
| Scanner | `demo.scanner@roam.local` | `Password123!` | Entry validation only |
| Venue owner | `demo.venue@roam.local` | `Password123!` | Venue management |

## 1. Authentication and account safety

- Register a new account. Confirm it has the normal `user` platform role and cannot see `/admin` or call `/api/admin/*`.
- Log in and out; reopen the browser and verify protected pages require login after logout.
- Try changing another user profile URL/API identifier. Expect `404`.
- Verify a normal user cannot set `platform_role` through profile update or registration.

## 2. Admin access

- Log in as `nizhar123mna@gmail.com`, refresh the profile, and open **Administration**. Expect the account-access and verification-queue panels.
- Search for a normal account, select **Make admin**, log in as that account, and confirm `/admin` is available.
- Remove that test admin role and confirm `/admin` becomes forbidden after refresh/login.
- Attempt to remove your own admin role. Expect it to be blocked.
- Verify each role decision creates an `admin_audit_logs` record (database/admin audit view when added).

## 3. Venue verification

- As a normal user, create a venue. Expect verification status `draft`; it must not appear in public discovery or offer booking slots.
- Submit ownership evidence: legal/business name, contact name/email/phone, at least one document name/URL/type, and notes. Expect `pending_review`.
- As admin, inspect the submission and its document links. Approve with a reason. Expect the venue status to become `verified`, appear publicly, and return bookable slots when booking is enabled.
- Repeat with another venue and reject it with a reason. Expect `rejected`, no public discovery, and no booking slots.
- Suspend a verified venue. Expect new availability/booking attempts to fail while historical bookings remain readable.
- Verify a venue owner can only submit/retrieve verification records for their own venue; another user must receive `404`.

## 4. Venue availability and booking

- Open **Demo Skyline Rooftop**. Confirm its seeded booking blocks the event window plus setup/cleanup buffers.
- Check **Demo Greenhouse** availability around its seeded blocked period. Expect unavailable slots only for the blocked interval.
- Create a free booking at an available slot; retry the same request and expect one booking (idempotency).
- Try the occupied/buffered slot with a second account. Expect conflict/unavailable.
- Try guest count above venue capacity and invalid dates/times. Expect validation errors.

## 5. Event access and staff

- Organizer creates a draft, edits it, then publishes it. Confirm drafts are hidden from other users.
- Confirm a public ticketed event can be discovered and its `18+` rating/access type is present in API/event details.
- Confirm a private invitation event is visible only to its organizer and assigned staff. Confirm an unlisted event is not in public discovery.
- Add a scanner to an event. As scanner, scan a valid ticket: expect successful check-in. Scan again: expect already used.
- As scanner, attempt event edit, cancellation, ticket-price change, venue booking, and staff management. Expect denial.
- As event manager, confirm event management access. As ticket manager/viewer, verify only their eventual scoped functions are available; document current gaps.

## 6. Ticketing and checkout

- As attendee, reserve/buy the seeded Summer Rooftop Sessions ticket. Confirm ticket appears under **My tickets**, QR can be displayed/downloaded, and order history matches the price.
- Attempt to exceed remaining capacity. Expect a conflict, no over-issued tickets.
- Attempt ticket checkout for invitation and guest-list events. Expect rejection: they are not ticketed events.
- Test declined/cancelled checkout outcomes in local preview; confirm no ticket is issued.

## 7. Regression and security checks

- Browser test desktop and mobile widths: login, discovery, event detail, venue detail, ticket QR, profile, and admin page.
- Confirm API requests without a token return `401`; normal accounts calling admin routes return `403`.
- Confirm no browser request can set a venue directly to `verified` or set a user to admin outside admin routes.
- Confirm rejected/suspended venues cannot accept new bookings.
- Run `docker compose exec web bin/rails test` and `npm run build` before sign-off.

## Exit criteria

Pass when all expected outcomes above are met, there are no privilege-escalation paths, no booking overlap occurs, and all failures have a reproducible report with screenshots and request/response details. Known deliberate gaps to mark separately: real payment callbacks, document file storage/virus scanning, automated business/KYC matching, invitation RSVP fulfilment, ticket tiers, and offline scanner sync.
