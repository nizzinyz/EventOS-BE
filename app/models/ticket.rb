class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :order, optional: true
  before_validation :assign_code, on: :create
  validates :code, :request_key, presence: true

  def api_attributes
    { id: id.to_s, code: code, createdAt: created_at, event: event.api_attributes,
      paymentMode: order&.payment_mode || "free", orderReference: order&.reference,
      amountCents: order&.unit_amount_cents || 0, checkedInAt: checked_in_at }
  end

  private

  def assign_code
    self.code ||= SecureRandom.uuid
  end
end
