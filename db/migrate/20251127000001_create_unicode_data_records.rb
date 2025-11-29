# frozen_string_literal: true

class CreateUnicodeDataRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :unicode_data_records do |t|
      t.references :unicode_character, null: false, foreign_key: true

      t.string :name
      t.string :general_category
      t.integer :canonical_combining_class
      t.string :bidi_class
      t.string :decomposition_type
      t.string :decomposition_mapping
      t.integer :numeric_type
      t.string :numeric_value
      t.boolean :bidi_mirrored, default: false, null: false
      t.string :unicode_1_name
      t.string :iso_comment
      t.integer :simple_uppercase
      t.integer :simple_lowercase
      t.integer :simple_titlecase

      t.string :raw_data
      t.integer :raw_data_line_number

      t.timestamps
    end
  end
end
