class Venue < ApplicationRecord
  validates :name, presence: true
  validates :city, presence: true
  validates :address, presence: true

  validates :capacity,
            numericality: { greater_than_or_equal_to: 0 }

  validates :price_from,
            numericality: { greater_than_or_equal_to: 0 }

  validates :rating,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 5
            },
            allow_nil: true

  validates :currency,
            inclusion: { in: %w[ZAR] }
end