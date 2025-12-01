class UnicodeCharacter < ApplicationRecord
  has_one :unicode_data_record, dependent: :destroy
  has_one :derived_name_record, dependent: :destroy

  def hex
    format("%04X", codepoint)
  end

  def glyph
    [ codepoint ].pack("U")
  rescue RangeError
    ?�
  end

  def common_name
    unicode_data_record&.name || unicode_data_record&.unicode_1_name || derived_name_record&.name || "<no name>"
  end

  def general_category
    unicode_data_record&.general_category
  end

  def block
    BlockRecord.containing_codepoint(codepoint)&.name
  end

  def previous(index = 1)
    UnicodeCharacter.find_by(codepoint: codepoint - index)
  end

  def next(index = 1)
    UnicodeCharacter.find_by(codepoint: codepoint + index)
  end
end
