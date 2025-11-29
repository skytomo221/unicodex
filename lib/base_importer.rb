# frozen_string_literal: true

class BaseImporter
  attr_reader :file_path, :batch_size, :limit, :processed, :inserted

  def initialize(file_path:, batch_size:, limit: nil, model_class:, delete_before_import: false)
    @file_path = file_path.is_a?(Pathname) ? file_path : Pathname.new(file_path)
    @batch_size = [ batch_size, 1 ].max
    @limit = limit&.positive? ? limit : nil
    @model_class = model_class
    @delete_before_import = delete_before_import

    @batch = []
    @inserted = 0
    @processed = 0
  end

  def call
    verify_source!
    before_import

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    open_source do |io|
      each_source_item(io) do |item, line_number|
        break unless handle_item(item, line_number)
      end
    end

    flush_batch

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    after_import(elapsed)
  end

  private

  # ===== テンプレートメソッド群 =====

  # デフォルトは1行ずつ読むテキストファイル
  # XML のときはサブクラスでオーバーライドして、char 要素ごとに yield する
  def each_source_item(io)
    io.each_line do |line|
      yield line
    end
  end

  # item → attributes Hash を返す
  # 返り値 nil の場合はスキップ扱い
  def build_record(_item, _line_number)
    raise NotImplementedError, "#{self.class.name}#build_record を実装してください"
  end

  def push_record(attrs)
    @batch << attrs
    flush_batch if @batch.size >= @batch_size
  end

  # コメント行かどうかを判定する
  def comment_line?(item, _line_number)
    item.strip.empty? || item.start_with?("#")
  end

  # モデルクラス（ActiveRecord::Base を想定）
  def model_class
    @model_class
  end

  # import 開始前に一度だけ呼ばれるフック
  def before_import
    if @delete_before_import
      model_class.delete_all
      puts "#{label} テーブル(#{model_class.table_name})を初期化しました"
    end
  end

  # import 終了後に一度だけ呼ばれるフック
  def after_import(elapsed)
    puts format("%<label>s: %<count>d 件を %<seconds>.2f 秒で取り込みました",
                label: label,
                count: @inserted,
                seconds: elapsed)
  end

  # ログ用の名前
  def label
    self.class.name
  end

  # ===== 共通ユーティリティ =====

  def open_source
    File.open(@file_path) do |io|
      yield io
    end
  end

  def handle_item(item, line_number)
    return false if @limit && @processed >= @limit

    @processed += 1

    return true if comment_line?(item, line_number)

    records = build_records(item, line_number)
    return true if records.empty?

    records.each do |attrs|
      push_record(attrs)
    end

    true
  end

  def flush_batch
    return if @batch.empty?

    model_class.insert_all!(@batch)
    @inserted += @batch.size
    @batch.clear
  end

  def verify_source!
    return if @file_path.exist?

    raise ArgumentError, "#{@file_path} が見つかりません"
  end

  # 汎用メソッド系（必要に応じてサブクラスから使う）

  def truncate(value, limit)
    return value if value.nil? || limit.nil?

    value[0, limit]
  end

  def blank_to_nil(value)
    value unless value.respond_to?(:blank?) ? value.blank? : (value.nil? || value == "")
  end
end
