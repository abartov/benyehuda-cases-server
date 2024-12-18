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

ActiveRecord::Schema.define(version: 2024_12_18_192045) do

  create_table "api_users", charset: "latin1", force: :cascade do |t|
    t.string "api_key"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["api_key"], name: "index_api_users_on_api_key", unique: true
    t.index ["email"], name: "index_api_users_on_email", unique: true
  end

  create_table "assignment_histories", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "task_id"
    t.string "role", limit: 16
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["task_id"], name: "index_assignment_histories_on_task_id"
    t.index ["user_id"], name: "index_assignment_histories_on_user_id"
  end

  create_table "audit_logs", charset: "latin1", force: :cascade do |t|
    t.string "backtrace"
    t.string "data"
    t.bigint "api_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["api_user_id"], name: "index_audit_logs_on_api_user_id"
  end

  create_table "audits", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "user_id"
    t.integer "action"
    t.text "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "task_id"
    t.text "changed_attrs"
    t.boolean "hidden", default: false
    t.index ["task_id"], name: "index_audits_on_task_id"
    t.index ["user_id", "created_at"], name: "index_audits_on_user_id_and_created_at"
  end

  create_table "comments", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "task_id"
    t.string "message", limit: 4096
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "editor_eyes_only", default: false
    t.boolean "is_rejection_reason", default: false
    t.boolean "is_abandoning_reason", default: false
    t.boolean "is_finished_reason"
    t.boolean "is_help_required_reason", default: false
    t.index ["task_id", "created_at", "editor_eyes_only"], name: "task_created_eyes"
  end

  create_table "custom_properties", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "property_id"
    t.integer "proprietary_id"
    t.string "proprietary_type", limit: 32
    t.string "custom_value", limit: 8192
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["proprietary_id", "proprietary_type"], name: "proprietary"
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.integer "user_id"
    t.integer "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean "done"
    t.index ["task_id"], name: "index_documents_on_task_id"
  end

  create_table "global_preferences", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.integer "ttl"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_global_preferences_on_name", unique: true
  end

  create_table "projects", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "title"
    t.string "parent_type", limit: 32
    t.string "property_type", limit: 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_public", default: true
    t.string "comment"
  end

  create_table "search_settings", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.string "search_key"
    t.string "search_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "search_key"], name: "index_search_settings_on_user_id_and_search_key"
  end

  create_table "sessions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "site_notices", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.datetime "start_displaying_at"
    t.datetime "end_displaying_at"
    t.string "html", limit: 8192
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["start_displaying_at", "end_displaying_at"], name: "index_site_notices_on_start_displaying_at_and_end_displaying_at"
  end

  create_table "task_kinds", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_states", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.integer "task_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["task_id"], name: "index_task_teams_on_task_id"
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
  end

  create_table "tasks", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "creator_id"
    t.integer "editor_id"
    t.integer "assignee_id"
    t.string "name"
    t.string "state", limit: 16
    t.string "difficulty", limit: 16
    t.boolean "full_nikkud", default: false
    t.integer "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "documents_count", default: 0
    t.integer "kind_id"
    t.string "priority"
    t.integer "hours"
    t.integer "genre"
    t.boolean "independent"
    t.boolean "include_images"
    t.string "source", limit: 2048
    t.integer "project_id"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["creator_id"], name: "index_tasks_on_creator_id"
    t.index ["editor_id"], name: "index_tasks_on_editor_id"
    t.index ["kind_id"], name: "index_tasks_on_kind_id"
    t.index ["parent_id"], name: "index_tasks_on_parent_id"
    t.index ["state"], name: "index_tasks_on_state"
  end

  create_table "team_memberships", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.integer "user_id"
    t.datetime "joined"
    t.datetime "left"
    t.integer "team_role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.boolean "open"
    t.text "description", size: :medium
    t.integer "status"
    t.date "targetdate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tmp_stats", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tasks_assigned"
    t.datetime "activated_at"
    t.integer "days_active"
    t.float "tasks_per_day"
  end

  create_table "translation_keys", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "key", limit: 1024, null: false, collation: "utf8mb3_bin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key"], name: "index_translation_keys_on_key", length: 255
  end

  create_table "translation_texts", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.text "text"
    t.string "locale", limit: 16
    t.integer "translation_key_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["translation_key_id", "locale"], name: "index_translation_texts_on_translation_key_id_and_locale", unique: true
  end

  create_table "users", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 48
    t.string "email", limit: 100, null: false
    t.string "crypted_password", limit: 128
    t.string "password_salt", limit: 20
    t.string "persistence_token", limit: 128
    t.string "single_access_token", limit: 20
    t.string "perishable_token", limit: 20
    t.integer "login_count"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.datetime "activated_at"
    t.string "current_login_ip", limit: 15
    t.string "last_login_ip", limit: 15
    t.boolean "is_admin"
    t.boolean "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_volunteer", default: false
    t.boolean "is_editor", default: false
    t.datetime "disabled_at"
    t.datetime "activation_email_sent_at"
    t.boolean "notify_on_comments", default: true
    t.boolean "notify_on_status", default: true
    t.datetime "task_requested_at"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer "volunteer_kind_id"
    t.boolean "on_break"
    t.date "last_reminder"
    t.string "zehut"
    t.index ["email"], name: "index_users_on_email"
    t.index ["perishable_token"], name: "index_users_on_perishable_token"
    t.index ["persistence_token"], name: "index_users_on_persistence_token"
    t.index ["single_access_token"], name: "index_users_on_single_access_token"
  end

  create_table "volunteer_kinds", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "volunteer_requests", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id"
    t.string "preferences", limit: 4096
    t.datetime "approved_at"
    t.integer "approver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_volunteer_requests_on_user_id"
  end

  add_foreign_key "audit_logs", "api_users"
  add_foreign_key "task_teams", "tasks"
  add_foreign_key "team_memberships", "users"
end
