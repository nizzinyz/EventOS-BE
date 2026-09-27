require "test_helper"

class EventOperationsTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "owner-#{SecureRandom.hex(5)}@example.com", first_name: "Event", last_name: "Owner", password: "Password123!", confirmed_at: Time.current)
    @scanner = User.create!(email: "scanner-#{SecureRandom.hex(5)}@example.com", first_name: "Door", last_name: "Scanner", password: "Password123!", confirmed_at: Time.current)
    @guest = User.create!(email: "guest-#{SecureRandom.hex(5)}@example.com", first_name: "Guest", last_name: "Person", password: "Password123!", confirmed_at: Time.current)
    @venue = Venue.create!(owner: @owner, name: "Operations Hall", city: "Cape Town", address: "1 Main Road", capacity: 100, booking_enabled: true, setup_buffer_minutes: 60, cleanup_buffer_minutes: 60, verification_status: "verified")
    @event = Event.create!(organizer: @owner, venue: @venue, title: "Private launch", category: "Community", start_at: 7.days.from_now, capacity: 50, status: "published", visibility: "private")
  end

  def headers_for(user)
    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}" }
  end

  test "event staff can scan but cannot manage the event" do
    post "/api/events/#{@event.id}/members", params: { member: { email: @scanner.email, role: "scanner" } }, headers: headers_for(@owner), as: :json
    assert_response :created
    get "/api/events/#{@event.id}", headers: headers_for(@scanner), as: :json
    assert_response :success
    patch "/api/events/#{@event.id}", params: { event: { title: "Changed" } }, headers: headers_for(@scanner), as: :json
    assert_response :not_found
    ticket = Ticket.create!(event: @event, user: @guest, request_key: SecureRandom.uuid)
    post "/api/events/#{@event.id}/check_ins", params: { code: ticket.code }, headers: headers_for(@scanner), as: :json
    assert_response :success
    assert ticket.reload.checked_in_at
  end

  test "buffers, blocked periods, and private visibility protect venue operations" do
    date = 7.days.from_now.in_time_zone("Africa/Johannesburg").to_date
    start = @venue.slots_on(date).first[:startAt]
    VenueBooking.create!(venue: @venue, user: @owner, request_key: SecureRandom.uuid, start_at: start, end_at: Time.iso8601(start) + 3.hours, guests: 10, amount_cents: 0, payment_mode: "free", status: "completed")
    assert_equal false, @venue.slots_on(date).first[:available]
    @venue.update!(blocked_periods: [{ "startAt" => (Time.iso8601(start) + 6.hours).iso8601, "endAt" => (Time.iso8601(start) + 9.hours).iso8601 }])
    assert @venue.slots_on(date).any? { |slot| !slot[:available] }
    get "/api/events/#{@event.id}", headers: headers_for(@guest), as: :json
    assert_response :not_found
  end

  test "an event can use its organizer's confirmed venue booking only within its window" do
    start_at = 10.days.from_now.change(hour: 12)
    booking = VenueBooking.create!(venue: @venue, user: @owner, request_key: SecureRandom.uuid, start_at: start_at, end_at: start_at + 4.hours, guests: 20, amount_cents: 0, payment_mode: "free", status: "completed")
    event = Event.create!(organizer: @owner, venue: @venue, venue_booking: booking, title: "Booked venue event", category: "Music", start_at: start_at + 1.hour, end_at: start_at + 3.hours, capacity: 20)
    assert_equal booking, event.venue_booking
    event.end_at = booking.end_at + 1.minute
    assert_not event.valid?
  end
end
