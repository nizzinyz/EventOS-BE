class AddPosterConfigToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events,
               :poster_config,
               :jsonb,
               null: false,
               default: {}
  end
end