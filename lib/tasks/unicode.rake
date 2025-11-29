# frozen_string_literal: true

require "pathname"
require "rexml/parsers/pullparser"

namespace :unicode do
  desc "data/ucd.all.flat.xml の内容を unicode_characters テーブルへ取り込む"
  task import: :environment do
    file_path = Rails.root.join("data", "ucd.all.flat.xml")
    batch_size = ENV.fetch("BATCH_SIZE", 500).to_i
    batch_size = 500 if batch_size <= 0

    limit = ENV["LIMIT"]
    limit = limit.present? ? limit.to_i : nil

    importer = Unicode::UcdImporter.new(file_path: file_path, batch_size:, limit:)
    importer.call
  end
end

module Unicode
  class UcdImporter
    NUMERIC_TYPE_CODES = {
      "De" => 0,
      "Decimal" => 0,
      "Di" => 1,
      "Digit" => 1,
      "Nu" => 2,
      "Numeric" => 2
    }.freeze

    def initialize(file_path:, batch_size:, limit: nil)
      @file_path = file_path.is_a?(Pathname) ? file_path : Pathname.new(file_path)
      @batch_size = [ batch_size, 1 ].max
      @limit = limit&.positive? ? limit : nil
      @batch = []
      @inserted = 0
      @processed = 0
    end

    def call
      verify_source!
      UnicodeCharacter.delete_all
      puts "unicode_characters テーブルを初期化しました"
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      File.open(@file_path) do |io|
        parser = REXML::Parsers::PullParser.new(io)

        while parser.has_next?
          event = parser.pull
          next unless event.start_element? && event[0] == "char"

          break unless handle_char(event[1])
        end
      end

      flush_batch
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      puts format("%<count>d 件を %<seconds>.2f 秒で取り込みました", count: @inserted, seconds: elapsed)
    end

    private

    def handle_char(attrs)
      return false if @limit && @processed >= @limit

      @processed += 1
      @batch << build_record(attrs)
      flush_batch if @batch.size >= @batch_size
      true
    end

    def flush_batch
      return if @batch.empty?

      UnicodeCharacter.insert_all!(@batch)
      @inserted += @batch.size
      @batch.clear
    end

    def verify_source!
      return if @file_path.exist?

      raise ArgumentError, "#{@file_path} が見つかりません"
    end

    def build_record(attrs)
      now = Time.current

      {
        codepoint: hex_to_int(attrs["cp"]),
        name: blank_to_nil(attrs["na"]),
        general_category: attrs["gc"],
        canonical_combining_class: attrs["ccc"].to_i,
        bidi_class: attrs["bc"],
        decomposition_type: attrs["dt"],
        decomposition_mapping: placeholder_to_nil(attrs["dm"]),
        numeric_type: numeric_type_value(attrs["nt"]),
        numeric_value: numeric_value_string(attrs["nv"]),
        bidi_mirrored: attrs["Bidi_M"],
        unicode_1_name: blank_to_nil(attrs["na1"]),
        iso_comment: blank_to_nil(attrs["JSN"]),
        simple_uppercase: hex_to_int(attrs["suc"]),
        simple_lowercase: hex_to_int(attrs["slc"]),
        simple_titlecase: hex_to_int(attrs["stc"]),
        raw_ucd_all_flat_xml: raw_fragment(attrs),
        raw_unicode_data: nil,
        created_at: now,
        updated_at: now
      }
    end

    def numeric_type_value(value)
      NUMERIC_TYPE_CODES[value]
    end

    def numeric_value_string(value)
      return if value.blank? || value == "NaN"

      value
    end

    def raw_fragment(attrs)
      raw = +"<char"
      attrs.each do |key, val|
        raw << %( #{key}="#{val}")
      end
      raw << ">"
      truncate(raw, raw_ucd_limit)
    end

    def raw_ucd_limit
      @raw_ucd_limit ||= UnicodeCharacter.columns_hash["raw_ucd_all_flat_xml"]&.limit
    end

    def hex_to_int(value)
      return if value.blank? || value == "#"

      value.to_i(16)
    end

    def placeholder_to_nil(value)
      value unless value.blank? || value == "#"
    end

    def blank_to_nil(value)
      value unless value.blank?
    end

    def truncate(value, limit)
      return value if value.nil? || limit.nil?

      value[0, limit]
    end
  end
end
