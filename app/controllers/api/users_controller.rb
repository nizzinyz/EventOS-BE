module Api
  class UsersController < ApplicationController
    before_action :set_user

    # GET /api/users/:id
    def show
      render json: { data: @user.api_attributes }, status: :ok
    end

    # PATCH /api/users/:id
    def update
      if @user.update(user_update_params)
        render json: { data: @user.api_attributes }, status: :ok
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/users/:id — a user may delete their own account.
    def destroy
      @user.destroy!
      head :no_content
    end

    private

    # Users can only ever operate on their own account. Any other id 404s
    # rather than 403s so account public_ids can't be probed.
    def set_user
      raise ActiveRecord::RecordNotFound, "User not found" unless params[:id] == current_user.public_id

      @user = current_user
    end

    def user_update_params
      params.require(:user).permit(
        :first_name, :last_name,
        :date_of_birth,
        :avatar_url
      )
    end
  end
end
