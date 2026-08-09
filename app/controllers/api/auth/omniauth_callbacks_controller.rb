module Api
  module Auth
    # Handles the OAuth redirect callbacks from all providers.
    #
    # OAuth flow for the web SPA (browser redirect):
    #   1. Frontend redirects to GET /api/auth/<provider>
    #   2. Provider authenticates and redirects back here.
    #   3. On success, we store the JWT in Rails.cache keyed by a random one-time
    #      code and redirect to FRONTEND_URL/auth/callback?code=<OTC>.
    #   4. The frontend POSTs the code to POST /api/auth/exchange, which returns
    #      the JWT + user profile in the response body and deletes the cache entry.
    #   5. On failure, we redirect to FRONTEND_URL/login?error=oauth_failed.
    #
    # The JWT and user profile never appear in any URL, keeping them out of
    # browser history, server access logs, and Referer headers.
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      skip_before_action :verify_authenticity_token, raise: false

      EXCHANGE_TTL    = 60.seconds
      CACHE_PREFIX    = "oauth_exchange:"
      CODE_BYTE_LEN   = 32
      private_constant :EXCHANGE_TTL, :CACHE_PREFIX, :CODE_BYTE_LEN

      # ── Google ─────────────────────────────────────────────────────────────
      def google_oauth2
        handle_callback
      end

      # ── Apple ──────────────────────────────────────────────────────────────
      def apple
        handle_callback
      end

      # ── Failure ────────────────────────────────────────────────────────────
      def failure
        redirect_to "#{frontend_url}/login?error=oauth_failed", allow_other_host: true
      end

      private

      def handle_callback
        @user = OauthUserService.find_or_create(request.env["omniauth.auth"])

        if @user.persisted?
          sign_in(@user, store: false)   # store: false → no session, JWT only

          # Devise-JWT writes the token to the Authorization response header.
          jwt = response.headers["Authorization"]&.delete_prefix("Bearer ")

          # Store the JWT + user profile under a random, single-use code.
          # The frontend exchanges this code via POST /api/auth/exchange within
          # the TTL window; the cache entry is deleted on first read.
          code = SecureRandom.urlsafe_base64(CODE_BYTE_LEN)
          Rails.cache.write(
            "#{CACHE_PREFIX}#{code}",
            { jwt: jwt, user: @user.api_attributes },
            expires_in: EXCHANGE_TTL
          )

          redirect_to "#{frontend_url}/auth/callback?code=#{code}",
                      allow_other_host: true
        else
          redirect_to "#{frontend_url}/login?error=oauth_failed", allow_other_host: true
        end
      end

      def frontend_url
        ENV.fetch("FRONTEND_URL", "http://localhost:3000").delete_suffix("/")
      end
    end
  end
end
