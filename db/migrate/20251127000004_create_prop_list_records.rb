# frozen_string_literal: true

class CreatePropListRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :prop_list_records do |t|
      t.references :unicode_character, null: false, foreign_key: true

      t.string :property_name

      t.string :raw_data
      t.integer :raw_data_line_number

      t.timestamps
    end
  end
end
