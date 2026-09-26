class AddVenueSlotBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :ticketing_enabled, :boolean, null: false, default: true
    add_column :venues, :ticketing_enabled, :boolean, null: false, default: false
    add_column :venues, :booking_enabled, :boolean, null: false, default: false
    add_column :venues, :opening_days, :jsonb, null: false, default: [ 1, 2, 3, 4, 5, 6, 0 ]
    add_column :venues, :blocked_dates, :jsonb, null: false, default: []
    add_column :venues, :opening_time, :string, null: false, default: "09:00"
    add_column :venues, :closing_time, :string, null: false, default: "18:00"
    add_column :venues, :slot_minutes, :integer, null: false, default: 180
    create_table :venue_bookings do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :request_key, null: false
      t.string :reference, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.integer :guests, null: false
      t.integer :amount_cents, null: false
      t.string :payment_mode, null: false
      t.string :status, null: false
      t.boolean :ticketed, null: false, default: false
      t.timestamps
    end
    add_index :venue_bookings, [ :user_id, :request_key ], unique: true
    add_index :venue_bookings, :reference, unique: true
    add_check_constraint :venue_bookings, "end_at > start_at AND guests > 0 AND amount_cents >= 0", name: "valid_venue_booking"
  end
end
