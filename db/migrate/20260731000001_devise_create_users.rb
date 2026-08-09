class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # ── Profile ───────────────────────────────────────────────────────────
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :avatar_url
      t.string :date_of_birth   # encrypted via ActiveRecord encryption

      # ── Devise: database_authenticatable ──────────────────────────────────
      t.string :encrypted_password, null: false, default: ""

      # ── Devise: recoverable ───────────────────────────────────────────────
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      # ── Devise: rememberable ──────────────────────────────────────────────
      t.datetime :remember_created_at

      # ── Devise: trackable ─────────────────────────────────────────────────
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # ── Devise: confirmable ───────────────────────────────────────────────
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      # ── Devise: lockable ──────────────────────────────────────────────────
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      # ── devise-jwt: JTIMatcher (one active token per user; invalidate on sign-out) ──
      t.string :jti, null: false

      # ── Public UUID (safe to expose in URLs) ──────────────────────────────
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :jti,                  unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
    add_index :users, :public_id,            unique: true
  end
end
