# frozen_string_literal: true

class UnicodeCharacterCard < ApplicationComponent
  def initialize(unicode_character:, type: :normal)
    @unicode_character = unicode_character
    @type = type
  end
end
