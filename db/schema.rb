# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200721135352) do

  create_table "assignment_histories", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "task_id",    limit: 4
    t.string   "role",       limit: 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assignment_histories", ["user_id"], name: "index_assignment_histories_on_user_id", using: :btree

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id",   limit: 4
    t.string   "auditable_type", limit: 255
    t.integer  "user_id",        limit: 4
    t.integer  "action",         limit: 4
    t.text     "note",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "task_id",        limit: 4
    t.text     "changed_attrs",  limit: 65535
    t.boolean  "hidden",                       default: false
  end

  add_index "audits", ["task_id"], name: "index_audits_on_task_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.integer  "task_id",              limit: 4
    t.string   "message",              limit: 4096
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "editor_eyes_only",                  default: false
    t.boolean  "is_rejection_reason",               default: false
    t.boolean  "is_abandoning_reason",              default: false
    t.boolean  "is_finished_reason"
  end

  add_index "comments", ["task_id", "created_at", "editor_eyes_only"], name: "task_created_eyes", using: :btree

  create_table "custom_properties", force: :cascade do |t|
    t.integer  "property_id",      limit: 4
    t.integer  "proprietary_id",   limit: 4
    t.string   "proprietary_type", limit: 32
    t.string   "custom_value",     limit: 8192
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custom_properties", ["proprietary_id", "proprietary_type"], name: "proprietary", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", force: :cascade do |t|
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
    t.integer  "user_id",           limit: 4
    t.integer  "task_id",           limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "done"
  end

  add_index "documents", ["task_id"], name: "index_documents_on_task_id", using: :btree

  create_table "global_preferences", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "value",      limit: 255
    t.integer  "ttl",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "global_preferences", ["name"], name: "index_global_preferences_on_name", unique: true, using: :btree

  create_table "properties", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.string   "parent_type",   limit: 32
    t.string   "property_type", limit: 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_public",                 default: true
    t.string   "comment",       limit: 255
  end

  create_table "search_settings", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.string   "search_key",   limit: 255
    t.string   "search_value", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_settings", ["user_id", "search_key"], name: "index_search_settings_on_user_id_and_search_key", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,      null: false
    t.text     "data",       limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "site_notices", force: :cascade do |t|
    t.datetime "start_displaying_at"
    t.datetime "end_displaying_at"
    t.string   "html",                limit: 8192
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_notices", ["start_displaying_at", "end_displaying_at"], name: "index_site_notices_on_start_displaying_at_and_end_displaying_at", using: :btree

  create_table "task_kinds", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_states", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "value",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer  "creator_id",      limit: 4
    t.integer  "editor_id",       limit: 4
    t.integer  "assignee_id",     limit: 4
    t.string   "name",            limit: 255
    t.string   "state",           limit: 16
    t.string   "difficulty",      limit: 16
    t.boolean  "full_nikkud",                 default: false
    t.integer  "parent_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "documents_count", limit: 4,   default: 0
    t.integer  "kind_id",         limit: 4
    t.string   "priority",        limit: 255
    t.integer  "hours",           limit: 4
  end

  add_index "tasks", ["assignee_id"], name: "index_tasks_on_assignee_id", using: :btree
  add_index "tasks", ["editor_id"], name: "index_tasks_on_editor_id", using: :btree
  add_index "tasks", ["kind_id"], name: "index_tasks_on_kind_id", using: :btree
  add_index "tasks", ["state"], name: "index_tasks_on_state", using: :btree

  create_table "tmp_stats", id: false, force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "tasks_assigned", limit: 4
    t.datetime "activated_at"
    t.integer  "days_active",    limit: 4
    t.float    "tasks_per_day",  limit: 24
  end

  create_table "translation_keys", force: :cascade do |t|
    t.string   "key",        limit: 1024, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "translation_keys", ["key"], name: "index_translation_keys_on_key", length: {"key"=>255}, using: :btree

  create_table "translation_texts", force: :cascade do |t|
    t.text     "text",               limit: 65535
    t.string   "locale",             limit: 16
    t.integer  "translation_key_id", limit: 4,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "translation_texts", ["translation_key_id", "locale"], name: "index_translation_texts_on_translation_key_id_and_locale", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                     limit: 48
    t.string   "email",                    limit: 100,                 null: false
    t.string   "crypted_password",         limit: 128
    t.string   "password_salt",            limit: 20
    t.string   "persistence_token",        limit: 128
    t.string   "single_access_token",      limit: 20
    t.string   "perishable_token",         limit: 20
    t.integer  "login_count",              limit: 4
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.datetime "activated_at"
    t.string   "current_login_ip",         limit: 15
    t.string   "last_login_ip",            limit: 15
    t.boolean  "is_admin"
    t.boolean  "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_volunteer",                         default: false
    t.boolean  "is_editor",                            default: false
    t.datetime "disabled_at"
    t.datetime "activation_email_sent_at"
    t.boolean  "notify_on_comments",                   default: true
    t.boolean  "notify_on_status",                     default: true
    t.datetime "task_requested_at"
    t.string   "avatar_file_name",         limit: 255
    t.string   "avatar_content_type",      limit: 255
    t.integer  "avatar_file_size",         limit: 4
    t.datetime "avatar_updated_at"
    t.integer  "volunteer_kind_id",        limit: 4
    t.boolean  "on_break"
    t.date     "last_reminder"
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["perishable_token"], name: "index_users_on_perishable_token", using: :btree
  add_index "users", ["persistence_token"], name: "index_users_on_persistence_token", using: :btree
  add_index "users", ["single_access_token"], name: "index_users_on_single_access_token", using: :btree

  create_table "volunteer_kinds", force: :cascade do |t|
    t.string   "name",       limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "volunteer_requests", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "preferences", limit: 4096
    t.datetime "approved_at"
    t.integer  "approver_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "volunteer_requests", ["user_id"], name: "index_volunteer_requests_on_user_id", using: :btree

end
