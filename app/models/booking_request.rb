class BookingRequest < ApplicationRecord
  belongs_to :user
  belongs_to :venue
  validates :event_date, :message, presence: true
  validates :message, length: { maximum: 2000 }
  validates :guests, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: %w[pending accepted declined] }
  validate :booking_limits, on: :create

  def api_attributes
    { id: id.to_s, venueId: venue_id.to_s, venueName: venue.name,
      requesterName: user.full_name, eventDate: event_date, guests: guests,
      message: message, status: status, canRespond: false }
  end

  private

  def booking_limits
    errors.add(:venue, "is not accepting enquiries") if venue && !venue.available?
    errors.add(:event_date, "must be today or later") if event_date && event_date < Date.current
    errors.add(:guests, "exceeds venue capacity") if venue && guests && guests > venue.capacity
  end
end
