# User API

All user-management endpoints a client can call. Base path: `/api`.

**Authentication model:** JWT (Bearer token). Signing in returns a JWT in the
`Authorization` response header (`Authorization: Bearer <token>`); the client
must send that same header on every protected request. Tokens expire after
24 hours. Signing out revokes **all** of a user's outstanding tokens.

All request/response bodies are JSON. User `id` values are public UUIDs.

---

## Registration

### `POST /api/auth` — Sign up

Creates an account and sends a confirmation email. The user **cannot sign in
until the email is confirmed**.

```json
{
  "user": {
    "email": "jane@example.com",
    "password": "supersecret1",
    "password_confirmation": "supersecret1",
    "first_name": "Jane",
    "last_name": "Doe",
    "date_of_birth": "2000-01-31"   // optional
  }
}
```

- `200 OK` — `{ "status": {...}, "data": <user> }`
- `422 Unprocessable Entity` — `{ "status": {...}, "errors": [...] }`

Password rules: 8–128 characters.

### `PATCH /api/auth` or `PUT /api/auth` — Update own account (auth required)

Body accepts `first_name`, `last_name`, `date_of_birth`, `avatar_url`, and
`password` + `password_confirmation` + `current_password` (Devise requires
`current_password` to change the password via this endpoint).

### `DELETE /api/auth` — Delete own account (auth required)

---

## Sessions

### `POST /api/auth/sign_in` — Sign in

```json
{ "user": { "email": "jane@example.com", "password": "supersecret1" } }
```

- `200 OK` — body `{ "status": {...}, "data": <user> }`; **JWT is in the
  `Authorization` response header.**
- `401 Unauthorized` — bad credentials, unconfirmed email, or locked account.
  (10 failed attempts locks the account for 1 hour or until email unlock.)

### `DELETE /api/auth/sign_out` — Sign out (auth required)

Revokes every outstanding token for the user.

- `200 OK` — `{ "status": { "code": 200, "message": "Logged out successfully." } }`
- `401 Unauthorized` — no active session.

---

## Password reset

### `POST /api/auth/password` — Request reset email

```json
{ "user": { "email": "jane@example.com" } }
```

- `200 OK` — reset instructions sent (token valid 6 hours).

### `PUT /api/auth/password` — Reset with token

```json
{
  "user": {
    "reset_password_token": "<token from email>",
    "password": "newsecret1",
    "password_confirmation": "newsecret1"
  }
}
```

- `200 OK` / `422` with `errors`.

---

## Email confirmation

### `POST /api/auth/confirmation` — Resend confirmation email

```json
{ "user": { "email": "jane@example.com" } }
```

### `GET /api/auth/confirmation?confirmation_token=<token>` — Confirm

Hit from the link in the email. Redirects the browser to
`FRONTEND_URL/email-confirmed` (or `?error=invalid_token` on failure).

---

## Account unlock

### `POST /api/auth/unlock` — Resend unlock email

```json
{ "user": { "email": "jane@example.com" } }
```

### `GET /api/auth/unlock?unlock_token=<token>` — Unlock account

Hit from the link in the email.

---

## OAuth (Google, Apple)

Browser-redirect flow using a one-time exchange code so the JWT never appears
in a URL:

1. Client redirects the browser to `GET /api/auth/auth/google_oauth2`
   (or `/api/auth/auth/apple`).
2. Provider authenticates, then redirects back to the callback
   (`/api/auth/auth/<provider>/callback` — handled server-side).
3. On success the server redirects to `FRONTEND_URL/auth/callback?code=<one-time code>`.
   On failure: `FRONTEND_URL/login?error=oauth_failed`.
4. Client exchanges the code within **60 seconds**:

### `POST /api/auth/exchange`

```json
{ "code": "<one-time code>" }
```

- `200 OK` — `{ "token": "<jwt>", "user": <user> }`
- `400 Bad Request` — missing code.
- `401 Unauthorized` — code expired or already used (single-use).

If the provider email matches an existing account, the OAuth identity is
linked to it. OAuth-created accounts are auto-confirmed and have no password
(one can be set later via the password-reset flow).

---

## Users (auth required)

Users can only operate on **their own** account; any other `:id` returns `404`.

### `GET /api/users/:id` — Fetch profile

- `200 OK` — `{ "data": <user> }`

### `PATCH /api/users/:id` — Update profile

```json
{ "user": { "first_name": "...", "last_name": "...", "date_of_birth": "...", "avatar_url": "..." } }
```

- `200 OK` / `422` with `errors`. (Email and password changes go through
  `PATCH /api/auth` instead.)

### `DELETE /api/users/:id` — Delete account

- `204 No Content`

---

## The user object

Returned as `data` by auth and user endpoints:

```json
{
  "id": "8973be83-63be-427a-8a63-ff3b2948eb6f",
  "email": "jane@example.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "full_name": "Jane Doe",
  "avatar_url": null,
  "confirmed": true,
  "linked_providers": ["google_oauth2"],
  "created_at": "2026-07-31T11:06:24.602Z"
}
```

---

## Errors (all protected endpoints)

- `401 Unauthorized` — missing/invalid/expired/revoked JWT.
- `404 Not Found` — `{ "error": "..." }`
- `422 Unprocessable Entity` — `{ "errors": ["..."] }`

## Required environment variables

See `.env.example`: `DEVISE_JWT_SECRET_KEY`, the three
`ACTIVE_RECORD_ENCRYPTION_*` keys, `FRONTEND_URL`, mailer + OAuth provider
credentials.
