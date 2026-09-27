class Venue < ApplicationRecord
  include MapLocation
  validates :booking_enabled, :ticketing_enabled, inclusion: { in: [ true, false ] }
  belongs_to :owner, class_name: "User"
  has_many :events, dependent: :restrict_with_error
  has_many :booking_requests, dependent: :restrict_with_error
  has_many :venue_bookings, dependent: :restrict_with_error
  has_many :venue_verification_submissions, dependent: :restrict_with_error
  validates :slot_minutes, inclusion: { in: [ 30, 60, 90, 120, 180, 240, 360, 480, 720 ] }
  validate :valid_booking_schedule
  validates :verification_status, inclusion: { in: %w[draft pending_review verified rejected suspended] }

  def slots_on(date)
    today = Time.current.in_time_zone("Africa/Johannesburg").to_date
    return [] unless verification_status == "verified" && available && booking_enabled && date.between?(today, today + 365) && opening_days.include?(date.wday) && !blocked_dates.include?(date.iso8601)
    zone = ActiveSupport::TimeZone["Africa/Johannesburg"]
    cursor = zone.parse("#{date.iso8601} #{opening_time}")
    closing = zone.parse("#{date.iso8601} #{closing_time}")
    bookings = venue_bookings.where(status: "completed").where("start_at < ? AND end_at > ?", closing + cleanup_buffer_minutes.minutes, cursor - setup_buffer_minutes.minutes).to_a
    slots = []
    while cursor + slot_minutes.minutes <= closing
      ending = cursor + slot_minutes.minutes
      slots << { startAt: cursor.iso8601, endAt: ending.iso8601,
        available: cursor > Time.current && blocked_periods.none? { |period| period_overlaps?(period, cursor, ending) } && bookings.none? { |booking| booking.start_at - setup_buffer_minutes.minutes < ending && booking.end_at + cleanup_buffer_minutes.minutes > cursor } }
      cursor = ending
    end
    slots
  end

  def valid_booking_schedule
    valid_times = [ opening_time, closing_time ].all? { |value| value.to_s.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/) }
    errors.add(:opening_time, "and closing time must be valid and on the same day") unless valid_times && opening_time < closing_time
    if valid_times && slot_minutes && ((Time.parse(closing_time) - Time.parse(opening_time)) / 60) < slot_minutes
      errors.add(:slot_minutes, "must fit inside opening hours")
    end
    errors.add(:opening_days, "must include valid weekdays") unless opening_days.is_a?(Array) && opening_days.any? && opening_days.all? { |day| day.is_a?(Integer) && (0..6).cover?(day) }
    valid_dates = blocked_dates.is_a?(Array) && blocked_dates.all? { |value| value.is_a?(String) && (Date.iso8601(value).iso8601 == value rescue false) }
    errors.add(:blocked_dates, "must contain dates in YYYY-MM-DD format") unless valid_dates
    errors.add(:blocked_periods, "must contain startAt and endAt ISO-8601 times") unless blocked_periods.is_a?(Array) && blocked_periods.all? { |period| valid_period?(period) }
    if persisted? && capacity && venue_bookings.where(status: "completed").where("end_at > ? AND guests > ?", Time.current, capacity).exists?
      errors.add(:capacity, "cannot be below guests in upcoming bookings")
    end
  end

  def period_overlaps?(period, start_at, end_at)
    Time.iso8601(period["startAt"] || period[:startAt]) < end_at && Time.iso8601(period["endAt"] || period[:endAt]) > start_at
  rescue ArgumentError, TypeError
    false
  end

  def valid_period?(period)
    start_at = Time.iso8601(period["startAt"] || period[:startAt])
    end_at = Time.iso8601(period["endAt"] || period[:endAt])
    end_at > start_at
  rescue ArgumentError, TypeError, NoMethodError
    false
  end
  validates :name, :city, :address, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_from, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: [ "ZAR" ] }

  def api_attributes
    attributes.except("owner_id").transform_keys { |key| key.camelize(:lower) }.merge(
      "ownerId" => owner&.public_id, "rating" => self[:rating] || 0, "reviewCount" => self[:review_count] || 0
    )
  end
end
