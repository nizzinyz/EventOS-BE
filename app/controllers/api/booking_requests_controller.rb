module Api
  class BookingRequestsController < ApplicationController
    def index
      requests = BookingRequest.where(user: current_user).or(BookingRequest.where(venue_id: Venue.where(owner: current_user).select(:id)))
      render json: requests.includes(:user, :venue).order(event_date: :asc).map { |request|
        request.api_attributes.merge(canRespond: request.venue.owner_id == current_user.id)
      }
    end

    def create
      request = BookingRequest.create!(params.require(:booking_request).permit(:venue_id, :event_date, :guests, :message).merge(user: current_user))
      render json: request.api_attributes, status: :created
    end

    def update
      request = BookingRequest.where(venue_id: Venue.where(owner: current_user).select(:id)).find(params[:id])
      status = params.require(:booking_request).require(:status)
      unless %w[accepted declined].include?(status)
        return render json: { error: "Choose accepted or declined" }, status: :unprocessable_entity
      end
      request.with_lock do
        unless request.status == "pending"
          return render json: { error: "This enquiry has already been answered" }, status: :conflict
        end
        request.update!(status: status)
      end
      render json: request.api_attributes.merge(canRespond: true)
    end
  end
end
