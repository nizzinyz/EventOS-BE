module Api
  class EventReactionsController < ApplicationController
    def show
      event = visible_event
      reaction = EventReaction.find_by(user: current_user, event: event)
      render json: { saved: reaction&.saved || false, liked: reaction&.liked || false }
    end

    def update
      event = visible_event
      event.with_lock do
        reaction = EventReaction.find_or_initialize_by(user: current_user, event: event)
        reaction.update!(params.require(:reaction).permit(:saved, :liked))
        render json: { saved: reaction.saved, liked: reaction.liked }
      end
    end

    private

    def visible_event
      Event.where(status: "published").or(Event.where(organizer: current_user)).find(params[:event_id])
    end
  end
end
