require "test_helper"

class MarketplaceTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "owner-#{SecureRandom.hex(5)}@example.com", first_name: "Venue", last_name: "Owner", password: "Password123!", confirmed_at: Time.current)
    @attendee = User.create!(email: "attendee-#{SecureRandom.hex(5)}@example.com", first_name: "Event", last_name: "Guest", password: "Password123!", confirmed_at: Time.current)
    @venue = Venue.create!(owner: @owner, name: "Hall", city: "Cape Town", province: "Western Cape", address: "1 Main Road", capacity: 2)
    @event = Event.create!(organizer: @owner, venue: @venue, title: "Meetup", category: "Community", start_at: 2.days.from_now, capacity: 1, status: "published")
  end

  def headers_for(user)
    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}" }
  end

  test "authentication required" do
    get "/api/tickets", as: :json
    assert_response :unauthorized
  end

  test "drafts and mutations are restricted to the organizer" do
    @event.update!(status: "draft")
    get "/api/events/#{@event.id}", headers: headers_for(@attendee), as: :json
    assert_response :not_found
    get "/api/events", headers: headers_for(@attendee), as: :json
    assert_empty response.parsed_body
    patch "/api/events/#{@event.id}", params: { event: { title: "Stolen" } }, headers: headers_for(@attendee), as: :json
    assert_response :not_found
    assert_equal "Meetup", @event.reload.title
  end

  test "event creation derives owner and venue location" do
    post "/api/events", params: { event: { title: "New event", category: "Music", venue_id: @venue.id, start_at: 3.days.from_now, capacity: 2, organizer_id: @owner.id, city: "Fake", featured: true } }, headers: headers_for(@attendee), as: :json
    assert_response :created
    assert_equal @attendee.public_id, response.parsed_body["organizerId"]
    assert_equal "Cape Town", response.parsed_body["city"]
    assert_equal false, response.parsed_body["featured"]
  end

  test "free reservations are idempotent and cannot oversell" do
    key = SecureRandom.uuid
    2.times do
      post "/api/tickets", params: { event_id: @event.id, request_key: key }, headers: headers_for(@attendee), as: :json
      assert_response :success
    end
    assert_equal 1, @event.tickets.count
    post "/api/tickets", params: { event_id: @event.id, request_key: SecureRandom.uuid }, headers: headers_for(@owner), as: :json
    assert_response :conflict
    get "/api/tickets", headers: headers_for(@owner), as: :json
    assert_empty response.parsed_body
    get "/api/tickets", headers: headers_for(@attendee), as: :json
    assert_equal 1, response.parsed_body.size
    assert_equal @venue.id, response.parsed_body.first.dig("event", "venueId")
  end

  test "paid draft cancelled and past events cannot issue tickets" do
    [ { price_from: 50 }, { price_from: 0, status: "draft" }, { status: "cancelled" }, { status: "published", start_at: 1.day.ago } ].each do |attributes|
      @event.update!(attributes)
      post "/api/tickets", params: { event_id: @event.id, request_key: SecureRandom.uuid }, headers: headers_for(@attendee), as: :json
      assert_response :unprocessable_entity
    end
    assert_equal 0, Ticket.count
  end

  test "ticketed events cannot be deleted or reduced below tickets issued" do
    Ticket.create!(user: @attendee, event: @event, request_key: SecureRandom.uuid)
    delete "/api/events/#{@event.id}", headers: headers_for(@owner), as: :json
    assert_response :unprocessable_entity
    patch "/api/events/#{@event.id}", params: { event: { capacity: 0 } }, headers: headers_for(@owner), as: :json
    assert_response :unprocessable_entity
    assert_equal 1, @event.reload.capacity
  end

  test "capacity and schedule validations" do
    @event.capacity = 3
    assert_not @event.valid?
    @event.capacity = 1
    @event.end_at = @event.start_at - 1.hour
    assert_not @event.valid?
  end

  test "reactions persist per user and saved listings are private" do
    patch "/api/events/#{@event.id}/reaction", params: { reaction: { saved: true, liked: true } }, headers: headers_for(@attendee), as: :json
    assert_response :success
    get "/api/events/#{@event.id}/reaction", headers: headers_for(@attendee), as: :json
    assert_equal({ "saved" => true, "liked" => true }, response.parsed_body)
    get "/api/events?saved=true", headers: headers_for(@attendee), as: :json
    assert_equal 1, response.parsed_body.size
    assert_equal 1, response.parsed_body.first["saveCount"]
    get "/api/events?saved=true", headers: headers_for(@owner), as: :json
    assert_empty response.parsed_body
    patch "/api/events/#{@event.id}/reaction", params: { reaction: { saved: false } }, headers: headers_for(@attendee), as: :json
    assert_equal true, response.parsed_body["liked"]
    get "/api/events?saved=true", headers: headers_for(@attendee), as: :json
    assert_empty response.parsed_body
  end

  test "enquiries reject invalid dates unavailable venues and excess guests" do
    [ { event_date: Date.yesterday, guests: 1 }, { event_date: Date.tomorrow, guests: 3 } ].each do |attributes|
      post "/api/booking_requests", params: { booking_request: attributes.merge(venue_id: @venue.id, message: "Party") }, headers: headers_for(@attendee), as: :json
      assert_response :unprocessable_entity
    end
    @venue.update!(available: false)
    post "/api/booking_requests", params: { booking_request: { venue_id: @venue.id, event_date: Date.tomorrow, guests: 1, message: "Party" } }, headers: headers_for(@attendee), as: :json
    assert_response :unprocessable_entity
    assert_equal 0, BookingRequest.count
  end

  test "profile preferences persist and other accounts remain private" do
    patch "/api/users/#{@attendee.public_id}", params: { user: { bio: "Music fan", city: "Durban", interests: [ "Music" ], email_updates: true } }, headers: headers_for(@attendee), as: :json
    assert_response :success
    assert_equal [ "Music" ], response.parsed_body.dig("data", "interests")
    assert @attendee.reload.email_updates
    patch "/api/users/#{@owner.public_id}", params: { user: { first_name: "Changed" } }, headers: headers_for(@attendee), as: :json
    assert_response :not_found
  end

  test "venue enquiries are visible to requester and owner and only owner can respond" do
    post "/api/booking_requests", params: { booking_request: { venue_id: @venue.id, event_date: 3.days.from_now.to_date, guests: 2, message: "Birthday", status: "accepted" } }, headers: headers_for(@attendee), as: :json
    assert_response :created
    id = response.parsed_body["id"]
    assert_equal "pending", response.parsed_body["status"]
    patch "/api/booking_requests/#{id}", params: { booking_request: { status: "accepted" } }, headers: headers_for(@attendee), as: :json
    assert_response :not_found
    patch "/api/booking_requests/#{id}", params: { booking_request: { status: "accepted" } }, headers: headers_for(@owner), as: :json
    assert_response :success
    get "/api/booking_requests", headers: headers_for(@attendee), as: :json
    assert_equal "accepted", response.parsed_body.first["status"]
  end
end
