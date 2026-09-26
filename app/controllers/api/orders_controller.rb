module Api
  class OrdersController < ApplicationController
    def index
      render json: Order.where(user: current_user).includes(:event, :tickets).order(created_at: :desc).map(&:api_attributes)
    end

    def create
      input = params.require(:order)
      key = input.require(:request_key).to_s
      quantity = Integer(input.require(:quantity).to_s, 10) rescue nil
      mode = input.require(:payment_mode)
      outcome = input[:outcome] || "completed"
      unless key.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i) && quantity && (1..10).cover?(quantity) && %w[free mock].include?(mode) && %w[completed declined cancelled].include?(outcome)
        return render json: { error: "Invalid checkout details" }, status: :unprocessable_entity
      end
      if mode == "mock" && !LocalPreview.enabled?
        return render json: { error: "Mock checkout is disabled" }, status: :forbidden
      end
      event = Event.find(input.require(:event_id))
      event.with_lock do
        existing = Order.find_by(user: current_user, request_key: key)
        if existing
          unless existing.event_id == event.id && existing.quantity == quantity && existing.payment_mode == mode && existing.status == outcome
            return render json: { error: "Request key was used for a different checkout" }, status: :conflict
          end
          return render json: existing.api_attributes
        end
        unless event.ticketing_enabled && event.status == "published" && (event.start_at > Time.current || (mode == "mock" && LocalPreview.enabled?))
          return render json: { error: "This event is not accepting reservations" }, status: :unprocessable_entity
        end
        if mode == "free" && (!event.price_from.zero? || outcome != "completed")
          return render json: { error: "Paid tickets require mock checkout in local preview" }, status: :unprocessable_entity
        end
        unit_amount = (event.price_from * 100).to_i
        unless input[:expected_unit_amount_cents].to_s == unit_amount.to_s
          return render json: { error: "The ticket price has changed. Refresh the event before checking out." }, status: :conflict
        end
        if event.tickets.count + quantity > event.capacity
          return render json: { error: "Not enough tickets remain for this quantity" }, status: :conflict
        end
        order = Order.create!(user: current_user, event: event, request_key: key, quantity: quantity,
          payment_mode: mode, status: outcome, unit_amount_cents: unit_amount, total_amount_cents: unit_amount * quantity)
        if outcome == "completed"
          quantity.times { |index| Ticket.create!(user: current_user, event: event, order: order, request_key: "#{order.reference}:#{index}") }
        end
        render json: order.api_attributes, status: :created
      end
    rescue ActiveRecord::RecordNotUnique
      render json: { error: "Checkout already processed. Check your tickets." }, status: :conflict
    end
  end
end
