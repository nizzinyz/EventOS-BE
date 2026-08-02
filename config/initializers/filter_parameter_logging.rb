# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  # Credentials / secrets
  :passw, :secret, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # PII — personal identifiers
  :email, :first_name, :last_name, :name,
  # Auth tokens (JWT, OAuth)
  :token, :access_token, :refresh_token, :id_token, :authorization,
  # OAuth callback URL params (user= is JSON with email/name)
  :user,
  # OAuth provider raw payload stored in oauth_identities (duplicates PII)
  :raw_info
]
