# frozen_string_literal: true

module Nav
  class Blocks < ApplicationComponent
    TEMPLATE_MAP = {
      linear: Nav::Templates::Linear
    }.freeze

    def initialize(block:, type: :linear)
      @block = block
      @type = type
    end

    def template_component
      TEMPLATE_MAP.fetch(@type)
    end

    def navigation
      @navigation ||= Navigation.new(@block)
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
        "U+#{@entry.start_code}..U+#{@entry.end_code}"
      end

      def path_for(candidate)
        "/block/#{candidate.normalized_name}"
      end

      def card_for(candidate, type: nil)
        BlockCard.new(block: candidate, type: type)
      end
    end
  end
end
