# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_13_211158) do

  create_table "accounts", id: :string, force: :cascade do |t|
    t.string "user_id"
    t.string "sort_code"
    t.string "acc_number"
    t.string "account_id"
    t.integer "balance"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "savings"
    t.integer "threshold_offset"
  end

  create_table "conditions", id: :string, force: :cascade do |t|
    t.string "account_id"
    t.boolean "amount"
    t.string "condition"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pots", id: :string, force: :cascade do |t|
    t.string "account_id"
    t.string "pot_id"
    t.string "name"
    t.integer "current"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "display"
  end

  create_table "targets", id: :string, force: :cascade do |t|
    t.string "pot_id"
    t.integer "target"
    t.string "for"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transactions", id: :string, force: :cascade do |t|
    t.string "account_id"
    t.date "day"
    t.string "payee"
    t.integer "amount"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "transaction_id"
    t.boolean "pot_transfer"
    t.boolean "coin_jar"
    t.integer "balance"
    t.integer "coin_amount"
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.string "access_token"
    t.string "client_id"
    t.string "refresh_token"
    t.string "client_secret"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "username"
    t.string "cookie"
    t.string "password_digest"
  end

end
