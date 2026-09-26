class CreateBookingRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true
      t.date :event_date, null: false
      t.integer :guests, null: false
      t.text :message, null: false
      t.string :status, default: "pending", null: false
      t.timestamps
    end
  end
end
