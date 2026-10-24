# Repeatable local demo data. It is intentionally safe to run more than once.
# All demo accounts use password: Password123!

if Rails.env.test? && ENV["SEED_TEST_DATA"] != "true"
  puts "Skipping demo data in the test environment. Set SEED_TEST_DATA=true to include it."
else

def demo_user(email, first_name, last_name, city)
  User.find_or_initialize_by(email: email).tap do |user|
    user.assign_attributes(first_name: first_name, last_name: last_name, city: city,
      password: "Password123!", password_confirmation: "Password123!", confirmed_at: Time.current)
    user.save!
  end
end

def demo_venue(owner, attributes)
  Venue.find_or_initialize_by(name: attributes[:name], city: attributes[:city]).tap do |venue|
    venue.assign_attributes(attributes.merge(owner: owner))
    venue.save!
  end
end

def demo_event(organizer, venue, attributes)
  Event.find_or_initialize_by(title: attributes[:title], organizer: organizer).tap do |event|
    event.assign_attributes(attributes.merge(organizer: organizer, venue: venue))
    event.save!
  end
end

organizer = demo_user("demo.organizer@roam.local", "Aisha", "Mokoena", "Johannesburg")
venue_owner = demo_user("demo.venue@roam.local", "Liam", "Jacobs", "Cape Town")
attendee = demo_user("demo.attendee@roam.local", "Thandi", "Ndlovu", "Pretoria")
scanner = demo_user("demo.scanner@roam.local", "Sam", "Dlamini", "Johannesburg")
manager = demo_user("demo.manager@roam.local", "Mia", "Botha", "Cape Town")

zone = ActiveSupport::TimeZone["Africa/Johannesburg"]
flagship_start = zone.parse("#{14.days.from_now.to_date.iso8601} 18:00")
private_start = zone.parse("#{18.days.from_now.to_date.iso8601} 16:00")
community_start = zone.parse("#{21.days.from_now.to_date.iso8601} 10:00")
lapa_market_start = zone.parse("#{28.days.from_now.to_date.iso8601} 11:00")
lapa_cinema_start = zone.parse("#{30.days.from_now.to_date.iso8601} 18:00")

rooftop = demo_venue(venue_owner,
  name: "Demo Skyline Rooftop", city: "Johannesburg", province: "Gauteng", address: "88 Commissioner Street",
  description: "A rooftop demo venue for ticketing, staff access and booking availability.", capacity: 500,
  price_from: 18_000, image_url: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819",
  categories: ["Nightlife", "Music"], amenities: ["Bar", "Parking", "Stage"], booking_enabled: true,
  ticketing_enabled: true, opening_time: "10:00", closing_time: "23:00", slot_minutes: 180,
  setup_buffer_minutes: 60, cleanup_buffer_minutes: 60, blocked_dates: [], blocked_periods: [], verification_status: "verified")

garden = demo_venue(venue_owner,
  name: "Demo Greenhouse", city: "Cape Town", province: "Western Cape", address: "12 Kloof Street",
  description: "A private-function venue with a deliberately blocked afternoon for availability testing.", capacity: 120,
  price_from: 9_500, image_url: "https://images.unsplash.com/photo-1464366400600-7168b8af9bc3",
  categories: ["Weddings", "Corporate"], amenities: ["Catering", "Accessible", "Garden"], booking_enabled: true,
  opening_time: "08:00", closing_time: "22:00", slot_minutes: 120, setup_buffer_minutes: 90,
  cleanup_buffer_minutes: 60, blocked_dates: [],
  blocked_periods: [{ "startAt" => (private_start + 2.hours).iso8601, "endAt" => (private_start + 4.hours).iso8601 }], verification_status: "verified")

zwartkop_lapa = demo_venue(venue_owner,
  name: "Zwartkop Lapa Resort", city: "Centurion", province: "Gauteng", address: "Wierda Rd, Zwartkop 356-Jr",
  description: "A City of Tshwane outdoor lapa resort on the Hennops River, suited to picnics, camping and group functions. Demo listing for tester workflows; confirm availability and pricing with the venue.",
  capacity: 150, price_from: 0, image_url: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
  categories: ["Outdoor", "Weddings", "Community"], amenities: ["Lapa", "Braai facilities", "Picnic areas", "Parking"],
  booking_enabled: true, ticketing_enabled: true, opening_time: "07:00", closing_time: "19:00", slot_minutes: 180,
  setup_buffer_minutes: 60, cleanup_buffer_minutes: 60, blocked_dates: [], blocked_periods: [],
  latitude: -25.836733, longitude: 28.124280, verification_status: "verified")

# Book venue first, then create the event with that booking. This exercises the
# intentional VenueBooking != Event relationship.
booking = VenueBooking.find_or_initialize_by(user: organizer, request_key: "a4e394c1-83d1-4c7a-b1ed-2c9cc294aaa1")
booking.assign_attributes(venue: rooftop, start_at: flagship_start - 1.hour, end_at: flagship_start + 6.hours,
  guests: 350, amount_cents: 1_800_000, payment_mode: "mock", status: "completed", ticketed: true)
booking.save!

flagship = demo_event(organizer, rooftop,
  title: "Demo: Summer Rooftop Sessions", description: "Live amapiano, sunset views and a full QR check-in flow.",
  category: "Music", start_at: flagship_start, end_at: flagship_start + 5.hours, capacity: 350, price_from: 250,
  status: "published", access_type: "ticketed", age_rating: "18_plus", visibility: "public",
  venue_booking: booking, poster_config: { "template" => "neon", "palette" => "electric", "background" => "gradient", "tagline" => "Doors at 18:00", "highlights" => ["Live DJs", "Rooftop", "18+"] })

invitation = demo_event(organizer, garden,
  title: "Demo: The Khumalo Wedding", description: "A private invitation event used to test restricted access and RSVP-ready configuration.",
  category: "Community", start_at: private_start, end_at: private_start + 5.hours, capacity: 90, price_from: 0,
  ticketing_enabled: false, status: "published", access_type: "invitation", age_rating: "all_ages", visibility: "private",
  poster_config: { "template" => "luxury", "palette" => "sunset", "background" => "solid", "tagline" => "Celebrating together", "highlights" => ["Private", "RSVP required"] })

guest_list = demo_event(organizer, garden,
  title: "Demo: Founders Breakfast", description: "An unlisted guest-list event for testing non-ticketed admission workflows.",
  category: "Business", start_at: community_start, end_at: community_start + 3.hours, capacity: 60, price_from: 0,
  ticketing_enabled: false, status: "published", access_type: "guest_list", age_rating: "13_plus", visibility: "unlisted",
  poster_config: { "template" => "festival", "palette" => "emerald", "background" => "gradient", "tagline" => "Ideas over breakfast", "highlights" => ["Unlisted", "Guest list"] })

lapa_market = demo_event(organizer, zwartkop_lapa,
  title: "Demo: Zwartkop Riverside Market", description: "A mock outdoor market event for testing a real Centurion venue listing, discovery and ticket flows.",
  category: "Community", start_at: lapa_market_start, end_at: lapa_market_start + 6.hours, capacity: 150, price_from: 80,
  status: "published", access_type: "ticketed", age_rating: "all_ages", visibility: "public",
  poster_config: { "template" => "festival", "palette" => "emerald", "background" => "gradient", "tagline" => "Local makers by the river", "highlights" => ["Mock event", "Outdoor", "All ages"] })

lapa_cinema = demo_event(organizer, zwartkop_lapa,
  title: "Demo: Lapa Open-Air Cinema", description: "A mock evening screening for testing event discovery, venue details and future payment work.",
  category: "Entertainment", start_at: lapa_cinema_start, end_at: lapa_cinema_start + 4.hours, capacity: 120, price_from: 120,
  status: "published", access_type: "ticketed", age_rating: "13_plus", visibility: "public",
  poster_config: { "template" => "neon", "palette" => "electric", "background" => "gradient", "tagline" => "Bring a blanket", "highlights" => ["Mock event", "Open-air", "13+"] })

[[flagship, scanner, "scanner"], [flagship, manager, "event_manager"], [invitation, manager, "viewer"]].each do |event, user, role|
  membership = EventMember.find_or_initialize_by(event: event, user: user)
  membership.update!(role: role)
end

order = Order.find_or_initialize_by(user: attendee, request_key: "b5f394c1-83d1-4c7a-b1ed-2c9cc294aaa2")
order.assign_attributes(event: flagship, quantity: 1, payment_mode: "mock", status: "completed",
  unit_amount_cents: 25_000, total_amount_cents: 25_000, currency: "ZAR")
order.save!
Ticket.find_or_create_by!(user: attendee, event: flagship, order: order, request_key: "#{order.reference}:0")

EventReaction.find_or_create_by!(user: attendee, event: flagship) { |reaction| reaction.saved = true; reaction.liked = true }
BookingRequest.find_or_create_by!(user: attendee, venue: garden, event_date: community_start.to_date) do |request|
  request.guests = 40
  request.message = "Demo booking request for a product walk-through."
  request.status = "pending"
end

puts "Seeded ROAM demo data. Sign in as demo.organizer@roam.local or demo.attendee@roam.local (Password123!)."
end
