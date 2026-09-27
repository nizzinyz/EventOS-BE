class AddAdministrationAndVenueVerification < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :platform_role, :string, null: false, default: "user"
    add_column :venues, :verification_status, :string, null: false, default: "draft"
    create_table :venue_verification_submissions do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "submitted"
      t.string :legal_name, null: false
      t.string :contact_name, null: false
      t.string :contact_email, null: false
      t.string :contact_phone, null: false
      t.jsonb :documents, null: false, default: []
      t.text :notes
      t.text :decision_reason
      t.datetime :reviewed_at
      t.timestamps
    end
    create_table :admin_audit_logs do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :admin_audit_logs, [:target_type, :target_id]
    add_check_constraint :users, "platform_role IN ('user', 'admin')", name: "users_platform_role"
    add_check_constraint :venues, "verification_status IN ('draft', 'pending_review', 'verified', 'rejected', 'suspended')", name: "venues_verification_status"
    add_check_constraint :venue_verification_submissions, "status IN ('submitted', 'approved', 'rejected')", name: "verification_submission_status"

    User.reset_column_information
    Venue.reset_column_information
    # Listings created before verification existed remain visible; only new
    # venue submissions begin as drafts.
    Venue.update_all(verification_status: "verified")
    User.find_by(email: "nizhar123mna@gmail.com")&.update_columns(platform_role: "admin")
  end

  def down
    remove_column :users, :platform_role
    remove_column :venues, :verification_status
    drop_table :admin_audit_logs
    drop_table :venue_verification_submissions
  end
end
