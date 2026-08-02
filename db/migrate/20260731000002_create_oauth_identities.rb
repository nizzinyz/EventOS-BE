class CreateOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_identities do |t|
      t.references :user, null: false, foreign_key: true, index: true

      # Provider info
      t.string :provider, null: false  # google_oauth2 | apple
      t.string :uid,      null: false  # provider's unique user id

      # Tokens
      t.text     :access_token
      t.text     :refresh_token
      t.text     :id_token           # Apple uses a signed JWT id_token
      t.datetime :token_expires_at

      # Cached provider profile snapshot (kept in sync on each sign-in)
      t.string :name
      t.string :email
      t.string :avatar_url

      # Full raw payload from the provider for forward-compatibility
      t.jsonb :raw_info, default: {}

      t.timestamps
    end

    add_index :oauth_identities, %i[provider uid], unique: true
  end
end
