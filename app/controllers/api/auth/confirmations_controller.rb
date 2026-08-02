module Api
  module Auth
    class ConfirmationsController < Devise::ConfirmationsController
      respond_to :json

      # POST /api/auth/confirmation
      # Body: { user: { email: "..." } }
      # Resends the confirmation email.
      def create
        super
      end

      # GET /api/auth/confirmation?confirmation_token=<token>
      # Confirms the email address and redirects to the frontend.
      def show
        self.resource = resource_class.confirm_by_token(params[:confirmation_token])
        frontend = ENV.fetch("FRONTEND_URL", "http://localhost:3000")

        if resource.errors.empty?
          redirect_to "#{frontend}/email-confirmed", allow_other_host: true
        else
          redirect_to "#{frontend}/email-confirmed?error=invalid_token", allow_other_host: true
        end
      end

      private

      def respond_with(resource, _opts = {})
        if resource.errors.empty?
          render json: {
            status:  { code: 200, message: "Confirmation email sent." }
          }, status: :ok
        else
          render json: {
            status:  { code: 422, message: "Could not send confirmation email." },
            errors:  resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
