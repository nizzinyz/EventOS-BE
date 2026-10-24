class VenueVerificationSubmission < ApplicationRecord
  STATUSES = %w[submitted approved rejected].freeze
  belongs_to :venue
  belongs_to :submitted_by, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true
  validates :status, inclusion: { in: STATUSES }
  validates :legal_name, :contact_name, :contact_email, :contact_phone, presence: true
  validates :documents, length: { minimum: 1 }
  validate :documents_use_secure_urls

  private

  def documents_use_secure_urls
    return unless documents.is_a?(Array)

    documents.each do |document|
      url = document.is_a?(Hash) ? document["url"] || document[:url] : nil
      uri = URI.parse(url.to_s)
      next if uri.is_a?(URI::HTTPS) && uri.host.present?

      errors.add(:documents, "must contain HTTPS document URLs")
      break
    rescue URI::InvalidURIError
      errors.add(:documents, "must contain valid HTTPS document URLs")
      break
    end
  end
end
