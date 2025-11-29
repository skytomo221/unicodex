# frozen_string_literal: true

class CreateDerivedNameRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :derived_name_records do |t|
      t.references :unicode_character, null: false, foreign_key: true

      t.string :name

      t.string :raw_data
      t.integer :raw_data_line_number

      t.timestamps
    end
  end
end
