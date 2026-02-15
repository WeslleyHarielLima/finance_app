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

ActiveRecord::Schema[8.1].define(version: 2026_02_15_203337) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "credit_card_charges", force: :cascade do |t|
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.decimal "installment_amount", null: false
    t.integer "installments", default: 1, null: false
    t.boolean "recurring", default: false
    t.date "start_date", null: false
    t.decimal "total_amount", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_credit_card_charges_on_category_id"
    t.index ["user_id", "start_date"], name: "index_credit_card_charges_on_user_id_and_start_date"
    t.index ["user_id"], name: "index_credit_card_charges_on_user_id"
  end

  create_table "financial_entries", force: :cascade do |t|
    t.decimal "amount"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.string "entry_type"
    t.boolean "recurring", default: false
    t.integer "recurring_day"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_financial_entries_on_category_id"
    t.index ["user_id", "date"], name: "index_financial_entries_on_user_id_and_date"
    t.index ["user_id", "entry_type", "date"], name: "index_financial_entries_on_user_id_and_entry_type_and_date"
    t.index ["user_id", "entry_type"], name: "index_financial_entries_on_user_id_and_entry_type"
    t.index ["user_id"], name: "index_financial_entries_on_user_id"
  end

  create_table "monthly_budgets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "month"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "month"], name: "index_monthly_budgets_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_monthly_budgets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "currency"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.decimal "monthly_income"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "timezone"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "categories", "users"
  add_foreign_key "credit_card_charges", "categories"
  add_foreign_key "credit_card_charges", "users"
  add_foreign_key "financial_entries", "categories"
  add_foreign_key "financial_entries", "users"
  add_foreign_key "monthly_budgets", "users"
end
