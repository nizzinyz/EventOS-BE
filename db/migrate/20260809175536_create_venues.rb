class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.text :description

      # Will become a proper User association when auth/roles are connected.
      t.integer :owner_id

      t.string :city, null: false
      t.string :province
      t.string :address, null: false

      t.integer :capacity, null: false, default: 0
      t.decimal :price_from, precision: 12, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "ZAR"

      t.string :image_url

      t.text :amenities, array: true, default: []
      t.text :categories, array: true, default: []

      t.decimal :rating, precision: 3, scale: 2, default: 0
      t.integer :review_count, null: false, default: 0

      t.boolean :available, null: false, default: true
      t.boolean :featured, null: false, default: false

      t.timestamps
    end

    add_index :venues, :owner_id
    add_index :venues, :city
    add_index :venues, :available
    add_index :venues, :featured
  end
end