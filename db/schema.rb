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

ActiveRecord::Schema.define(version: 20160812212340) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "applications", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "address"
    t.string   "phone"
    t.string   "emergency_contact_name"
    t.string   "emergency_contact_phone"
    t.text     "wahnam_courses"
    t.text     "martial_arts_experience"
    t.text     "health_issues"
    t.text     "bio"
    t.text     "why_shaolin"
    t.boolean  "ten_shaolin_laws"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applications", ["user_id"], name: "index_applications_on_user_id", using: :btree

  create_table "contract_plans", force: :cascade do |t|
    t.string   "title",                      null: false
    t.integer  "total",                      null: false
    t.integer  "deposit",                    null: false
    t.integer  "payment_amount", default: 0
    t.string   "stripe_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "contract_plans", ["stripe_id"], name: "index_contract_plans_on_stripe_id", using: :btree

  create_table "contracts", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.string   "title",                      null: false
    t.string   "status",                     null: false
    t.datetime "start_date",                 null: false
    t.datetime "end_date",                   null: false
    t.integer  "total",                      null: false
    t.integer  "balance",                    null: false
    t.integer  "payment_amount", default: 0
    t.string   "stripe_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "contracts", ["user_id", "status"], name: "index_contracts_on_user_id_and_status", using: :btree

  create_table "course_contract_plans", force: :cascade do |t|
    t.integer "course_id",        null: false
    t.integer "contract_plan_id", null: false
  end

  add_index "course_contract_plans", ["contract_plan_id"], name: "index_course_contract_plans_on_contract_plan_id", using: :btree
  add_index "course_contract_plans", ["course_id"], name: "index_course_contract_plans_on_course_id", using: :btree

  create_table "courses", force: :cascade do |t|
    t.string   "title",                  null: false
    t.text     "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "first_installment_date"
    t.integer  "base_price"
    t.integer  "event_id"
    t.string   "schedule_desc"
  end

  add_index "courses", ["event_id"], name: "index_courses_on_event_id", using: :btree

  create_table "event_discounts", force: :cascade do |t|
    t.integer "event_id"
    t.string  "description"
    t.string  "course_list"
    t.integer "price"
  end

  add_index "event_discounts", ["event_id"], name: "index_event_discounts_on_event_id", using: :btree

  create_table "event_registrations", force: :cascade do |t|
    t.integer "event_id"
    t.integer "user_id"
    t.integer "amount_paid"
    t.string  "stripe_id"
  end

  add_index "event_registrations", ["event_id"], name: "index_event_registrations_on_event_id", using: :btree
  add_index "event_registrations", ["user_id"], name: "index_event_registrations_on_user_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "title",       null: false
    t.text     "description"
    t.string   "location"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "user_id",   null: false
    t.integer "course_id", null: false
  end

  add_index "registrations", ["course_id"], name: "index_registrations_on_course_id", using: :btree
  add_index "registrations", ["user_id"], name: "index_registrations_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                                           null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "activation_state"
    t.string   "activation_token"
    t.datetime "activation_token_expires_at"
    t.boolean  "admin",                           default: false
    t.string   "name"
    t.string   "stripe_id"
    t.string   "hometown"
  end

  add_index "users", ["activation_token"], name: "index_users_on_activation_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree
  add_index "users", ["stripe_id"], name: "index_users_on_stripe_id", using: :btree

  add_foreign_key "courses", "events"
  add_foreign_key "event_discounts", "events"
  add_foreign_key "event_registrations", "events"
  add_foreign_key "event_registrations", "users"
end
