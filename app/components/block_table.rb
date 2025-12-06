# frozen_string_literal: true

class BlockTable < ApplicationComponent
  def initialize(block:, highlight: nil)
    @block = block
    @highlight = highlight
    @unicode_characters_by_codepoint =
      UnicodeCharacter
      .where(codepoint: block.start_code..block.end_code)
      .index_by(&:codepoint)
  end

  def unicode_character_for(codepoint)
    @unicode_characters_by_codepoint.fetch(codepoint) do
      raise ActiveRecord::RecordNotFound, "codepoint #{codepoint} missing in block #{@block.name}"
    end
  end
end
