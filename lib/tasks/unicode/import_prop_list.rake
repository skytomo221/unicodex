# frozen_string_literal: true

require "pathname"
require_relative "../../base_importer"
require_relative "../../unicode_importer"

namespace :unicode do
  desc "data/ucd.all.flat.xml の内容を unicode_characters テーブルへ取り込む"
  task import_prop_list: :environment do
    file_path = Rails.root.join("data", "UCD", "PropList.txt")
    batch_size = ENV.fetch("BATCH_SIZE", 500).to_i
    batch_size = 500 if batch_size <= 0

    limit = ENV["LIMIT"]
    limit = limit.present? ? limit.to_i : nil

    importer = PropListImporter.new(file_path: file_path, batch_size:, limit:)
    importer.call
  end
end

class PropListImporter < UnicodeImporter
  def initialize(file_path:, batch_size:, limit: nil)
    super(
      file_path:,
      batch_size:,
      limit:,
      model_class: PropListRecord,
      delete_before_import: true
    )
  end

  private

  def build_records(line, line_number)
    range, right = line.split(";", 2)
    property_name_raw, comment = right.split("#", 2)

    property_name = property_name_raw.strip
    comment = comment&.strip

    now = Time.current

    # --- Range parse ---
    case range.strip
    in /\A(?<start>[0-9A-Fa-f]{4,6})\.\.(?<end>[0-9A-Fa-f]{4,6})\z/
      start_cp = $~[:start].to_i(16)
      end_cp   = $~[:end].to_i(16)
    in /\A(?<cp>[0-9A-Fa-f]{4,6})\z/
      start_cp = end_cp = $~[:cp].to_i(16)
    else
      raise "Invalid code range format: #{range}"
    end

    (start_cp..end_cp).map do |cp|
      {
        unicode_character_id: unicode_character_id(cp),
        property_name:,
        raw_data: line,
        raw_data_line_number: line_number,
        created_at: now,
        updated_at: now
      }
    end
  end
end
