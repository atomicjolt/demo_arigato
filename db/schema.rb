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

ActiveRecord::Schema.define(version: 20141120233402) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: true do |t|
    t.string   "name"
    t.string   "domain"
    t.string   "lti_key"
    t.string   "lti_secret"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "canvas_api_key"
    t.string   "canvas_uri",     limit: 2048
    t.string   "code"
  end

  add_index "accounts", ["code"], name: "index_accounts_on_code", using: :btree
  add_index "accounts", ["domain"], name: "index_accounts_on_domain", unique: true, using: :btree

  create_table "authentications", force: true do |t|
    t.integer  "user_id"
    t.string   "token"
    t.string   "secret"
    t.string   "provider"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.text     "json_response"
    t.string   "uid"
    t.string   "provider_avatar"
    t.string   "username"
    t.string   "provider_url",    limit: 2048
    t.string   "refresh_token"
  end

  add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", using: :btree
  add_index "authentications", ["user_id"], name: "index_authentications_on_user_id", using: :btree

  create_table "canvas_loads", force: true do |t|
    t.integer  "user_id"
    t.string   "canvas_domain",  limit: 2048
    t.string   "suffix"
    t.string   "sis_id"
    t.boolean  "lti_attendance"
    t.boolean  "lti_chat"
    t.boolean  "course_welcome"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "canvas_loads", ["user_id"], name: "index_canvas_loads_on_user_id", using: :btree

  create_table "courses", force: true do |t|
    t.text     "content"
    t.integer  "canvas_load_id"
    t.integer  "canvas_course_id"
    t.integer  "canvas_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "courses", ["canvas_load_id"], name: "index_courses_on_canvas_load_id", using: :btree

  create_table "external_identifiers", force: true do |t|
    t.integer  "user_id"
    t.string   "identifier"
    t.string   "provider"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "custom_canvas_user_id"
  end

  add_index "external_identifiers", ["identifier", "provider"], name: "index_external_identifiers_on_identifier_and_provider", using: :btree
  add_index "external_identifiers", ["user_id"], name: "index_external_identifiers_on_user_id", using: :btree

  create_table "profiles", force: true do |t|
    t.integer  "user_id"
    t.string   "location"
    t.decimal  "lat",           precision: 15, scale: 10
    t.decimal  "lng",           precision: 15, scale: 10
    t.text     "about"
    t.string   "city"
    t.integer  "state_id"
    t.integer  "country_id"
    t.integer  "language_id"
    t.integer  "profile_views"
    t.text     "policy"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "website"
    t.string   "blog"
    t.string   "twitter"
    t.string   "facebook"
    t.string   "linkedin"
  end

  create_table "user_accounts", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_accounts", ["user_id", "account_id"], name: "index_user_accounts_on_user_id_and_account_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",        null: false
    t.string   "encrypted_password",     default: "",        null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,         null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "role"
    t.integer  "account_id"
    t.string   "username"
    t.string   "avatar"
    t.string   "time_zone",              default: "UTC"
    t.string   "password_salt"
    t.string   "lti_key"
    t.string   "lti_secret"
    t.string   "provider_avatar"
    t.string   "profile_privacy",        default: "private"
    t.string   "profile_privacy_token"
    t.string   "active_avatar",          default: "none"
  end

  add_index "users", ["account_id"], name: "index_users_on_account_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
