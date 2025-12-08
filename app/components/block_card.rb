# frozen_string_literal: true

class BlockCard < ApplicationComponent
  def initialize(block:, type: :normal)
    @unicode_character = UnicodeCharacter.find_by(codepoint: block.start_code)
    @type = type
  end
end
