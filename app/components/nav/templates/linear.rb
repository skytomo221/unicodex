# frozen_string_literal: true

module Nav
  module Templates
    class Linear < ApplicationComponent
      def initialize(navigation:)
        @navigation = navigation
      end
    end
  end
end
