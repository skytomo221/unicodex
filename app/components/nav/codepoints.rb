# frozen_string_literal: true

module Nav
  class Codepoints < ApplicationComponent
    TEMPLATE_MAP = {
      linear: Nav::Templates::Linear
    }.freeze

    def initialize(unicode_character:, type: :linear)
      @unicode_character = unicode_character
      @type = type
    end

    def template_component
      TEMPLATE_MAP.fetch(@type)
    end

    def navigation
      @navigation ||= Navigation.new(@unicode_character)
    end

    class Navigation
      def initialize(entry)
        @entry = entry
      end

      def current
        @entry
      end

      def previous(distance)
        @entry.previous(distance)
      end

      def next(distance)
        @entry.next(distance)
      end

      def label
        "U+#{@entry.hex}"
      end

      def path_for(candidate)
        "/codepoint/#{candidate.hex}"
      end

      def card_for(candidate, type: nil)
        UnicodeCharacterCard.new(unicode_character: candidate, type: type)
      end
    end
  end
end
