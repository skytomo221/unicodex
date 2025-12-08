class BlockRecord < ApplicationRecord
  def self.containing_codepoint(codepoint)
    find_by("start_code <= ? AND end_code >= ?", codepoint, codepoint)
  end

  def normalized_name
    name.strip.downcase.gsub(/[^a-z0-9]+/, "_")
  end

  def previous(index = 1)
    BlockRecord.find_by(id: id - index)
  end

  def next(index = 1)
    BlockRecord.find_by(id: id + index)
  end
end
