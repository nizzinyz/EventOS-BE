class AddEventOperations < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :venue_booking, foreign_key: true
    add_column :events, :access_type, :string, null: false, default: "ticketed"
    add_column :events, :age_rating, :string, null: false, default: "all_ages"
    add_column :events, :visibility, :string, null: false, default: "public"

    add_column :venues, :setup_buffer_minutes, :integer, null: false, default: 0
    add_column :venues, :cleanup_buffer_minutes, :integer, null: false, default: 0
    add_column :venues, :blocked_periods, :jsonb, null: false, default: []

    create_table :event_members do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.timestamps
    end
    add_index :event_members, [:event_id, :user_id], unique: true
    add_check_constraint :events, "access_type IN ('ticketed', 'invitation', 'guest_list')", name: "events_access_type"
    add_check_constraint :events, "age_rating IN ('all_ages', '13_plus', '16_plus', '18_plus', '21_plus')", name: "events_age_rating"
    add_check_constraint :events, "visibility IN ('public', 'private', 'unlisted')", name: "events_visibility"
    add_check_constraint :venues, "setup_buffer_minutes >= 0 AND cleanup_buffer_minutes >= 0", name: "venues_nonnegative_buffers"
  end
end
