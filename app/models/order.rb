class Order < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :tickets, dependent: :restrict_with_error
  before_validation :assign_reference, on: :create
  validates :reference, :request_key, presence: true
  validates :status, inclusion: { in: %w[completed declined cancelled] }
  validates :payment_mode, inclusion: { in: %w[free mock] }
  validates :quantity, numericality: { only_integer: true, in: 1..10 }

  def api_attributes
    { id: id.to_s, reference: reference, status: status, paymentMode: payment_mode,
      quantity: quantity, unitAmountCents: unit_amount_cents, totalAmountCents: total_amount_cents,
      currency: currency, createdAt: created_at, eventTitle: event.title,
      tickets: tickets.includes(event: [ :organizer, :venue, :tickets, :event_reactions ]).map(&:api_attributes) }
  end

  private

  def assign_reference
    self.reference ||= SecureRandom.uuid
  end
end
