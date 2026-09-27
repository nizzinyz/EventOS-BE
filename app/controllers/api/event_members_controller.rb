module Api
  class EventMembersController < ApplicationController
    before_action :set_event

    def index
      authorize_management!
      render json: @event.event_members.includes(:user).map(&:api_attributes)
    end

    def create
      authorize_management!
      user = User.find_by!(email: params.require(:member).require(:email).to_s.strip.downcase)
      member = @event.event_members.find_or_initialize_by(user: user)
      member.role = params.require(:member).require(:role)
      member.save!
      render json: member.api_attributes, status: :created
    end

    def destroy
      authorize_management!
      @event.event_members.find(params[:id]).destroy!
      head :no_content
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
    end

    def authorize_management!
      return if @event.can_manage?(current_user)
      raise ActiveRecord::RecordNotFound, "Event not found"
    end
  end
end
