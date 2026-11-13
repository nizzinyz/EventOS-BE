class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  before_action :authenticate_request!

  # Devise/Warden hook: return 401 JSON instead of a redirect when the
  # JWT token is missing or invalid.
  def self.responders_controller?; false; end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def authenticate_request!
    token = request.authorization.to_s.delete_prefix("Bearer ")
    if auth0_token?(token)
      @auth0_user = Auth0TokenService.user_from(token)
    else
      authenticate_user!
    end
  rescue JWT::DecodeError, KeyError, JSON::ParserError
    render json: { error: "Invalid Auth0 access token" }, status: :unauthorized
  end

  # Auth0 and Devise both issue three-part JWTs. Route only tokens issued by
  # our configured Auth0 tenant through Auth0 verification; Devise validates
  # its own tokens through Warden.
  def auth0_token?(token)
    return false if token.blank? || ENV["AUTH0_DOMAIN"].blank?

    payload, = JWT.decode(token, nil, false)
    payload["iss"] == "https://#{ENV.fetch("AUTH0_DOMAIN")}/"
  rescue JWT::DecodeError, JSON::ParserError
    false
  end

  def current_user
    @auth0_user || super
  end

  def require_admin!
    return if current_user&.admin?
    render json: { error: "Admin access is required" }, status: :forbidden
  end

  # Returns the currently authenticated user from the Devise-JWT token.
  # Available in every controller as `current_user` (provided by Devise).

  # 401 response sent as JSON (replaces Devise's default HTML redirect).
  def respond_to_on_destroy
    head :no_content
  end
end
