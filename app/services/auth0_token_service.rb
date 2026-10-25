require "net/http"

class Auth0TokenService
  NAMESPACE = "https://roam.app/"

  def self.user_from(token)
    domain = ENV.fetch("AUTH0_DOMAIN")
    issuer = "https://#{domain}/"
    header = JWT.decode(token, nil, false).last
    keys = Rails.cache.fetch("auth0:jwks", expires_in: 6.hours) { JSON.parse(Net::HTTP.get(URI("#{issuer}.well-known/jwks.json"))).fetch("keys") }
    jwk = keys.find { |key| key["kid"] == header["kid"] } or raise JWT::DecodeError, "Unknown signing key"
    payload, = JWT.decode(token, JWT::JWK.import(jwk).public_key, true, algorithms: ["RS256"], iss: issuer, verify_iss: true, aud: ENV.fetch("AUTH0_AUDIENCE"), verify_aud: true)
    email = payload.fetch("#{NAMESPACE}email").to_s.downcase
    raise JWT::DecodeError, "Missing email claim" if email.blank?
    identity = OauthIdentity.find_by(provider: "auth0", uid: payload.fetch("sub"))
    return identity.user if identity
    user = User.find_or_initialize_by(email: email)
    if user.new_record?
      user.assign_attributes(first_name: payload["#{NAMESPACE}given_name"].presence || "Roam", last_name: payload["#{NAMESPACE}family_name"].presence || "Member", avatar_url: payload["#{NAMESPACE}picture"], confirmed_at: Time.current)
      user.oauth_identities.build(provider: "auth0", uid: payload.fetch("sub"), email: email, name: payload["#{NAMESPACE}name"], raw_info: {})
      user.save!
    else
      user.oauth_identities.create!(provider: "auth0", uid: payload.fetch("sub"), email: email, name: payload["#{NAMESPACE}name"], raw_info: {})
    end
    user
  end
end
