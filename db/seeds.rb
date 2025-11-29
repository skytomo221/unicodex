# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

batch_size = 200

range = 0..0x10FFFF

puts "Seeding Unicode codepoints (#{range.begin}..#{range.end}) with batch_size=#{batch_size}"
now = Time.current
buffer = []
range.each do |cp|
  buffer << { codepoint: cp, created_at: now, updated_at: now }

  if buffer.size >= batch_size
    UnicodeCharacter.upsert_all(
      buffer,
      unique_by: :index_unicode_characters_on_codepoint
    )
    buffer.clear
  end
end
UnicodeCharacter.upsert_all(
  buffer,
  unique_by: :index_unicode_characters_on_codepoint
) if buffer.any?
puts "Done."
