class User < ApplicationRecord
  # ── devise-jwt revocation strategy ──────────────────────────────────────────
  # JTIMatcher: each user stores one active jti; signing out regenerates it,
  # immediately invalidating every outstanding token for that user.
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # ── Devise modules ───────────────────────────────────────────────────────────
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,         # validates email format & password length
         :confirmable,         # email verification flow
         :lockable,            # locks account after N failed attempts
         :trackable,           # records sign-in timestamps / IPs
         :omniauthable,
         :jwt_authenticatable,
         omniauth_providers: %i[google_oauth2 apple],
         jwt_revocation_strategy: self

  # ── PII encryption ───────────────────────────────────────────────────────────
  # Deterministic = same plaintext → same ciphertext; required for DB-level
  # uniqueness constraints and Devise's find_by(email:) lookups.
  encrypts :email,        deterministic: true
  encrypts :first_name
  encrypts :last_name
  encrypts :date_of_birth

  # ── Associations ─────────────────────────────────────────────────────────────
  has_many :oauth_identities, dependent: :destroy

  # ── Validations ──────────────────────────────────────────────────────────────
  validates :first_name, :last_name, presence: true

  # ── Callbacks ────────────────────────────────────────────────────────────────
  before_validation :set_public_id, on: :create
  before_create :set_jti

  # ── Scopes ───────────────────────────────────────────────────────────────────
  scope :active, -> { where(locked_at: nil) }

  # ── Helpers ──────────────────────────────────────────────────────────────────
  # Use public_id (UUID) in URLs — never expose the sequential integer PK.
  def to_param = public_id

  def full_name
    "#{first_name} #{last_name}".strip
  end

  # OAuth-only accounts carry NO password at all: OauthUserService builds the
  # identity before the user is first saved, so Devise never demands one here.
  # Email/password accounts keep Devise's standard requirement. An OAuth user
  # can still set a password later via the forgot-password flow.
  def password_required?
    super && oauth_identities.none?
  end

  # Public-safe JSON representation used across all API responses.
  def api_attributes
    {
      id:               public_id,
      email:            email,
      first_name:       first_name,
      last_name:        last_name,
      full_name:        full_name,
      avatar_url:       avatar_url,
      confirmed:        confirmed?,
      linked_providers: oauth_identities.map(&:provider),
      created_at:       created_at
    }
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end

  def set_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
