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

ActiveRecord::Schema[8.0].define(version: 2024_11_14_102248) do
  create_table "hong_baos", force: :cascade do |t|
    t.decimal "amount"
    t.decimal "btc_amount"
    t.decimal "platform_fee"
    t.decimal "gas_fee"
    t.string "private_key"
    t.decimal "total_cost"
    t.text "personal_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
