class CreateEventReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :event_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.boolean :saved, default: false, null: false
      t.boolean :liked, default: false, null: false
      t.timestamps
    end
    add_index :event_reactions, [ :user_id, :event_id ], unique: true
  end
end
