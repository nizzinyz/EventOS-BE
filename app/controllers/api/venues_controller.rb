module Api
  class VenuesController < ApplicationController
    def index
      venues = Venue.where(verification_status: "verified").or(Venue.where(owner: current_user))
      venues = Venue.all if current_user.admin?
      render json: venues.includes(:owner).order(created_at: :desc).map(&:api_attributes)
    end

    def show
      venue = Venue.find(params[:id])
      raise ActiveRecord::RecordNotFound, "Venue not found" unless venue.verification_status == "verified" || venue.owner == current_user || current_user.admin?
      render json: venue.api_attributes
    end

    def create
      venue = Venue.create!(venue_params.merge(owner: current_user))
      render json: venue.api_attributes, status: :created
    end

    def update
      venue = Venue.where(owner: current_user).find(params[:id])
      venue.with_lock { venue.update!(venue_params) }
      render json: venue.api_attributes
    end

    def destroy
      venue = Venue.where(owner: current_user).find(params[:id])
      if venue.destroy
        head :no_content
      else
        render json: { errors: venue.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def venue_params
      params.require(:venue).permit(:name, :description, :city, :province, :address,
        :ticketing_enabled, :booking_enabled, :opening_time, :closing_time, :slot_minutes, :setup_buffer_minutes, :cleanup_buffer_minutes, :capacity, :latitude, :longitude, :price_from, :image_url, :available, amenities: [], categories: [], opening_days: [], blocked_dates: [], blocked_periods: [:startAt, :endAt])
    end
  end
end
