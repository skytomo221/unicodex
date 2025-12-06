# frozen_string_literal: true

class Glyph < ApplicationComponent
  def initialize(glyph:, font:)
    @glyph = glyph
    @font = font
  end
end
