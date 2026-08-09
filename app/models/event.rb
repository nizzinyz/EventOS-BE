class Event < ApplicationRecord
  belongs_to :venue, optional: true

  CATEGORIES = %w[
    Music
    Automotive
    Food
    Business
    Arts
    Sports
    Community
    Nightlife
  ].freeze

  STATUSES = %w[
    draft
    published
    cancelled
  ].freeze

  validates :title, presence: true
  validates :organizer_name, presence: true
  validates :venue_name, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :city, presence: true
  validates :address, presence: true
  validates :start_at, presence: true

  validates :status, inclusion: { in: STATUSES }
  validates :currency, inclusion: { in: %w[ZAR] }

  validates :price_from,
            numericality: { greater_than_or_equal_to: 0 }

  validates :attendee_count,
            :like_count,
            :save_count,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validate :end_after_start

  private

  def end_after_start
    return if end_at.blank? || start_at.blank?
    return if end_at > start_at

    errors.add(:end_at, "must be after the start date")
  end
end