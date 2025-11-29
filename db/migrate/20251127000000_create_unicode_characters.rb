# frozen_string_literal: true

class CreateUnicodeCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :unicode_characters do |t|
      t.integer :codepoint, null: false

      t.timestamps
    end

    add_index :unicode_characters, :codepoint, unique: true
  end
end
