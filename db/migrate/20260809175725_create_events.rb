class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description

      # Will connect to User later.
      t.integer :organizer_id
      t.string :organizer_name, null: false

      t.references :venue,
                   null: true,
                   foreign_key: true

      t.string :venue_name, null: false

      t.string :category, null: false

      t.string :city, null: false
      t.string :province
      t.string :address, null: false

      t.datetime :start_at, null: false
      t.datetime :end_at

      t.string :image_url
      t.string :video_url

      t.decimal :price_from,
                precision: 12,
                scale: 2,
                null: false,
                default: 0

      t.string :currency,
               null: false,
               default: "ZAR"

      t.integer :attendee_count,
                null: false,
                default: 0

      t.integer :like_count,
                null: false,
                default: 0

      t.integer :save_count,
                null: false,
                default: 0

      t.boolean :featured,
                null: false,
                default: false

      t.string :status,
               null: false,
               default: "draft"

      t.timestamps
    end

    add_index :events, :organizer_id
    add_index :events, :category
    add_index :events, :city
    add_index :events, :status
    add_index :events, :start_at
    add_index :events, :featured
  end
end