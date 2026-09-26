module Api
  class VenueBookingsController < ApplicationController
    def index
      bookings = params[:hosting] == "true" ? VenueBooking.where(venue: Venue.where(owner: current_user)) : VenueBooking.where(user: current_user)
      render json: bookings.includes(:venue).order(start_at: :desc).map(&:api_attributes)
    end

    def slots
      venue = Venue.find(params[:venue_id])
      date = Date.iso8601(params.require(:date))
      render json: { timezone: "Africa/Johannesburg", slots: venue.slots_on(date) }
    rescue Date::Error
      render json: { error: "Choose a valid date" }, status: :unprocessable_entity
    end

    def create
      input = params.require(:booking)
      key = input.require(:request_key).to_s
      guests = Integer(input[:guests].to_s, 10) rescue nil
      start_at = Time.iso8601(input[:start_at].to_s) rescue nil
      mode = input[:payment_mode]
      outcome = input[:outcome] || "completed"
      unless key.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i) && guests && guests > 0 && start_at && %w[free mock].include?(mode) && %w[completed declined cancelled].include?(outcome)
        return render json: { error: "Invalid booking details" }, status: :unprocessable_entity
      end
      return render json: { error: "Mock checkout is disabled" }, status: :forbidden if mode == "mock" && !LocalPreview.enabled?
      venue = Venue.find(input.require(:venue_id))
      venue.with_lock do
        existing = VenueBooking.find_by(user: current_user, request_key: key)
        if existing
          unless existing.venue_id == venue.id && existing.start_at == start_at && existing.guests == guests && existing.payment_mode == mode && existing.status == outcome
            return render json: { error: "Request key already used for another booking" }, status: :conflict
          end
          return render json: existing.api_attributes
        end
        # Compare instants because clients may send UTC or an explicit local offset.
        slot = venue.slots_on(start_at.in_time_zone("Africa/Johannesburg").to_date).find { |item| Time.iso8601(item[:startAt]) == start_at }
        unless slot && slot[:available] && guests <= venue.capacity
          return render json: { error: "This slot is unavailable. Choose another time or check the guest count." }, status: :conflict
        end
        amount = (venue.price_from * 100).to_i
        if mode == "free" && (amount != 0 || outcome != "completed")
          return render json: { error: "Paid venue bookings require mock checkout in local preview" }, status: :unprocessable_entity
        end
        unless input[:expected_amount_cents].to_s == amount.to_s
          return render json: { error: "The price changed. Refresh before booking." }, status: :conflict
        end
        booking = VenueBooking.create!(venue: venue, user: current_user, request_key: key,
          start_at: start_at, end_at: slot[:endAt], guests: guests, amount_cents: amount,
          payment_mode: mode, status: outcome, ticketed: venue.ticketing_enabled)
        render json: booking.api_attributes, status: :created
      end
    rescue ActiveRecord::RecordNotUnique
      render json: { error: "Booking already processed. Retry to recover it." }, status: :conflict
    end
  end
end
