# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

range_end = 0x10FFFF
puts "Seeding Unicode codepoints (0..#{range_end}) via PostgreSQL generate_series"
sql = <<~SQL
  INSERT INTO unicode_characters (codepoint, created_at, updated_at)
  SELECT cp, NOW(), NOW()
  FROM generate_series(0, #{range_end}) AS cp
  ON CONFLICT (codepoint) DO NOTHING;
SQL
ActiveRecord::Base.connection.execute(sql)
puts "Done."
