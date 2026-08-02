# frozen_string_literal: true

# ─────────────────────────────────────────────────────────────────────────────
# Required environment variables (set in .env / platform secrets):
#
#   DEVISE_JWT_SECRET_KEY    – random 128-char hex string (openssl rand -hex 64)
#
#   GOOGLE_CLIENT_ID         – OAuth 2.0 client ID from Google Cloud Console
#   GOOGLE_CLIENT_SECRET     – OAuth 2.0 client secret from Google Cloud Console
#
#   APPLE_CLIENT_ID          – Apple Services ID (e.g. com.yourapp.signin)
#   APPLE_TEAM_ID            – 10-char Apple Developer Team ID
#   APPLE_KEY_ID             – Key ID from the Sign In with Apple key
#   APPLE_PRIVATE_KEY        – PEM string of the .p8 private key
#                              (newlines may be escaped as \n in ENV)
#                              Alternatively place the file at
#                              config/apple_auth_key.p8
# ─────────────────────────────────────────────────────────────────────────────

# Resolve Apple private key from ENV or file.
apple_private_key = if ENV["APPLE_PRIVATE_KEY"].present?
  ENV["APPLE_PRIVATE_KEY"].gsub('\n', "\n")
else
  key_path = Rails.root.join("config", "apple_auth_key.p8")
  key_path.exist? ? File.read(key_path) : ""
end

Devise.setup do |config|
  # ── Mailer ──────────────────────────────────────────────────────────────────
  config.mailer_sender = ENV.fetch("MAILER_FROM", "noreply@example.com")

  # ── ORM ─────────────────────────────────────────────────────────────────────
  require "devise/orm/active_record"

  # ── Case-insensitive email ───────────────────────────────────────────────────
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # ── API-only: no browser redirects or cookie sessions ───────────────────────
  config.navigational_formats = []
  config.skip_session_storage = [:http_auth]
  config.http_authenticatable_on_xhr = false

  # ── Password ─────────────────────────────────────────────────────────────────
  config.password_length = 8..128
  config.reset_password_within = 6.hours

  # ── Rememberable ─────────────────────────────────────────────────────────────
  config.remember_for = 2.weeks
  config.extend_remember_period = false

  # ── Confirmable ──────────────────────────────────────────────────────────────
  config.confirm_within = 3.days
  config.reconfirmable  = true
  config.allow_unconfirmed_access_for = 0.days

  # ── Lockable ─────────────────────────────────────────────────────────────────
  config.lock_strategy   = :failed_attempts
  config.maximum_attempts = 10
  config.unlock_strategy  = :both   # email link or time
  config.unlock_in        = 1.hour

  # ── Timeoutable ──────────────────────────────────────────────────────────────
  config.timeout_in = 30.minutes

  # ── devise-jwt ───────────────────────────────────────────────────────────────
  # The JWT secret MUST be different from Rails' secret_key_base.
  # The token is attached to the Authorization response header on sign-in
  # and must be sent by the client as:  Authorization: Bearer <token>
  config.jwt do |jwt|
    jwt.secret          = ENV.fetch("DEVISE_JWT_SECRET_KEY") { Rails.application.secret_key_base }
    jwt.expiration_time = 24.hours.to_i

    # Which requests cause a new token to be dispatched in the response header
    jwt.dispatch_requests = [
      ["POST", %r{^/api/auth/sign_in$}]
    ]

    # Which requests revoke (invalidate) the current token
    jwt.revocation_requests = [
      ["DELETE", %r{^/api/auth/sign_out$}]
    ]
  end

  # ── OmniAuth providers ───────────────────────────────────────────────────────

  # Google / Gmail
  # Scopes: email + profile gives us name, locale, picture, sub (uid)
  config.omniauth :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", ""),
    ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
    scope: "email,profile",
    access_type: "offline",   # request a refresh_token
    prompt: "consent",        # force consent screen so refresh_token is always returned
    include_granted_scopes: true

  # Apple Sign In
  # Apple only returns name + email on the FIRST authorisation; subsequent
  # sign-ins return only the uid. Always persist those fields after the first
  # callback (OauthUserService does this via the OauthIdentity record).
  config.omniauth :apple,
    ENV.fetch("APPLE_CLIENT_ID", ""),
    "",                         # no client_secret for Apple
    scope:   "name email",
    team_id: ENV.fetch("APPLE_TEAM_ID", ""),
    key_id:  ENV.fetch("APPLE_KEY_ID", ""),
    pem:     apple_private_key
end

# Allow GET for OAuth initiation (needed for browser-redirect OAuth flow).
# The OAuth state parameter provides CSRF protection for the callback.
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning     = true
