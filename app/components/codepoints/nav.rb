# frozen_string_literal: true

module Codepoints
  class Nav < ApplicationComponent
    def initialize(unicode_character:)
      @unicode_character = unicode_character
    end
  end
end
