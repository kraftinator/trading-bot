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

ActiveRecord::Schema.define(version: 20180125183158) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "coins", force: :cascade do |t|
    t.string "symbol"
  end

  create_table "limit_orders", force: :cascade do |t|
    t.integer  "trader_id"
    t.integer  "order_guid"
    t.decimal  "price",      precision: 15, scale: 8
    t.decimal  "qty",        precision: 16, scale: 8
    t.string   "side"
    t.boolean  "open"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "state"
    t.datetime "filled_at"
    t.decimal  "eth_price",  precision: 8,  scale: 2, default: "0.0"
  end

  create_table "partially_filled_orders", force: :cascade do |t|
    t.integer  "limit_order_id"
    t.decimal  "executed_qty",   precision: 16, scale: 8
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "strategies", force: :cascade do |t|
    t.string "name"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "symbol"
  end

  create_table "traders", force: :cascade do |t|
    t.integer  "trading_pair_id"
    t.decimal  "coin_qty",                                             default: "0.0"
    t.decimal  "{:precision=>16, :scale=>8}",                          default: "0.0"
    t.decimal  "token_qty",                                            default: "0.0"
    t.integer  "strategy_id"
    t.decimal  "percentage_range",                                     default: "0.05"
    t.decimal  "{:precision=>5, :scale=>4}",                           default: "0.05"
    t.integer  "wait_period",                                          default: 0
    t.boolean  "active",                                               default: false
    t.integer  "buy_count",                                            default: 0
    t.integer  "sell_count",                                           default: 0
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.decimal  "original_coin_qty",           precision: 16, scale: 8, default: "0.0"
    t.datetime "merged_at"
    t.integer  "merged_trader_id"
    t.decimal  "buy_pct",                     precision: 5,  scale: 4, default: "0.0"
    t.decimal  "sell_pct",                    precision: 5,  scale: 4, default: "0.0"
    t.decimal  "ceiling_pct",                 precision: 5,  scale: 4, default: "0.0"
    t.integer  "user_id"
    t.integer  "sell_count_trigger",                                   default: 0
  end

  create_table "trading_pairs", force: :cascade do |t|
    t.integer  "coin_id"
    t.integer  "token_id"
    t.decimal  "max_price",  precision: 15, scale: 8
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "precision",                           default: 8
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "first_name"
    t.boolean  "active",                 default: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
