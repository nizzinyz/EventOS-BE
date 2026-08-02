# Claude & Secrets

During the initial port of the user-management system (2026-07-31), Claude
generated or had visibility of the secrets below. All of them are regenerable;
rotating them removes any exposure from that session.

| Key | Regenerate with | Consequence of rotating |
|---|---|---|
| `config/master.key` + `credentials.yml.enc` | delete both, then `EDITOR=true bin/rails credentials:edit` | Invalidates anything signed with `secret_key_base` (signed cookies, Active Storage URLs). Harmless while the app has no users. |
| `DEVISE_JWT_SECRET_KEY` (in `.env`) | `openssl rand -hex 64` | Every issued JWT becomes invalid — all users signed out. Harmless while the app has no users. |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `_DETERMINISTIC_KEY`, `_KEY_DERIVATION_SALT` (in `.env`) | `bin/rails db:encryption:init` (prints three fresh values) | **The one that matters:** rows encrypted with the old keys become permanently unreadable (user emails, names, OAuth tokens). Rotate freely **only while the database is empty**. Once real users exist these keys must never change without a re-encryption migration. |
| Google/Apple OAuth credentials | Google Cloud Console / Apple Developer portal | Claude never saw real values — `.env.example` has empty placeholders. |
| Postgres password (`password` in `compose.yaml`) | pick any value, update compose + `DATABASE_URL` | None, dev-only. |

## Suggested rotation order (while DB is empty)

1. `bin/rails db:encryption:init` → paste the three values into `.env`.
2. `openssl rand -hex 64` → paste into `DEVISE_JWT_SECRET_KEY` in `.env`.
3. Optionally redo the credentials pair:
   `rm config/master.key config/credentials.yml.enc && EDITOR=true bin/rails credentials:edit`.

## Notes

- `.env` is gitignored — never commit it. `.env.example` documents the shape.
- `config/credentials.yml.enc.bak` is the pre-port credentials file whose
  master key was lost (the checked-out `master.key` was empty). It is
  undecryptable — delete it unless the original key turns up.
