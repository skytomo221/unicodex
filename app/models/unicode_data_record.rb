class UnicodeDataRecord < ApplicationRecord
  belongs_to :unicode_character

  enum :numeric_type, %i[decimal digit numeric]
end
