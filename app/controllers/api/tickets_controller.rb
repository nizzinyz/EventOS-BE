module Api
  class TicketsController < ApplicationController
    def index
      render json: Ticket.where(user: current_user).includes(event: [ :organizer, :venue, :tickets ]).order(created_at: :desc).map(&:api_attributes)
    end

    def create
      key = params.require(:request_key).to_s
      return render json: { error: "Invalid request key" }, status: :unprocessable_entity unless key.match?(/\A[0-9a-f-]{36}\z/i)
      event = Event.find(params.require(:event_id))
      event.with_lock do
        existing = Ticket.find_by(user: current_user, request_key: key)
        if existing
          return render json: { error: "Request key already used" }, status: :conflict unless existing.event_id == event.id
          return render json: existing.api_attributes
        end
        unless event.ticketing_enabled && event.status == "published" && event.start_at > Time.current
          return render json: { error: "This event is not accepting reservations" }, status: :unprocessable_entity
        end
        unless event.price_from.zero?
          return render json: { error: "Paid checkout is not yet available" }, status: :unprocessable_entity
        end
        if event.tickets.count >= event.capacity
          return render json: { error: "This event is sold out" }, status: :conflict
        end
        ticket = Ticket.create!(event: event, user: current_user, request_key: key)
        render json: ticket.api_attributes, status: :created
      end
    rescue ActiveRecord::RecordNotUnique
      render json: { error: "Request already processed; refresh your tickets" }, status: :conflict
    end
  end
end
