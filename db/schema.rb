# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_27_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "target_id", null: false
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_admin_audit_logs_on_actor_id"
    t.index ["target_type", "target_id"], name: "index_admin_audit_logs_on_target_type_and_target_id"
  end

  create_table "booking_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "event_date", null: false
    t.integer "guests", null: false
    t.text "message", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "venue_id", null: false
    t.index ["user_id"], name: "index_booking_requests_on_user_id"
    t.index ["venue_id"], name: "index_booking_requests_on_venue_id"
  end

  create_table "event_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id", "user_id"], name: "index_event_members_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_event_members_on_event_id"
    t.index ["user_id"], name: "index_event_members_on_user_id"
  end

  create_table "event_reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.boolean "liked", default: false, null: false
    t.boolean "saved", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_event_reactions_on_event_id"
    t.index ["user_id", "event_id"], name: "index_event_reactions_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_event_reactions_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "access_type", default: "ticketed", null: false
    t.string "address", null: false
    t.string "age_rating", default: "all_ages", null: false
    t.integer "attendee_count", default: 0, null: false
    t.integer "capacity", default: 100, null: false
    t.string "category", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "ZAR", null: false
    t.text "description"
    t.datetime "end_at"
    t.boolean "featured", default: false, null: false
    t.string "image_url"
    t.decimal "latitude", precision: 10, scale: 7
    t.integer "like_count", default: 0, null: false
    t.decimal "longitude", precision: 10, scale: 7
    t.integer "organizer_id"
    t.string "organizer_name", null: false
    t.jsonb "poster_config", default: {}, null: false
    t.decimal "price_from", precision: 12, scale: 2, default: "0.0", null: false
    t.string "province"
    t.integer "save_count", default: 0, null: false
    t.datetime "start_at", null: false
    t.string "status", default: "draft", null: false
    t.boolean "ticketing_enabled", default: true, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_booking_id"
    t.bigint "venue_id"
    t.string "venue_name", null: false
    t.string "video_url"
    t.string "visibility", default: "public", null: false
    t.index ["category"], name: "index_events_on_category"
    t.index ["city"], name: "index_events_on_city"
    t.index ["featured"], name: "index_events_on_featured"
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["start_at"], name: "index_events_on_start_at"
    t.index ["status"], name: "index_events_on_status"
    t.index ["venue_booking_id"], name: "index_events_on_venue_booking_id"
    t.index ["venue_id"], name: "index_events_on_venue_id"
    t.check_constraint "access_type::text = ANY (ARRAY['ticketed'::character varying::text, 'invitation'::character varying::text, 'guest_list'::character varying::text])", name: "events_access_type"
    t.check_constraint "age_rating::text = ANY (ARRAY['all_ages'::character varying::text, '13_plus'::character varying::text, '16_plus'::character varying::text, '18_plus'::character varying::text, '21_plus'::character varying::text])", name: "events_age_rating"
    t.check_constraint "latitude IS NULL AND longitude IS NULL OR latitude IS NOT NULL AND longitude IS NOT NULL AND latitude >= '-90'::integer::numeric AND latitude <= 90::numeric AND longitude >= '-180'::integer::numeric AND longitude <= 180::numeric", name: "events_valid_coordinates"
    t.check_constraint "visibility::text = ANY (ARRAY['public'::character varying::text, 'private'::character varying::text, 'unlisted'::character varying::text])", name: "events_visibility"
  end

  add_check_constraint "events", "capacity > 0 AND price_from >= 0::numeric", name: "events_positive_limits", validate: false

  create_table "oauth_identities", force: :cascade do |t|
    t.text "access_token"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.text "id_token"
    t.string "name"
    t.string "provider", null: false
    t.jsonb "raw_info", default: {}
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "ZAR", null: false
    t.bigint "event_id", null: false
    t.string "payment_mode", null: false
    t.integer "quantity", null: false
    t.string "reference", null: false
    t.string "request_key", null: false
    t.string "status", null: false
    t.integer "total_amount_cents", null: false
    t.integer "unit_amount_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_orders_on_event_id"
    t.index ["reference"], name: "index_orders_on_reference", unique: true
    t.index ["user_id", "request_key"], name: "index_orders_on_user_id_and_request_key", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "quantity >= 1 AND quantity <= 10 AND unit_amount_cents >= 0 AND total_amount_cents = (quantity * unit_amount_cents)", name: "orders_valid_amounts"
  end

  create_table "tickets", force: :cascade do |t|
    t.datetime "checked_in_at"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "order_id"
    t.string "request_key", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["code"], name: "index_tickets_on_code", unique: true
    t.index ["event_id"], name: "index_tickets_on_event_id"
    t.index ["order_id"], name: "index_tickets_on_order_id"
    t.index ["user_id", "request_key"], name: "index_tickets_on_user_id_and_request_key", unique: true
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.string "city"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "date_of_birth"
    t.string "email"
    t.boolean "email_updates", default: false, null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.jsonb "interests", default: [], null: false
    t.string "jti", null: false
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "platform_role", default: "user", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.check_constraint "platform_role::text = ANY (ARRAY['user'::character varying::text, 'admin'::character varying::text])", name: "users_platform_role"
  end

  create_table "venue_bookings", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "end_at", null: false
    t.integer "guests", null: false
    t.string "payment_mode", null: false
    t.string "reference", null: false
    t.string "request_key", null: false
    t.datetime "start_at", null: false
    t.string "status", null: false
    t.boolean "ticketed", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "venue_id", null: false
    t.index ["reference"], name: "index_venue_bookings_on_reference", unique: true
    t.index ["user_id", "request_key"], name: "index_venue_bookings_on_user_id_and_request_key", unique: true
    t.index ["user_id"], name: "index_venue_bookings_on_user_id"
    t.index ["venue_id"], name: "index_venue_bookings_on_venue_id"
    t.check_constraint "end_at > start_at AND guests > 0 AND amount_cents >= 0", name: "valid_venue_booking"
  end

  create_table "venue_verification_submissions", force: :cascade do |t|
    t.string "contact_email", null: false
    t.string "contact_name", null: false
    t.string "contact_phone", null: false
    t.datetime "created_at", null: false
    t.text "decision_reason"
    t.jsonb "documents", default: [], null: false
    t.string "legal_name", null: false
    t.text "notes"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "status", default: "submitted", null: false
    t.bigint "submitted_by_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["reviewed_by_id"], name: "index_venue_verification_submissions_on_reviewed_by_id"
    t.index ["submitted_by_id"], name: "index_venue_verification_submissions_on_submitted_by_id"
    t.index ["venue_id"], name: "index_venue_verification_submissions_on_venue_id"
    t.check_constraint "status::text = ANY (ARRAY['submitted'::character varying::text, 'approved'::character varying::text, 'rejected'::character varying::text])", name: "verification_submission_status"
  end

  create_table "venues", force: :cascade do |t|
    t.string "address", null: false
    t.text "amenities", default: [], array: true
    t.boolean "available", default: true, null: false
    t.jsonb "blocked_dates", default: [], null: false
    t.jsonb "blocked_periods", default: [], null: false
    t.boolean "booking_enabled", default: false, null: false
    t.integer "capacity", default: 0, null: false
    t.text "categories", default: [], array: true
    t.string "city", null: false
    t.integer "cleanup_buffer_minutes", default: 0, null: false
    t.string "closing_time", default: "18:00", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "ZAR", null: false
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.string "image_url"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "name", null: false
    t.jsonb "opening_days", default: [1, 2, 3, 4, 5, 6, 0], null: false
    t.string "opening_time", default: "09:00", null: false
    t.integer "owner_id"
    t.decimal "price_from", precision: 12, scale: 2, default: "0.0", null: false
    t.string "province"
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.integer "review_count", default: 0, null: false
    t.integer "setup_buffer_minutes", default: 0, null: false
    t.integer "slot_minutes", default: 180, null: false
    t.boolean "ticketing_enabled", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "verification_status", default: "draft", null: false
    t.index ["available"], name: "index_venues_on_available"
    t.index ["city"], name: "index_venues_on_city"
    t.index ["featured"], name: "index_venues_on_featured"
    t.index ["owner_id"], name: "index_venues_on_owner_id"
    t.check_constraint "latitude IS NULL AND longitude IS NULL OR latitude IS NOT NULL AND longitude IS NOT NULL AND latitude >= '-90'::integer::numeric AND latitude <= 90::numeric AND longitude >= '-180'::integer::numeric AND longitude <= 180::numeric", name: "venues_valid_coordinates"
    t.check_constraint "setup_buffer_minutes >= 0 AND cleanup_buffer_minutes >= 0", name: "venues_nonnegative_buffers"
    t.check_constraint "verification_status::text = ANY (ARRAY['draft'::character varying::text, 'pending_review'::character varying::text, 'verified'::character varying::text, 'rejected'::character varying::text, 'suspended'::character varying::text])", name: "venues_verification_status"
  end

  add_check_constraint "venues", "capacity > 0 AND price_from >= 0::numeric", name: "venues_positive_limits", validate: false

  add_foreign_key "admin_audit_logs", "users", column: "actor_id"
  add_foreign_key "booking_requests", "users"
  add_foreign_key "booking_requests", "venues"
  add_foreign_key "event_members", "events"
  add_foreign_key "event_members", "users"
  add_foreign_key "event_reactions", "events"
  add_foreign_key "event_reactions", "users"
  add_foreign_key "events", "venue_bookings"
  add_foreign_key "events", "venues"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "orders", "events"
  add_foreign_key "orders", "users"
  add_foreign_key "tickets", "events"
  add_foreign_key "tickets", "orders"
  add_foreign_key "tickets", "users"
  add_foreign_key "venue_bookings", "users"
  add_foreign_key "venue_bookings", "venues"
  add_foreign_key "venue_verification_submissions", "users", column: "reviewed_by_id"
  add_foreign_key "venue_verification_submissions", "users", column: "submitted_by_id"
  add_foreign_key "venue_verification_submissions", "venues"
end
