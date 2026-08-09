module Api
  module Auth
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # POST /api/auth/sign_up
      # Body: { user: { email, password, password_confirmation, first_name, last_name,
      #                 date_of_birth (opt) } }
      def create
        super
      end

      # PATCH/PUT /api/auth  (update own profile)
      def update
        super
      end

      # DELETE /api/auth/cancel
      def destroy
        super
      end

      private

      def sign_up_params
        params.require(:user).permit(
          :email, :password, :password_confirmation,
          :first_name, :last_name,
          :date_of_birth
        )
      end

      def account_update_params
        params.require(:user).permit(
          :first_name, :last_name,
          :date_of_birth,
          :avatar_url,
          :password, :password_confirmation, :current_password
        )
      end

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            status:  { code: 200, message: "Signed up successfully." },
            data:    resource.api_attributes
          }, status: :ok
        else
          render json: {
            status:  { code: 422, message: "Could not create account." },
            errors:  resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
