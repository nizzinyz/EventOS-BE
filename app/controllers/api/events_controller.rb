module Api
  class EventsController < ApplicationController
    def index
      events = Event.where(status: "published").or(Event.where(organizer: current_user))
      events = events.where(id: EventReaction.where(user: current_user, saved: true).select(:event_id)) if params[:saved] == "true"
      render json: events.includes(:organizer, :venue, :tickets, :event_reactions).order(start_at: :asc).map(&:api_attributes)
    end

    def show
      event = Event.where(status: "published").or(Event.where(organizer: current_user)).find(params[:id])
      render json: event.api_attributes
    end

    def create
      event = Event.create!(event_params.merge(organizer: current_user))
      render json: event.api_attributes, status: :created
    end

    def update
      event = Event.where(organizer: current_user).find(params[:id])
      event.with_lock { event.update!(event_params) }
      render json: event.api_attributes
    end

    def destroy
      event = Event.where(organizer: current_user).find(params[:id])
      event.with_lock do
        if event.destroy
          head :no_content
        else
          render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    private

    def event_params
      params.require(:event).permit(:title, :description, :venue_id, :venue_name, :category,
        :city, :province, :address, :start_at, :end_at, :image_url, :video_url,
        :ticketing_enabled, :latitude, :longitude, :price_from, :capacity, :status, poster_config: [ :template, :palette, :background,
          :background_color, :accent_color, :background_image_url, :tagline, { highlights: [] } ])
    end
  end
end
