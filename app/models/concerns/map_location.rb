module MapLocation
  extend ActiveSupport::Concern

  included do
    validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
    validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
    validate :coordinate_pair
  end

  private

  def coordinate_pair
    errors.add(:base, "Both latitude and longitude are required for a map pin") if latitude.nil? != longitude.nil?
  end
end
