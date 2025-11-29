# frozen_string_literal: true

require "pathname"
require_relative "../../base_importer"
require_relative "../../unicode_importer"

namespace :unicode do
  desc "data/ucd.all.flat.xml の内容を unicode_characters テーブルへ取り込む"
  task import_blocks: :environment do
    file_path = Rails.root.join("data", "UCD", "Blocks.txt")
    batch_size = ENV.fetch("BATCH_SIZE", 500).to_i
    batch_size = 500 if batch_size <= 0

    limit = ENV["LIMIT"]
    limit = limit.present? ? limit.to_i : nil

    importer = BlockImporter.new(file_path: file_path, batch_size:, limit:)
    importer.call
  end
end

class BlockImporter < UnicodeImporter
  def initialize(file_path:, batch_size:, limit: nil)
    super(
      file_path:,
      batch_size:,
      limit:,
      model_class: BlockRecord,
      delete_before_import: true
    )
  end

  private

  # Format:
  # Start Code..End Code; Block Name
  def build_records(line, line_number)
    range, name = line.split(";")

    now = Time.current

    case range
    in /\A(?<start>[0-9A-Fa-f]{4,6})\.\.(?<end>[0-9A-Fa-f]{4,6})\z/
      start_code = $~[:start].to_i(16)
      end_code   = $~[:end].to_i(16)
    else
      raise "Invalid code range format: #{range}"
    end

    [
      {
        start_code:,
        end_code:,
        name:,
        raw_data: line,
        raw_data_line_number: line_number,
        created_at: now,
        updated_at: now
      }
    ]
  end
end
