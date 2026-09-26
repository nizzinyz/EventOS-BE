require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  teardown do
    Rails.configuration.x.local_preview = false
  end

  test "local signup can log in without email and does not claim verification" do
    Rails.configuration.x.local_preview = true
    email = "local-#{SecureRandom.hex(5)}@example.com"
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post "/api/auth", params: { user: { email: email, password: "Testing123!", password_confirmation: "Testing123!", first_name: "Local", last_name: "Member" } }, as: :json
    end
    assert_response :success
    assert_equal false, response.parsed_body.dig("data", "confirmed")
    assert_equal false, response.parsed_body.dig("data", "confirmation_required")
    id = response.parsed_body.dig("data", "id")
    post "/api/auth/sign_in", params: { user: { email: email, password: "Testing123!" } }, as: :json
    assert_response :success
    token = response.headers["Authorization"]
    assert token.present?
    get "/api/users/#{id}", headers: { "Authorization" => token }, as: :json
    assert_response :success
    assert_equal email, response.parsed_body.dig("data", "email")
  end

  test "confirmation is required when preview is disabled and production never allows preview" do
    Rails.configuration.x.local_preview = true
    assert_not LocalPreview.enabled?(environment: "production")
    Rails.configuration.x.local_preview = false
    email = "confirm-#{SecureRandom.hex(5)}@example.com"
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post "/api/auth", params: { user: { email: email, password: "Testing123!", password_confirmation: "Testing123!", first_name: "Email", last_name: "Member" } }, as: :json
    end
    assert_response :success
    assert response.parsed_body.dig("data", "confirmation_required")
    post "/api/auth/sign_in", params: { user: { email: email, password: "Testing123!" } }, as: :json
    assert_response :unauthorized
  end

  test "registration returns a user and validation errors as JSON" do
    post "/api/auth", params: { user: { email: "signup-#{SecureRandom.hex(5)}@example.com", password: "Testing123!", password_confirmation: "Testing123!", first_name: "New", last_name: "Member" } }, as: :json
    assert_response :success
    assert response.parsed_body.dig("data", "id").present?
    post "/api/auth", params: { user: { email: "invalid", password: "short", first_name: "", last_name: "" } }, as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].present?
  end
end
