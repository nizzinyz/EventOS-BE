require "test_helper"

class VenueSlotsTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.x.local_preview = true
    @owner = User.create!(email: "owner-#{SecureRandom.hex(5)}@example.com", first_name: "Host", last_name: "Member", password: "Testing123!", confirmed_at: Time.current)
    @buyer = User.create!(email: "buyer-#{SecureRandom.hex(5)}@example.com", first_name: "Buyer", last_name: "Member", password: "Testing123!", confirmed_at: Time.current)
    @venue = Venue.create!(owner: @owner, name: "Slot hall", city: "Cape Town", address: "1 Main Road", capacity: 20, price_from: 1000, booking_enabled: true)
    @date = 7.days.from_now.in_time_zone("Africa/Johannesburg").to_date
    @start = @venue.slots_on(@date).first[:startAt]
  end

  teardown { Rails.configuration.x.local_preview = false }

  def headers_for(user)
    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}" }
  end

  def input(overrides = {})
    { venue_id: @venue.id, start_at: @start, guests: 10, request_key: SecureRandom.uuid, expected_amount_cents: 100000, payment_mode: "mock", outcome: "completed" }.merge(overrides)
  end

  def book(data)
    post "/api/venue_bookings", params: { booking: data }, headers: headers_for(@buyer), as: :json
  end

  test "successful checkout occupies slot and retry returns original snapshot" do
    data = input
    book(data)
    assert_response :created
    assert_equal false, response.parsed_body["ticketed"]
    reference = response.parsed_body["reference"]
    assert_equal 100000, response.parsed_body["amountCents"]
    @venue.update!(price_from: 2000, slot_minutes: 60)
    book(data)
    assert_response :success
    assert_equal reference, response.parsed_body["reference"]
    assert_equal 100000, response.parsed_body["amountCents"]
    assert_equal 1, VenueBooking.count
    book(input(expected_amount_cents: 200000))
    assert_response :conflict
    # A new slot grid cannot create overlapping bookings after owner edits.
    book(input(start_at: (Time.iso8601(@start) + 1.hour).iso8601, expected_amount_cents: 200000))
    assert_response :conflict
    book(data.merge(guests: 1))
    assert_response :conflict
  end

  test "declined cancelled and invalid checkouts leave slot available" do
    %w[declined cancelled].each { |outcome| book(input(outcome: outcome)); assert_response :created }
    book(input(guests: 21))
    assert_response :conflict
    book(input(guests: 1.5))
    assert_response :unprocessable_entity
    book(input(expected_amount_cents: 1))
    assert_response :conflict
    book(input(payment_mode: "free"))
    assert_response :unprocessable_entity
    assert @venue.slots_on(@date).first[:available]
    @venue.update!(ticketing_enabled: true)
    book(input)
    assert_response :created
    assert_equal true, response.parsed_body["ticketed"]
    assert_not @venue.slots_on(@date).first[:available]
  end

  test "schedule restrictions and ownership are enforced" do
    patch "/api/venues/#{@venue.id}", params: { venue: { booking_enabled: false } }, headers: headers_for(@buyer), as: :json
    assert_response :not_found
    @venue.update!(blocked_dates: [ @date.iso8601 ])
    assert_empty @venue.slots_on(@date)
    book(input)
    assert_response :conflict
    @venue.update!(blocked_dates: [], opening_days: [ (@date.wday + 1) % 7 ])
    assert_empty @venue.slots_on(@date)
    assert_empty @venue.slots_on(@date + 400)
    @venue.update!(opening_days: [ @date.wday ], booking_enabled: false)
    assert_empty @venue.slots_on(@date)
    @venue.update!(booking_enabled: true)
    patch "/api/venues/#{@venue.id}", params: { venue: { closing_time: "08:00" } }, headers: headers_for(@owner), as: :json
    assert_response :unprocessable_entity
    get "/api/venues/#{@venue.id}/slots", params: { date: "invalid" }, headers: headers_for(@buyer)
    assert_response :unprocessable_entity
    get "/api/venues/#{@venue.id}/slots", params: { date: @date.iso8601 }, headers: headers_for(@buyer)
    assert_response :success
    assert_equal 3, response.parsed_body["slots"].size
  end

  test "booking history is private and mock payments require local preview" do
    book(input)
    assert_response :created
    get "/api/venue_bookings", headers: headers_for(@owner)
    assert_empty response.parsed_body
    get "/api/venue_bookings?hosting=true", headers: headers_for(@owner)
    assert_equal 1, response.parsed_body.size
    get "/api/venue_bookings?hosting=true", headers: headers_for(@buyer)
    assert_empty response.parsed_body
    Rails.configuration.x.local_preview = false
    book(input)
    assert_response :forbidden
    @venue.update!(price_from: 0)
    book(input(start_at: @venue.slots_on(@date).last[:startAt], payment_mode: "free", expected_amount_cents: 0))
    assert_response :created
  end

  test "past published events allow only explicit local mock checkout and optional tickets block all ticket endpoints" do
    event = Event.create!(organizer: @owner, venue: @venue, title: "Past test", category: "Music", start_at: 2.days.ago, capacity: 10, status: "published", price_from: 0)
    data = { event_id: event.id, quantity: 1, request_key: SecureRandom.uuid, expected_unit_amount_cents: 0, payment_mode: "free" }
    post "/api/orders", params: { order: data }, headers: headers_for(@buyer), as: :json
    assert_response :unprocessable_entity
    post "/api/orders", params: { order: data.merge(payment_mode: "mock") }, headers: headers_for(@buyer), as: :json
    assert_response :created
    assert_not event.update(ticketing_enabled: false)
    event = Event.create!(organizer: @owner, venue: @venue, title: "Open event", category: "Music", start_at: 2.days.from_now, capacity: 10, status: "published", ticketing_enabled: false)
    post "/api/orders", params: { order: data.merge(event_id: event.id, request_key: SecureRandom.uuid) }, headers: headers_for(@buyer), as: :json
    assert_response :unprocessable_entity
    post "/api/tickets", params: { event_id: event.id, request_key: SecureRandom.uuid }, headers: headers_for(@buyer), as: :json
    assert_response :unprocessable_entity
    Rails.configuration.x.local_preview = false
    post "/api/orders", params: { order: data.merge(payment_mode: "mock", request_key: SecureRandom.uuid) }, headers: headers_for(@buyer), as: :json
    assert_response :forbidden
  end
end
