module Api
  module Auth
    # POST /api/auth/exchange
    #
    # Completes the OAuth login flow by exchanging a short-lived one-time code
    # for a JWT + user profile. The code is written by OmniauthCallbacksController
    # after a successful provider callback; it expires in 60 seconds and is
    # deleted on first use so it cannot be replayed.
    #
    # This keeps the JWT out of the redirect URL (and therefore out of browser
    # history, server access logs, and Referer headers).
    class ExchangesController < ApplicationController
      # This endpoint either consumes the legacy one-time OAuth code or an
      # Auth0 bearer token. Both flows establish a user session themselves.
      skip_before_action :authenticate_request!, only: :create

      CACHE_PREFIX = "oauth_exchange:"
      private_constant :CACHE_PREFIX

      def create
        auth0_token = request.authorization.to_s.delete_prefix("Bearer ")
        if auth0_token.present?
          user = Auth0TokenService.user_from(auth0_token)
          return render json: { data: user.api_attributes }, status: :ok
        end

        code = params[:code].to_s.strip
        return render json: { error: "Missing code" }, status: :bad_request if code.blank?

        payload = Rails.cache.delete("#{CACHE_PREFIX}#{code}")
        return render json: { error: "Code expired or already used" }, status: :unauthorized if payload.nil?

        render json: { token: payload[:jwt], user: payload[:user] }, status: :ok
      rescue JWT::DecodeError, KeyError, JSON::ParserError
        render json: { error: "Invalid Auth0 access token" }, status: :unauthorized
      end
    end
  end
end
