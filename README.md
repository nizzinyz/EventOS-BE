# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

- Ruby version

- System dependencies

- Configuration

- Database creation

- Database initialization

- How to run the test suite

- Services (job queues, cache servers, search engines, etc.)

- Deployment instructions

- ...

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
available at http://localhost:3000.

```sh
docker compose up --build
```

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
