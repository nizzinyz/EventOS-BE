module Api
  module Auth
    class SessionsController < Devise::SessionsController
      respond_to :json
      rate_limit to: 10, within: 15.minutes, only: :create

      # POST /api/auth/sign_in
      # Body: { user: { email: "...", password: "..." } }
      # On success the JWT is automatically added to the Authorization response
      # header by devise-jwt.  The body also includes the user payload.
      def create
        super
      end

      # DELETE /api/auth/sign_out
      # Requires: Authorization: Bearer <token>
      # Regenerates the user's jti, invalidating all outstanding tokens.
      def destroy
        super
      end

      def auth0_session
        user = Auth0TokenService.user_from(request.authorization.to_s.delete_prefix("Bearer "))
        render json: { data: user.api_attributes }
      rescue JWT::DecodeError, KeyError, JSON::ParserError
        render json: { error: "Invalid Auth0 access token" }, status: :unauthorized
      end

      private

      def respond_with(resource, _opts = {})
        render json: {
          status:  { code: 200, message: "Logged in successfully." },
          data:    resource.api_attributes
        }, status: :ok
      end

      def respond_to_on_destroy
        if current_user
          render json: {
            status:  { code: 200, message: "Logged out successfully." }
          }, status: :ok
        else
          render json: {
            status:  { code: 401, message: "No active session." }
          }, status: :unauthorized
        end
      end
    end
  end
end
