module Api
  class CheckInsController < ApplicationController
    def create
      event = Event.where(organizer: current_user).find(params[:event_id])
      code = params.require(:code).to_s.delete_prefix("roam-ticket:")
      event.with_lock do
        unless event.status == "published"
          return render json: { error: "Only published events accept check-ins" }, status: :unprocessable_entity
        end
        ticket = event.tickets.find_by!(code: code)
        if ticket.order&.payment_mode == "mock" && !LocalPreview.enabled?
          return render json: { error: "Mock tickets are only valid in local preview" }, status: :forbidden
        end
        if ticket.checked_in_at
          return render json: { error: "This ticket has already checked in" }, status: :conflict
        end
        ticket.update!(checked_in_at: Time.current)
        render json: { code: ticket.code, checkedInAt: ticket.checked_in_at, attendeeName: ticket.user.full_name }
      end
    end
  end
end
