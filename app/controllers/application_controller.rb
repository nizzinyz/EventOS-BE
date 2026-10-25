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
    if token.present? && ENV["AUTH0_DOMAIN"].present? && token.split(".").length == 3
      @auth0_user = Auth0TokenService.user_from(token)
    else
      authenticate_user!
    end
  rescue JWT::DecodeError, KeyError, JSON::ParserError
    render json: { error: "Invalid Auth0 access token" }, status: :unauthorized
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
