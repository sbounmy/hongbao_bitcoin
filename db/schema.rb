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

ActiveRecord::Schema[8.0].define(version: 2025_07_12_032000) do
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

  create_table "ai_elements", force: :cascade do |t|
    t.string "leonardo_id"
    t.string "title"
    t.string "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.datetime "leonardo_created_at"
    t.datetime "leonardo_updated_at"
    t.index ["leonardo_id"], name: "index_ai_elements_on_leonardo_id", unique: true
  end

  create_table "ai_elements_themes", id: false, force: :cascade do |t|
    t.integer "theme_id", null: false
    t.integer "element_id", null: false
    t.index ["element_id", "theme_id"], name: "index_ai_elements_themes_on_element_id_and_theme_id"
    t.index ["theme_id", "element_id"], name: "index_ai_elements_themes_on_theme_id_and_element_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "text"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_ai_messages_on_type"
  end

  create_table "ai_tasks", force: :cascade do |t|
    t.string "external_id"
    t.string "status"
    t.integer "user_id", null: false
    t.string "type", null: false
    t.string "prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "request"
    t.json "response"
    t.string "source_type"
    t.integer "source_id"
    t.index ["source_type", "source_id"], name: "index_ai_tasks_on_source"
    t.index ["type", "external_id"], name: "index_ai_tasks_on_type_and_external_id"
    t.index ["user_id"], name: "index_ai_tasks_on_user_id"
  end

  create_table "ai_themes", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "path"
    t.json "ui", default: "{}"
  end

  create_table "bundles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bundles_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "model_id"
    t.integer "user_id"
    t.integer "bundle_id"
    t.json "input_item_ids", default: "[]"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id"], name: "index_chats_on_bundle_id"
    t.index ["user_id", "bundle_id"], name: "index_chats_on_user_id_and_bundle_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
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
    t.index ["position"], name: "index_inputs_on_position"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.string "role"
    t.text "content"
    t.string "model_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "metadata", default: "{}"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "papers", force: :cascade do |t|
    t.string "name"
    t.integer "ai_style_id", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "elements"
    t.integer "user_id"
    t.boolean "public", default: false
    t.integer "parent_id"
    t.integer "ai_theme_id"
    t.integer "bundle_id"
    t.json "input_item_ids", default: []
    t.integer "message_id"
    t.json "input_ids", default: [], null: false
    t.index ["ai_theme_id"], name: "index_papers_on_ai_theme_id"
    t.index ["bundle_id"], name: "index_papers_on_bundle_id"
    t.index ["message_id"], name: "index_papers_on_message_id"
    t.index ["parent_id"], name: "index_papers_on_parent_id"
    t.index ["user_id"], name: "index_papers_on_user_id"
    t.check_constraint "JSON_TYPE(input_ids) = 'array'", name: "paper_input_ids_is_array"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name", null: false
    t.text "instructions"
    t.boolean "active", default: true
    t.json "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order"
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

  create_table "tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "quantity", null: false
    t.string "description"
    t.json "metadata", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["created_at"], name: "index_tokens_on_created_at"
    t.index ["external_id"], name: "index_tokens_on_external_id"
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
  add_foreign_key "ai_tasks", "users"
  add_foreign_key "bundles", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "input_items", "bundles"
  add_foreign_key "input_items", "inputs"
  add_foreign_key "messages", "chats"
  add_foreign_key "papers", "ai_themes"
  add_foreign_key "papers", "bundles"
  add_foreign_key "papers", "messages"
  add_foreign_key "papers", "papers", column: "parent_id"
  add_foreign_key "papers", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tokens", "users"
end
