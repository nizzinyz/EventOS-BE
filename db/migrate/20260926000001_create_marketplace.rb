class CreateMarketplace < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :bio, :text
    add_column :users, :city, :string
    add_column :users, :interests, :jsonb, default: [], null: false
    add_column :users, :email_updates, :boolean, default: false, null: false
    unless table_exists?(:venues)
      create_table :venues do |t|
        t.references :owner, null: false, foreign_key: { to_table: :users }
        t.string :name, :city, :province, :address, null: false
        t.text :description
        t.string :image_url
        t.integer :capacity, null: false
        t.decimal :price_from, precision: 12, scale: 2, default: 0, null: false
        t.string :currency, default: "ZAR", null: false
        t.jsonb :amenities, :categories, default: [], null: false
        t.boolean :available, default: true, null: false
        t.boolean :featured, default: false, null: false
        t.timestamps
      end
    end
    unless table_exists?(:events)
      create_table :events do |t|
        t.references :organizer, null: false, foreign_key: { to_table: :users }
        t.references :venue, foreign_key: true
        t.string :title, :venue_name, :category, :city, :province, :address
        t.text :description
        t.string :image_url, :video_url
        t.datetime :start_at, null: false
        t.datetime :end_at
        t.integer :capacity, default: 100, null: false
        t.decimal :price_from, precision: 12, scale: 2, default: 0, null: false
        t.string :currency, default: "ZAR", null: false
        t.string :status, default: "draft", null: false
        t.boolean :featured, default: false, null: false
        t.jsonb :poster_config, default: {}, null: false
        t.timestamps
      end
    end
    unless column_exists?(:events, :capacity)
      add_column :events, :capacity, :integer, default: 100, null: false
      execute <<~SQL
        UPDATE events SET capacity = GREATEST(1, venues.capacity)
        FROM venues WHERE events.venue_id = venues.id
      SQL
    end
    create_table :tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.string :code, null: false
      t.string :request_key, null: false
      t.timestamps
    end
    add_index :tickets, :code, unique: true
    add_index :tickets, [ :user_id, :request_key ], unique: true
    add_check_constraint :events, "capacity > 0 AND price_from >= 0", name: "events_positive_limits", validate: false
    add_check_constraint :venues, "capacity > 0 AND price_from >= 0", name: "venues_positive_limits", validate: false
  end
  def down
    raise ActiveRecord::IrreversibleMigration, "Marketplace tables may contain existing venue and event data"
  end
end
