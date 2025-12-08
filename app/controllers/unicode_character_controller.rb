class UnicodeCharacterController < ApplicationController
  def show
    codepoint = params[:codepoint].to_s.upcase.to_i(16)
    @unicode_character = UnicodeCharacter.find_by!(codepoint:)
  end
end
