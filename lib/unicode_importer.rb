# frozen_string_literal: true

class UnicodeImporter < BaseImporter
  def unicode_character_id(field)
    codepoint = field.is_a?(Integer) ? field : field.to_i(16)
    codepoint + 1
  end
end
