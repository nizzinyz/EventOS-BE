class VenueVerificationSubmission < ApplicationRecord
  STATUSES = %w[submitted approved rejected].freeze
  belongs_to :venue
  belongs_to :submitted_by, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true
  validates :status, inclusion: { in: STATUSES }
  validates :legal_name, :contact_name, :contact_email, :contact_phone, presence: true
  validates :documents, length: { minimum: 1 }
end
