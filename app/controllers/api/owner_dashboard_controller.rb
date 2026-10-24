module Api
  class OwnerDashboardController < ApplicationController
    def show
      venues = Venue.where(owner: current_user).order(:name)
      venue_ids = venues.select(:id)
      now = Time.current
      confirmed_bookings = VenueBooking.where(venue_id: venue_ids, status: "completed")
      upcoming_bookings = confirmed_bookings.where("end_at >= ?", now).includes(:venue, :user).order(:start_at)
      enquiries = BookingRequest.where(venue_id: venue_ids).includes(:venue, :user).order(event_date: :asc)
      hosted_events = Event.where(venue_id: venue_ids)
      completed_orders = Order.where(event_id: hosted_events.select(:id), status: "completed")

      render json: {
        summary: {
          venueCount: venues.count,
          upcomingBookings: upcoming_bookings.count,
          pendingEnquiries: enquiries.where(status: "pending").count,
          confirmedBookingValueCents: confirmed_bookings.sum(:amount_cents),
          ticketSalesCents: completed_orders.sum(:total_amount_cents),
          ticketsSold: completed_orders.sum(:quantity)
        },
        venues: venues.map { |venue| venue_summary(venue, confirmed_bookings) },
        upcomingBookings: upcoming_bookings.limit(12).map { |booking| booking_attributes(booking) },
        enquiries: enquiries.limit(12).map { |enquiry| enquiry_attributes(enquiry) }
      }
    end

    private

    def venue_summary(venue, confirmed_bookings)
      future = confirmed_bookings.where(venue: venue).where("end_at >= ?", Time.current)
      {
        id: venue.id.to_s,
        name: venue.name,
        city: venue.city,
        verificationStatus: venue.verification_status,
        upcomingBookings: future.count,
        pendingEnquiries: venue.booking_requests.where(status: "pending").count,
        nextBookingAt: future.minimum(:start_at)
      }
    end

    def booking_attributes(booking)
      booking.api_attributes.merge(
        customerName: booking.user.full_name,
        customerEmail: booking.user.email
      )
    end

    def enquiry_attributes(enquiry)
      enquiry.api_attributes.merge(
        customerEmail: enquiry.user.email,
        canRespond: true
      )
    end
  end
end
