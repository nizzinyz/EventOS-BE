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
      skip_before_action :authenticate_user!

      CACHE_PREFIX = "oauth_exchange:"
      private_constant :CACHE_PREFIX

      def create
        code = params[:code].to_s.strip
        return render json: { error: "Missing code" }, status: :bad_request if code.blank?

        payload = Rails.cache.delete("#{CACHE_PREFIX}#{code}")
        return render json: { error: "Code expired or already used" }, status: :unauthorized if payload.nil?

        render json: { token: payload[:jwt], user: payload[:user] }, status: :ok
      end
    end
  end
end
