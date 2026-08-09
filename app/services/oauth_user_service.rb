# Handles user creation and identity linking for all OmniAuth OAuth providers.
#
# Strategy:
#   1. Look for an existing OauthIdentity matching (provider, uid).
#      → If found: refresh tokens and return the linked user.
#   2. Look for an existing User with the provider's email.
#      → If found: attach a new OauthIdentity and return that user.
#   3. Otherwise create a new User + OauthIdentity in one save. The identity
#      is built BEFORE the user is saved so Devise's password_required? sees
#      an OAuth account and demands no password — OAuth-only users carry no
#      password at all (they can set one later via the forgot-password flow).
#
# Apple note: Apple only returns name and email on the VERY FIRST authorisation.
# Subsequent callbacks omit them.  The values are persisted in OauthIdentity.email
# / OauthIdentity.name and merged back into the user on first creation.
class OauthUserService
  def self.find_or_create(auth)
    new(auth).call
  end

  def initialize(auth)
    @auth = auth
  end

  def call
    identity = OauthIdentity.find_by(provider: @auth.provider, uid: @auth.uid)

    if identity
      identity.update_from_auth(@auth)
      return identity.user
    end

    # No matching identity – find or create the user, then link.
    ActiveRecord::Base.transaction do
      if (user = find_user_by_email)
        user.oauth_identities.create!(identity_attributes)
        user
      else
        user = build_user
        user.oauth_identities.build(identity_attributes)
        user.save!
        user
      end
    end
  end

  private

  def info = @auth.info
  def credentials = @auth.credentials

  def provider_email
    info.email.presence
  end

  def find_user_by_email
    User.find_by(email: provider_email) if provider_email
  end

  def build_user
    # Split "Full Name" into first/last for providers that don't expose them
    # separately.
    name_parts = (info.name || "").split(" ", 2)

    User.new(
      email:      provider_email,
      first_name: info.first_name.presence || name_parts.first || "User",
      last_name:  info.last_name.presence  || name_parts.second || "",
      avatar_url: info.image,
      # Skip email confirmation: the provider already verified the address.
      confirmed_at: Time.current
    )
  end

  def identity_attributes
    {
      provider:         @auth.provider,
      uid:              @auth.uid,
      access_token:     credentials&.token,
      refresh_token:    credentials&.refresh_token,
      id_token:         credentials.respond_to?(:id_token) ? credentials.id_token : nil,
      token_expires_at: credentials&.expires_at ? Time.at(credentials.expires_at) : nil,
      name:             info.name,
      email:            provider_email,
      avatar_url:       info.image,
      # raw_info is not stored — it duplicates PII already captured in dedicated
      # columns (name, email, avatar_url) and is never read back.
      raw_info:         {}
    }
  end
end
