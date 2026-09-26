require "test_helper"

class CheckoutTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.x.local_preview = true
    @owner = User.create!(email: "host-#{SecureRandom.hex(5)}@example.com", first_name: "Host", last_name: "Member", password: "Testing123!", confirmed_at: Time.current)
    @buyer = User.create!(email: "buyer-#{SecureRandom.hex(5)}@example.com", first_name: "Buyer", last_name: "Member", password: "Testing123!", confirmed_at: Time.current)
    @venue = Venue.create!(owner: @owner, name: "Test Hall", city: "Cape Town", province: "Western Cape", address: "1 Main Road", capacity: 10, latitude: -33.9249, longitude: 18.4241)
    @event = Event.create!(organizer: @owner, venue: @venue, title: "Paid meetup", category: "Music", start_at: 2.days.from_now, capacity: 3, status: "published", price_from: 125.50)
  end

  teardown do
    Rails.configuration.x.local_preview = false
  end

  def headers_for(user)
    token, = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}" }
  end

  def order_input(overrides = {})
    { event_id: @event.id, request_key: SecureRandom.uuid, quantity: 2, payment_mode: "mock", outcome: "completed", expected_unit_amount_cents: 12550 }.merge(overrides)
  end

  def checkout(input)
    post "/api/orders", params: { order: input }, headers: headers_for(@buyer), as: :json
  end

  test "mock purchase snapshots server price and retries issue tickets once" do
    input = order_input(total_amount_cents: 1)
    checkout(input)
    assert_response :created
    assert_equal 25100, response.parsed_body["totalAmountCents"]
    assert_equal "mock", response.parsed_body["paymentMode"]
    assert_equal 2, response.parsed_body["tickets"].size
    reference = response.parsed_body["reference"]
    @event.update!(price_from: 140)
    checkout(input)
    assert_response :success
    assert_equal reference, response.parsed_body["reference"]
    assert_equal 25100, response.parsed_body["totalAmountCents"]
    assert_equal 2, Ticket.count
    assert_equal 1, Order.count
    checkout(input.merge(quantity: 1))
    assert_response :conflict
  end

  test "declined and cancelled orders issue no tickets and leave capacity available" do
    %w[declined cancelled].each do |outcome|
      checkout(order_input(outcome: outcome))
      assert_response :created
      assert_equal outcome, response.parsed_body["status"]
    end
    assert_equal 0, Ticket.count
    checkout(order_input(quantity: 3))
    assert_response :created
    assert_equal 3, Ticket.count
    checkout(order_input(quantity: 1))
    assert_response :conflict
  end

  test "checkout rejects invalid quantity stale price and paid tickets using free mode" do
    [ 0, 11, 1.5, "abc" ].each do |quantity|
      checkout(order_input(quantity: quantity))
      assert_response :unprocessable_entity
    end
    checkout(order_input(expected_unit_amount_cents: 1))
    assert_response :conflict
    checkout(order_input(payment_mode: "free"))
    assert_response :unprocessable_entity
    assert_equal 0, Ticket.count
    assert_equal 0, Order.count
  end

  test "mock checkout fails closed outside preview while free orders still work" do
    Rails.configuration.x.local_preview = false
    checkout(order_input)
    assert_response :forbidden
    @event.update!(price_from: 0)
    checkout(order_input(payment_mode: "free", expected_unit_amount_cents: 0))
    assert_response :created
    assert_equal "free", response.parsed_body["paymentMode"]
  end

  test "order history is private and check-in is owner-only and single use" do
    checkout(order_input(quantity: 1))
    code = response.parsed_body["tickets"].first["code"]
    get "/api/orders", headers: headers_for(@owner), as: :json
    assert_empty response.parsed_body
    get "/api/orders", headers: headers_for(@buyer), as: :json
    assert_equal 1, response.parsed_body.size
    post "/api/events/#{@event.id}/check_ins", params: { code: code }, headers: headers_for(@buyer), as: :json
    assert_response :not_found
    post "/api/events/#{@event.id}/check_ins", params: { code: "roam-ticket:#{code}" }, headers: headers_for(@owner), as: :json
    assert_response :success
    post "/api/events/#{@event.id}/check_ins", params: { code: code }, headers: headers_for(@owner), as: :json
    assert_response :conflict
  end

  test "map coordinates are validated and events inherit venue pins" do
    assert_equal @venue.latitude, @event.latitude
    assert_equal @venue.longitude, @event.longitude
    patch "/api/venues/#{@venue.id}", params: { venue: { latitude: 100 } }, headers: headers_for(@owner), as: :json
    assert_response :unprocessable_entity
    patch "/api/venues/#{@venue.id}", params: { venue: { latitude: -34, longitude: 19 } }, headers: headers_for(@owner), as: :json
    assert_response :success
    get "/api/events/#{@event.id}", headers: headers_for(@buyer), as: :json
    assert_equal(-34, response.parsed_body["latitude"].to_f)
    assert_equal 19, response.parsed_body["longitude"].to_f
    patch "/api/venues/#{@venue.id}", params: { venue: { latitude: nil, longitude: nil } }, headers: headers_for(@owner), as: :json
    assert_response :success
    patch "/api/venues/#{@venue.id}", params: { venue: { latitude: -33 } }, headers: headers_for(@owner), as: :json
    assert_response :unprocessable_entity
  end
end
