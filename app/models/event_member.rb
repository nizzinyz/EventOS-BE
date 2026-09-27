class EventMember < ApplicationRecord
  ROLES = %w[event_manager ticket_manager scanner viewer].freeze

  belongs_to :event
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :event_id }

  def api_attributes
    { id: id.to_s, role: role, userId: user.public_id, name: user.full_name, email: user.email }
  end
end
