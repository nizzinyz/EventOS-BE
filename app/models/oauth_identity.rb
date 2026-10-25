class OauthIdentity < ApplicationRecord
  belongs_to :user

  # ── PII encryption ───────────────────────────────────────────────────────────
  # uid + email are deterministic so the provider+uid unique index still works.
  encrypts :uid,           deterministic: true
  encrypts :email,         deterministic: true
  encrypts :name
  encrypts :access_token
  encrypts :refresh_token
  encrypts :id_token

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # `auth0` represents the brokered identity used by the web client. The
  # upstream Google identity remains managed by Auth0 and is never stored here.
  PROVIDERS = %w[google_oauth2 apple auth0].freeze
  validates :provider, inclusion: { in: PROVIDERS }

  # Returns a human-readable provider label.
  def provider_label
    case provider
    when "google_oauth2" then "Google"
    when "apple"         then "Apple"
    else provider.humanize
    end
  end

  # Syncs token fields from the latest OmniAuth credentials hash.
  def update_from_auth(auth)
    creds = auth.credentials
    return unless creds

    update!(
      access_token:      creds.token,
      refresh_token:     creds.refresh_token || refresh_token,
      id_token:          creds.respond_to?(:id_token) ? creds.id_token : id_token,
      token_expires_at:  creds.expires_at ? Time.at(creds.expires_at) : nil,
      name:              auth.info.name,
      email:             auth.info.email || email,
      avatar_url:        auth.info.image || avatar_url,
      raw_info:          {}  # not stored — duplicates PII already in dedicated columns
    )
  end
end
