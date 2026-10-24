module Api
  module Auth
    class PasswordsController < Devise::PasswordsController
      respond_to :json
      rate_limit to: 5, within: 1.hour, only: :create

      # POST /api/auth/password
      # Body: { user: { email: "..." } }
      # Sends a password-reset email with a token link.
      def create
        super
      end

      # PUT /api/auth/password
      # Body: { user: { reset_password_token, password, password_confirmation } }
      def update
        super
      end

      private

      def respond_with(resource, _opts = {})
        if resource.errors.empty?
          render json: {
            status:  { code: 200, message: "Password reset instructions sent." }
          }, status: :ok
        else
          render json: {
            status:  { code: 422, message: "Could not send reset instructions." },
            errors:  resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
