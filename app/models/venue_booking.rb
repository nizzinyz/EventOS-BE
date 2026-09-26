class VenueBooking < ApplicationRecord
  belongs_to :venue
  belongs_to :user
  before_validation { self.reference ||= SecureRandom.uuid }
  validates :request_key, :reference, :start_at, :end_at, presence: true
  validates :status, inclusion: { in: %w[completed declined cancelled] }
  validates :payment_mode, inclusion: { in: %w[free mock] }
  validates :guests, numericality: { only_integer: true, greater_than: 0 }
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def api_attributes
    { id: id.to_s, venueId: venue_id.to_s, venueName: venue.name, reference: reference,
      startAt: start_at, endAt: end_at, guests: guests, amountCents: amount_cents,
      status: status, paymentMode: payment_mode, ticketed: ticketed }
  end
end
