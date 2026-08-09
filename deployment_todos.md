# Production Deployment TODO

Things to sort out before the first real production deploy. Roughly in order.

## Secrets & keys

- [ ] Decide on a secrets approach: env vars set on the deploy machine (current
      leaning) vs. reviving Rails encrypted credentials. See commented-out
      `RAILS_MASTER_KEY` lines in `config/deploy.yml`, `.kamal/secrets`, and
      `.github/workflows/ci.yml` if going the credentials route.
- [ ] Generate a `SECRET_KEY_BASE` and set it on the production machine:
      1. Run `bin/rails secret` locally to generate the value.
      2. Store it in the secrets manager.
      3. Set it as the `SECRET_KEY_BASE` env var on the deploy machine
         (for Kamal: add `SECRET_KEY_BASE` under `env.secret` in
         `config/deploy.yml` and define it in `.kamal/secrets`).
      Rails production will not boot without this — it signs/encrypts session
      cookies and other tokens.
- [ ] Set production `DATABASE_URL` (or `DB_HOST` + credentials) the same way.

## Infrastructure

- [ ] Replace the placeholder server IP (`192.168.0.1`) in `config/deploy.yml`.
- [ ] Pick a real container registry (`registry.server` is currently
      `localhost:5555`) and set up an access token.
- [ ] Provision a production Postgres database (managed service or Kamal
      accessory) and point the app at it.
- [ ] Decide on SSL: enable the Kamal `proxy: ssl` block with the real
      hostname, or terminate SSL elsewhere.
- [ ] Set up an object storage bucket (S3 or compatible: R2, DO Spaces, ...)
      for Active Storage — files will not live on the server's disk:
      1. Create the bucket + an access key scoped to it.
      2. Add the `aws-sdk-s3` gem.
      3. Define the service in `config/storage.yml` (bucket, region, endpoint;
         pull the access key/secret from env vars).
      4. Set `config.active_storage.service = :amazon` (or whatever the
         service is named) in `config/environments/production.rb`.
      5. Add the access key/secret to the secrets manager and deploy env.
      Note: the app server has no persistent disk volume (removed from
      `config/deploy.yml`), so this must be done before the app accepts any
      file uploads — files written by the `:local` service are lost on
      redeploy.

## App configuration

- [ ] Review `config/environments/production.rb` (force_ssl/assume_ssl to match
      the SSL decision, log level, mailer host if mail gets added).
- [ ] Confirm allowed hosts / CORS settings for the frontend's domain.

## CI / process

- [ ] Enable the commented-out test env vars in `.github/workflows/ci.yml` if
      credentials or extra secrets become needed for CI.
- [ ] Set up database backups.
- [ ] Do a dry-run deploy (`bin/kamal setup`) against a throwaway server before
      the real one.
