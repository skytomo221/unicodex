# frozen_string_literal: true

require "pathname"
require_relative "../../base_importer"
require_relative "../../unicode_importer"

namespace :unicode do
  desc "data/ucd.all.flat.xml の内容を unicode_characters テーブルへ取り込む"
  task import_derived_name: :environment do
    file_path = Rails.root.join("data", "UCD", "extracted", "DerivedName.txt")
    batch_size = ENV.fetch("BATCH_SIZE", 500).to_i
    batch_size = 500 if batch_size <= 0

    limit = ENV["LIMIT"]
    limit = limit.present? ? limit.to_i : nil

    importer = DerivedNameImporter.new(file_path: file_path, batch_size:, limit:)
    importer.call
  end
end

class DerivedNameImporter < UnicodeImporter
  def initialize(file_path:, batch_size:, limit: nil)
    super(
      file_path:,
      batch_size:,
      limit:,
      model_class: DerivedNameRecord,
      delete_before_import: true
    )
  end

  private

  # Format:
  # Start Code..End Code; Name
  def build_records(line, line_number)
    codepoint, name = line.split(";")
    codepoint = codepoint.to_s.strip
    name = name.to_s.strip

    now = Time.current
    expand_codepoints(codepoint).map do |cp|
      cp_hex = format("%04X", cp)
      {
        name: name.include?("*") ? name.gsub(/\*/, cp_hex) : name,
        unicode_character_id: unicode_character_id(cp),
        raw_data: line,
        raw_data_line_number: line_number,
        created_at: now,
        updated_at: now
      }
    end
  end

  def expand_codepoints(field)
    case field
    in /\A([0-9A-Fa-f]{4,6})\z/
      [ Regexp.last_match(1).to_i(16) ]
    in /\A(?<start>[0-9A-Fa-f]{4,6})\.\.(?<end>[0-9A-Fa-f]{4,6})\z/
      start_cp = Regexp.last_match(:start).to_i(16)
      end_cp = Regexp.last_match(:end).to_i(16)
      raise "Invalid code range format: #{field}" if end_cp < start_cp

      (start_cp..end_cp).to_a
    else
      raise "Invalid code range format: #{field}"
    end
  end
end
