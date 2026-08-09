module Api
  class VenuesController < ApplicationController
    include JsonResponse

    before_action :set_venue, only: %i[show update destroy]

    def index
      venues = Venue.order(created_at: :desc)

      render json: camelize_json(venues), status: :ok
    end

    def show
      render json: camelize_json(@venue), status: :ok
    end

    def create
      venue = Venue.new(venue_params)

      # Never trust owner_id from the client.
      venue.owner_id = current_user.id

      if venue.save
        render json: camelize_json(venue), status: :created
      else
        render json: {
          errors: venue.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def update
      if @venue.update(venue_params)
        render json: camelize_json(@venue), status: :ok
      else
        render json: {
          errors: @venue.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def destroy
      @venue.destroy!

      head :no_content
    end

    private

    def set_venue
      @venue = Venue.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "Venue not found"
      }, status: :not_found
    end

    def venue_params
      params.require(:venue).permit(
        :name,
        :description,
        :city,
        :province,
        :address,
        :capacity,
        :price_from,
        :currency,
        :image_url,
        :rating,
        :review_count,
        :available,
        :featured,
        amenities: [],
        categories: []
      )
    end
  end
end