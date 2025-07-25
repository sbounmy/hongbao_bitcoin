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

ActiveRecord::Schema[8.0].define(version: 2025_07_21_104341) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bundles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bundles_on_user_id"
  end

  create_table "identities", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider_name"
    t.string "provider_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "input_items", force: :cascade do |t|
    t.integer "input_id", null: false
    t.integer "bundle_id", null: false
    t.string "prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id"], name: "index_input_items_on_bundle_id"
    t.index ["input_id"], name: "index_input_items_on_input_id"
  end

  create_table "inputs", force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.string "prompt"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "metadata", default: "{}"
    t.integer "position", default: 0
    t.json "tag_ids", default: []
    t.index ["position"], name: "index_inputs_on_position"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "quantity", null: false
    t.decimal "price", null: false
    t.string "stripe_price_id"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_line_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id"
    t.string "payment_provider", null: false
    t.decimal "total_amount", null: false
    t.string "currency", null: false
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shipping_name"
    t.string "shipping_address_line1"
    t.string "shipping_address_line2"
    t.string "shipping_city"
    t.string "shipping_state"
    t.string "shipping_postal_code"
    t.string "shipping_country"
    t.string "state"
    t.string "redirect_ref"
    t.index ["external_id"], name: "index_orders_on_external_id", unique: true
    t.index ["redirect_ref"], name: "index_orders_on_redirect_ref"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "papers", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "elements"
    t.integer "user_id"
    t.boolean "public", default: false
    t.integer "bundle_id"
    t.json "input_ids", default: [], null: false
    t.json "input_item_ids", default: []
    t.json "metadata", default: "{}"
    t.integer "views_count", default: 0, null: false
    t.integer "likes_count", default: 0, null: false
    t.json "liker_ids", default: []
    t.index ["bundle_id"], name: "index_papers_on_bundle_id"
    t.index ["likes_count"], name: "index_papers_on_likes_count"
    t.index ["user_id"], name: "index_papers_on_user_id"
    t.index ["views_count"], name: "index_papers_on_views_count"
    t.check_constraint "JSON_TYPE(input_ids) = 'array'", name: "paper_input_ids_is_array"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name", null: false
    t.text "instructions"
    t.boolean "active", default: true
    t.json "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.boolean "no_kyc", default: true
    t.index ["name"], name: "index_payment_methods_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.integer "position"
    t.json "metadata", default: {}
    t.json "categories", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "quantity", null: false
    t.string "description"
    t.json "metadata", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.integer "order_id"
    t.index ["created_at"], name: "index_tokens_on_created_at"
    t.index ["external_id"], name: "index_tokens_on_external_id"
    t.index ["order_id"], name: "index_tokens_on_order_id"
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "transaction_fees", force: :cascade do |t|
    t.date "date", null: false
    t.json "priorities", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_transaction_fees_on_date", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "magic_link_token"
    t.datetime "magic_link_expires_at"
    t.integer "tokens_sum", default: 0, null: false
    t.string "stripe_customer_id"
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bundles", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "input_items", "bundles"
  add_foreign_key "input_items", "inputs"
  add_foreign_key "line_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "papers", "bundles"
  add_foreign_key "papers", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tokens", "orders"
  add_foreign_key "tokens", "users"
end
