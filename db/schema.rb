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

ActiveRecord::Schema[8.0].define(version: 2025_11_27_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "block_records", force: :cascade do |t|
    t.integer "start_code"
    t.integer "end_code"
    t.string "name"
    t.string "raw_data"
    t.integer "raw_data_line_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "derived_name_records", force: :cascade do |t|
    t.bigint "unicode_character_id", null: false
    t.string "name"
    t.string "raw_data"
    t.integer "raw_data_line_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unicode_character_id"], name: "index_derived_name_records_on_unicode_character_id"
  end

  create_table "prop_list_records", force: :cascade do |t|
    t.bigint "unicode_character_id", null: false
    t.string "property_name"
    t.string "raw_data"
    t.integer "raw_data_line_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unicode_character_id"], name: "index_prop_list_records_on_unicode_character_id"
  end

  create_table "unicode_characters", force: :cascade do |t|
    t.integer "codepoint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["codepoint"], name: "index_unicode_characters_on_codepoint", unique: true
  end

  create_table "unicode_data_records", force: :cascade do |t|
    t.bigint "unicode_character_id", null: false
    t.string "name"
    t.string "general_category"
    t.integer "canonical_combining_class"
    t.string "bidi_class"
    t.string "decomposition_type"
    t.string "decomposition_mapping"
    t.integer "numeric_type"
    t.string "numeric_value"
    t.boolean "bidi_mirrored", default: false, null: false
    t.string "unicode_1_name"
    t.string "iso_comment"
    t.integer "simple_uppercase"
    t.integer "simple_lowercase"
    t.integer "simple_titlecase"
    t.string "raw_data"
    t.integer "raw_data_line_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unicode_character_id"], name: "index_unicode_data_records_on_unicode_character_id"
  end

  add_foreign_key "derived_name_records", "unicode_characters"
  add_foreign_key "prop_list_records", "unicode_characters"
  add_foreign_key "unicode_data_records", "unicode_characters"
end
