# EOS Venues — backend API

Rails 8 JSON API with JWT auth (Devise), Google/Apple OAuth, and encrypted
PII columns, backed by Postgres. Active development happens on the
`development` branch.

- **API reference:** [docs/user_api.md](docs/user_api.md) — all auth and user
  routes with request/response examples. Auth lives under `/api/auth`
  (note: registration is `POST /api/auth`, sessions are `POST /api/auth/sign_in`).
- **Secrets:** everything comes from `.env` (see setup below);
  `.env.example` documents every variable.

## Running with Docker

The only prerequisite is Docker (with the compose plugin), no local Ruby or
Postgres needed.

### First-time setup: create your `.env`

```sh
cp .env.example .env
```

Then generate the secrets that are blank in the template and paste them in:

```sh
openssl rand -hex 64   # → DEVISE_JWT_SECRET_KEY
openssl rand -hex 16   # run 3x → the three ACTIVE_RECORD_ENCRYPTION_* values
```

The Google/Apple OAuth values are pre-filled with inert dev placeholders —
everything except the actual third-party OAuth handshake works with them (see
the comments in `.env.example`).

### Start the stack

```sh
docker compose up
```

This starts two containers: a Postgres 15 database and the Rails server. On
boot the web container runs `bin/rails db:prepare` automatically, so the
database is created, migrated, and seeded on first run. The app is then
available at http://localhost:3000 (health check: `GET /up`).

After pulling changes that touch the `Gemfile` or Dockerfiles, rebuild the
image:

```sh
docker compose up --build
```

### Connecting a client

CORS is open in development for `http://localhost:3000`, `5173` (Vite),
`8081` and `19006` (Expo) — no config needed for a client on those ports.
If yours runs elsewhere, add it to `CORS_ALLOWED_ORIGINS` in `.env`, and set
`FRONTEND_URL` to your client's URL so OAuth/email redirects land there.

Postgres is published on host port **5433** (not 5432, to avoid clashing
with a locally installed Postgres) if you want to inspect the database with
host tools: `psql -h localhost -p 5433 -U postgres`.

### Common commands

Run these while the stack is up:

```sh
docker compose exec web bin/rails console   # Rails console
docker compose exec web bin/rails test      # run the test suite
docker compose exec web bin/rails db:migrate
docker compose exec web bash                # shell inside the container
```

### Resetting

```sh
docker compose down      # stop containers (database data is kept)
docker compose down -v   # stop containers AND wipe the database volume
```
