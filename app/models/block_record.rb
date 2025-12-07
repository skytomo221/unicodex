class BlockRecord < ApplicationRecord
  def self.containing_codepoint(codepoint)
    find_by("start_code <= ? AND end_code >= ?", codepoint, codepoint)
  end
end
