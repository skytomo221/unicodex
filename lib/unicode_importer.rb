# frozen_string_literal: true

class UnicodeImporter < BaseImporter
  def unicode_character_id(field)
    codepoint = field.is_a?(Integer) ? field : field.to_i(16)
    UnicodeCharacter.find_by!(codepoint: codepoint).id
  end
end
