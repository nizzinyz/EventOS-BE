module Api
  class EventsController < ApplicationController
    include JsonResponse

    before_action :set_event, only: %i[show update destroy]

    def index
      events = Event.order(start_at: :asc)

      render json: camelize_json(events), status: :ok
    end

    def show
      render json: camelize_json(@event), status: :ok
    end

    def create
      event = Event.new(event_params)

      # Organizer always comes from the authenticated user
      event.organizer_id = current_user.id

      if event.save
        render json: camelize_json(event), status: :created
      else
        render json: {
          errors: event.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def update
      if @event.update(event_params)
        render json: camelize_json(@event), status: :ok
      else
        render json: {
          errors: @event.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy!

      head :no_content
    end

    private

    def set_event
      @event = Event.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "Event not found"
      }, status: :not_found
    end

    def event_params
      params.require(:event).permit(
        :title,
        :description,
        :organizer_name,
        :venue_id,
        :venue_name,
        :category,
        :city,
        :province,
        :address,
        :start_at,
        :end_at,
        :image_url,
        :video_url,
        :price_from,
        :currency,
        :attendee_count,
        :like_count,
        :save_count,
        :featured,
        :status
      )
    end
  end
end