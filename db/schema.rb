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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20151025205716) do

  create_table "assignment_histories", :force => true do |t|
    t.integer  "user_id"
    t.integer  "task_id"
    t.string   "role",       :limit => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assignment_histories", ["user_id"], :name => "index_assignment_histories_on_user_id"

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.integer  "action"
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "task_id"
    t.text     "changed_attrs"
    t.boolean  "hidden",         :default => false
  end

  add_index "audits", ["task_id"], :name => "index_audits_on_task_id"

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "task_id"
    t.string   "message",              :limit => 4096
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "editor_eyes_only",                     :default => false
    t.boolean  "is_rejection_reason",                  :default => false
    t.boolean  "is_abandoning_reason",                 :default => false
    t.boolean  "is_finished_reason"
  end

  add_index "comments", ["task_id", "created_at", "editor_eyes_only"], :name => "task_created_eyes"

  create_table "custom_properties", :force => true do |t|
    t.integer  "property_id"
    t.integer  "proprietary_id"
    t.string   "proprietary_type", :limit => 32
    t.string   "custom_value",     :limit => 8192
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custom_properties", ["proprietary_id", "proprietary_type"], :name => "proprietary"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "user_id"
    t.integer  "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "done"
  end

  create_table "global_preferences", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "ttl"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "global_preferences", ["name"], :name => "index_global_preferences_on_name", :unique => true

  create_table "properties", :force => true do |t|
    t.string   "title"
    t.string   "parent_type",   :limit => 32
    t.string   "property_type", :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_public",                   :default => true
    t.string   "comment"
  end

  create_table "search_settings", :force => true do |t|
    t.integer  "user_id"
    t.string   "search_key"
    t.string   "search_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_settings", ["user_id", "search_key"], :name => "index_search_settings_on_user_id_and_search_key"

  create_table "sessions", :force => true do |t|
    t.string   "session_id",                     :null => false
    t.text     "data",       :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "site_notices", :force => true do |t|
    t.datetime "start_displaying_at"
    t.datetime "end_displaying_at"
    t.string   "html",                :limit => 8192
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_notices", ["start_displaying_at", "end_displaying_at"], :name => "index_site_notices_on_start_displaying_at_and_end_displaying_at"

  create_table "task_kinds", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_states", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "editor_id"
    t.integer  "assignee_id"
    t.string   "name"
    t.string   "state",           :limit => 16
    t.string   "difficulty",      :limit => 16
    t.boolean  "full_nikkud",                   :default => false
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "documents_count",               :default => 0
    t.integer  "kind_id"
    t.string   "priority"
  end

  create_table "tmp_stats", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "tasks_assigned"
    t.datetime "activated_at"
    t.integer  "days_active"
    t.float    "tasks_per_day"
  end

  create_table "translation_keys", :force => true do |t|
    t.string   "key",        :limit => 1024, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "translation_keys", ["key"], :name => "index_translation_keys_on_key", :length => {"key"=>255}

  create_table "translation_texts", :force => true do |t|
    t.text     "text"
    t.string   "locale",             :limit => 16
    t.integer  "translation_key_id",               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "translation_texts", ["translation_key_id", "locale"], :name => "index_translation_texts_on_translation_key_id_and_locale", :unique => true

  create_table "users", :force => true do |t|
    t.string   "name",                     :limit => 48
    t.string   "email",                    :limit => 100,                    :null => false
    t.string   "crypted_password",         :limit => 128
    t.string   "password_salt",            :limit => 20
    t.string   "persistence_token",        :limit => 128
    t.string   "single_access_token",      :limit => 20
    t.string   "perishable_token",         :limit => 20
    t.integer  "login_count"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.datetime "activated_at"
    t.string   "current_login_ip",         :limit => 15
    t.string   "last_login_ip",            :limit => 15
    t.boolean  "is_admin"
    t.boolean  "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_volunteer",                            :default => false
    t.boolean  "is_editor",                               :default => false
    t.datetime "disabled_at"
    t.datetime "activation_email_sent_at"
    t.boolean  "notify_on_comments",                      :default => true
    t.boolean  "notify_on_status",                        :default => true
    t.datetime "task_requested_at"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "volunteer_kind_id"
    t.boolean  "on_break"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["single_access_token"], :name => "index_users_on_single_access_token"

  create_table "volunteer_kinds", :force => true do |t|
    t.string   "name",       :limit => 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "volunteer_requests", :force => true do |t|
    t.integer  "user_id"
    t.string   "preferences", :limit => 4096
    t.datetime "approved_at"
    t.integer  "approver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "volunteer_requests", ["user_id"], :name => "index_volunteer_requests_on_user_id"

end
