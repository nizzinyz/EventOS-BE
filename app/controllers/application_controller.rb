class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  before_action :authenticate_user!

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
