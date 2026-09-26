class Event < ApplicationRecord
  include MapLocation
  validates :ticketing_enabled, inclusion: { in: [ true, false ] }
  belongs_to :organizer, class_name: "User"
  belongs_to :venue, optional: true
  has_many :tickets, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :event_reactions, dependent: :destroy
  validates :title, :category, :city, :address, :venue_name, :start_at, presence: true
  validates :status, inclusion: { in: %w[draft published cancelled] }
  validates :currency, inclusion: { in: [ "ZAR" ] }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_from, numericality: { greater_than_or_equal_to: 0 }
  validate :valid_schedule_and_capacity
  before_validation :copy_venue_location
  before_validation :copy_legacy_organizer_name

  def api_attributes
    attributes.except("organizer_id").transform_keys { |key| key.camelize(:lower) }.merge(
      "organizerId" => organizer&.public_id, "organizerName" => organizer&.full_name || self[:organizer_name] || "Organizer",
      "latitude" => venue ? venue.latitude : latitude, "longitude" => venue ? venue.longitude : longitude,
      "attendeeCount" => tickets.size, "likeCount" => event_reactions.count(&:liked), "saveCount" => event_reactions.count(&:saved),
      "posterConfig" => poster_config.deep_transform_keys { |key| key.camelize(:lower) }
    )
  end

  private

  def copy_legacy_organizer_name
    self[:organizer_name] = organizer.full_name if has_attribute?(:organizer_name) && organizer
  end

  def copy_venue_location
    return unless venue
    self.venue_name = venue.name
    self.city, self.province, self.address = venue.city, venue.province, venue.address
    self.latitude, self.longitude = venue.latitude, venue.longitude
  end

  def valid_schedule_and_capacity
    errors.add(:ticketing_enabled, "cannot be disabled after tickets are issued") if persisted? && !ticketing_enabled && tickets.exists?
    errors.add(:end_at, "must be after the start") if end_at && start_at && end_at <= start_at
    errors.add(:capacity, "exceeds venue capacity") if venue && capacity && capacity > venue.capacity
    errors.add(:capacity, "cannot be below tickets issued") if persisted? && capacity && capacity < tickets.count
    if persisted? && tickets.exists? && status_changed? && status == "draft"
      errors.add(:status, "cannot return to draft after tickets are issued")
    end
  end
end
