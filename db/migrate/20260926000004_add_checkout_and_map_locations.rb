class AddCheckoutAndMapLocations < ActiveRecord::Migration[8.1]
  def change
    [ :venues, :events ].each do |table|
      add_column table, :latitude, :decimal, precision: 10, scale: 7
      add_column table, :longitude, :decimal, precision: 10, scale: 7
      add_check_constraint table, "(latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)", name: "#{table}_valid_coordinates"
    end
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.string :reference, :request_key, :payment_mode, :status, null: false
      t.integer :quantity, :unit_amount_cents, :total_amount_cents, null: false
      t.string :currency, default: "ZAR", null: false
      t.timestamps
    end
    add_index :orders, :reference, unique: true
    add_index :orders, [ :user_id, :request_key ], unique: true
    add_check_constraint :orders, "quantity BETWEEN 1 AND 10 AND unit_amount_cents >= 0 AND total_amount_cents = quantity * unit_amount_cents", name: "orders_valid_amounts"
    add_reference :tickets, :order, foreign_key: true
    add_column :tickets, :checked_in_at, :datetime
  end
end
