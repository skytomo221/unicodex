# frozen_string_literal: true

class CreateBlockRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :block_records do |t|
      t.integer :start_code
      t.integer :end_code
      t.string :name

      t.string :raw_data
      t.integer :raw_data_line_number

      t.timestamps
    end
  end
end
