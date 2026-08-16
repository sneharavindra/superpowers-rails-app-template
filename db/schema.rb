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

ActiveRecord::Schema[8.1].define(version: 2026_08_16_034424) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "fosm_access_events", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "performed_by_id"
    t.string "performed_by_label"
    t.string "performed_by_type"
    t.string "resource_id"
    t.string "resource_type", null: false
    t.string "role_name", null: false
    t.string "user_id", null: false
    t.string "user_label"
    t.string "user_type", null: false
    t.index ["action"], name: "idx_fosm_ae_action"
    t.index ["created_at"], name: "idx_fosm_ae_created_at"
    t.index ["resource_type", "resource_id"], name: "idx_fosm_ae_resource"
    t.index ["user_type", "user_id"], name: "idx_fosm_ae_user"
  end

  create_table "fosm_role_assignments", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "granted_by_id"
    t.string "granted_by_type"
    t.string "resource_id"
    t.string "resource_type", null: false
    t.string "role_name", null: false
    t.string "user_id", null: false
    t.string "user_type", null: false
    t.index ["resource_type", "resource_id", "role_name"], name: "idx_fosm_roles_resource_role"
    t.index ["user_type", "user_id", "resource_type", "resource_id", "role_name"], name: "idx_fosm_roles_unique", unique: true
    t.index ["user_type", "user_id", "resource_type", "resource_id"], name: "idx_fosm_roles_user_resource"
  end

  create_table "fosm_transition_logs", force: :cascade do |t|
    t.string "actor_id"
    t.string "actor_label"
    t.string "actor_type"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "event_name", null: false
    t.string "from_state", null: false
    t.json "metadata", default: {}
    t.string "record_id", null: false
    t.string "record_type", null: false
    t.string "snapshot_reason"
    t.json "state_snapshot"
    t.string "to_state", null: false
    t.index ["actor_label"], name: "idx_fosm_tl_actor"
    t.index ["created_at"], name: "idx_fosm_tl_created_at"
    t.index ["event_name"], name: "idx_fosm_tl_event"
    t.index ["record_type", "record_id"], name: "idx_fosm_tl_record"
    t.index ["snapshot_reason"], name: "idx_fosm_tl_snapshot_reason"
  end

  create_table "fosm_webhook_subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "event_name", null: false
    t.string "model_class_name", null: false
    t.string "secret_token"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["active"], name: "idx_fosm_webhooks_active"
    t.index ["model_class_name", "event_name"], name: "idx_fosm_webhooks_model_event"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "users", "accounts"
end
