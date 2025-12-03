# frozen_string_literal: true

require "pathname"
require_relative "../../base_importer"
require_relative "../../unicode_importer"

namespace :unicode do
  desc "data/ucd.all.flat.xml の内容を unicode_characters テーブルへ取り込む"
  task import_unicode_data: :environment do
    file_path = Rails.root.join("data", "UCD", "UnicodeData.txt")
    batch_size = ENV.fetch("BATCH_SIZE", 500).to_i
    batch_size = 500 if batch_size <= 0

    limit = ENV["LIMIT"]
    limit = limit.present? ? limit.to_i : nil

    importer = UnicodeDataImporter.new(file_path: file_path, batch_size:, limit:)
    importer.call
  end
end

class UnicodeDataImporter < UnicodeImporter
  def initialize(file_path:, batch_size:, limit: nil)
    super(
      file_path:,
      batch_size:,
      limit:,
      model_class: UnicodeDataRecord,
      delete_before_import: true
    )
  end

  private

  def build_records(line, line_number)
    fields = line.split(";")

    now = Time.current

    case fields[1]
    in /\A<(?<label>.+), First>\z/
      @pending_range = {
        label: label,
        start_cp: fields[0].to_i(16),
        fields: fields,
        raw_data: line,
        raw_data_line_number: line_number
      }
      []
    in /\A<(?<label>.+), Last>\z/
      unless @pending_range && @pending_range[:label] == label
        raise "UnicodeData First/Last mismatch: #{@pending_range&.inspect} vs #{fields[1]}"
      end
      start_cp = @pending_range[:start_cp]
      end_cp   = fields[0].to_i(16)
      base_fields = @pending_range[:fields]
      now = Time.current
      (start_cp..end_cp).map do |cp|
        copied = base_fields.dup
        copied[0] = cp.to_s(16).upcase
        {
          **build_record(copied),
          raw_data: @pending_range[:raw_data] + line,
          raw_data_line_number: line_number,
          created_at: now,
          updated_at: now
        }
      end
    else
      [
        {
          **build_record(fields),
          raw_data: line,
          raw_data_line_number: line_number,
          created_at: now,
          updated_at: now
        }
      ]
    end
  end

  def build_record(fields)
    {
      unicode_character_id: unicode_character_id(fields[0]),
      name: name(fields[1]),
      general_category: general_category(fields[2]),
      canonical_combining_class: canonical_combining_class(fields[3]),
      bidi_class: bidi_class(fields[4]),
      decomposition_type: decomposition_type(fields[5]),
      decomposition_mapping: decomposition_mapping(fields[5]),
      numeric_type: numeric_type(fields),
      numeric_value: numeric_value(fields),
      bidi_mirrored: bidi_mirrored(fields[9]),
      unicode_1_name: unicode_1_name(fields[10]),
      iso_comment: iso_comment(fields[11]),
      simple_uppercase: simple_uppercase(fields[12]),
      simple_lowercase: simple_lowercase(fields[13]),
      simple_titlecase: simple_titlecase(fields[14])
    }
  end

  # See: https://www.unicode.org/reports/tr44/#Name
  #
  # (1) When a string value not enclosed in <angle brackets> occurs in this
  # field, it specifies the character's Name property value, which matches
  # exactly the name published in the code charts. The Name property value for
  # most ideographic characters and for Hangul syllables is derived instead by
  # various rules. See Section 4.8, Name in [Unicode] for a full specification
  # of those rules. Strings enclosed in <angle brackets> in this field either
  # provide label information used in the name derivation rules, or—in the case
  # of characters which have a null string as their Name property value, such as
  # control characters—provide other information about their code point type.
  #
  # (1) このフィールドに<山括弧>で囲まれていない文字列値が現れた場合、それは文字
  # のNameプロパティ値を示し、これはコードチャートで公開されている名前と完全に一
  # 致する。ほとんどの表意文字とハングル音節のNameプロパティ値は、代わりに様々な
  # 規則によって導出される。これらの規則の完全な仕様については、[Unicode]のセク
  # ション4.8「Name」を参照のこと。このフィールドの<山括弧>で囲まれた文字列は、
  # 名前導出規則で使用されるラベル情報を提供するか、または制御文字のようにNameプ
  # ロパティ値がヌル文字列である文字の場合は、コードポイントの種類に関するその他
  # の情報を提供する。
  def name(field)
    field unless field.empty?
  end

  # See: https://www.unicode.org/reports/tr44/#General_Category
  #
  # (2) This is a useful breakdown into various character types which can be
  # used as a default categorization in implementations. For the property
  # values, see General Category Values.
  #
  # (2) これは、実装においてデフォルトの分類として使用できる、様々な文字種別への
  # 便利な分類です。プロパティ値については、「一般カテゴリ値」を参照してくださ
  # い。
  def general_category(field)
    field.presence || "Cn"
  end

  # See: https://www.unicode.org/reports/tr44/#Canonical_Combining_Class
  #
  # (3) The classes used for the Canonical Ordering Algorithm in the Unicode
  # Standard. This property could be considered either an enumerated property or
  # a numeric property: the principal use of the property is in terms of the
  # numeric values. For the property value names associated with different
  # numeric values, see DerivedCombiningClass.txt and Canonical Combining Class
  # Values.
  #
  # (3) Unicode標準の正規順序アルゴリズムで使用されるクラス。このプロパティは、
  # 列挙型プロパティまたは数値プロパティのいずれかと見なすことができます。このプ
  # ロパティの主な用途は数値です。異なる数値に関連付けられたプロパティ値名につい
  # ては、DerivedCombiningClass.txtおよび正規結合クラス値を参照してください。
  def canonical_combining_class(field)
    field.presence&.to_i || 0
  end

  # See: https://www.unicode.org/reports/tr44/#Bidi_Class
  #
  # (4) These are the categories required by the Unicode Bidirectional
  # Algorithm. For the property values, see Bidirectional Class Values. For more
  # information, see Unicode Standard Annex #9, "Unicode Bidirectional
  # Algorithm" [UAX9]. The default property values depend on the code point, and
  # are explained in DerivedBidiClass.txt
  #
  # (4) これらはUnicode双方向アルゴリズムで要求されるカテゴリです。プロパティ値
  # については、双方向クラス値を参照してください。詳細については、Unicode標準付
  # 録9「Unicode双方向アルゴリズム」[UAX9]を参照してください。デフォルトのプロパ
  # ティ値はコードポイントによって異なり、DerivedBidiClass.txtで説明されていま
  # す。
  def bidi_class(field)
    field
  end

  # See: https://www.unicode.org/reports/tr44/#Decomposition_Type
  #
  # (5) This field contains both values, with the type in angle brackets. The
  # decomposition mappings exactly match the decomposition mappings published
  # with the character names in the Unicode Standard. For more information, see
  # Character Decomposition Mappings.
  #
  # (5) このフィールドには両方の値が含まれており、型は山括弧で囲まれています。分
  # 解マッピングは、Unicode標準で文字名とともに公開されている分解マッピングと完
  # 全に一致しています。詳細については、「文字分解マッピング」を参照してくださ
  # い。
  def decomposition_type(field)
    field[/^<([^>]+)>$/, 1]
  end

  # See: https://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings
  def decomposition_mapping(field)
    field.sub(/^<[^>]+>\s*/, "").presence
  end

  # See: https://www.unicode.org/reports/tr44/#Numeric_Type
  #
  # (6) If the character has the property value Numeric_Type=Decimal, then the
  # Numeric_Value of that digit is represented with an integer value (limited to
  # the range 0..9) in fields 6, 7, and 8. Characters with the property value
  # Numeric_Type=Decimal are restricted to digits which can be used in a decimal
  # radix positional numeral system and which are encoded in the standard in a
  # contiguous ascending range 0..9. See the discussion of decimal digits in
  # Chapter 4, Character Properties in [Unicode].
  #
  # (7) If the character has the property value Numeric_Type=Digit, then the
  # Numeric_Value of that digit is represented with an integer value (limited to
  # the range 0..9) in fields 7 and 8, and field 6 is null. This covers digits
  # that need special handling, such as the compatibility superscript digits.
  # Starting with Unicode 6.3.0, no newly encoded numeric characters will be
  # given Numeric_Type=Digit, nor will existing characters with
  # Numeric_Type=Numeric be changed to Numeric_Type=Digit. The distinction
  # between those two types is not considered useful.
  #
  # (8) If the character has the property value Numeric_Type=Numeric, then the
  # Numeric_Value of that character is represented with a positive or negative
  # integer or rational number in this field, and fields 6 and 7 are null. This
  # includes fractions such as, for example, "1/5" for U+2155 VULGAR FRACTION
  # ONE FIFTH. Some characters have these properties based on values from the
  # Unihan data files. See Numeric_Type, Han.
  #
  # (6) 文字のプロパティ値が Numeric_Type=Decimal の場合、その数字の
  # Numeric_Value は、フィールド6、7、8 において整数値（0..9 の範囲に制限）で表
  # されます。プロパティ値が Numeric_Type=Decimal の文字は、10進基数位取り記数法
  # で使用できる数字に制限され、標準では連続した昇順の範囲 0..9 で符号化されま
  # す。[Unicode] の第4章「文字プロパティ」の 10進数字に関する説明を参照してくだ
  # さい。
  #
  # (7) 文字のプロパティ値がNumeric_Type=Digitの場合、その数字のNumeric_Valueは7
  # 番目と8番目のフィールドで整数値（0から9の範囲に制限）で表され、6番目のフィー
  # ルドはnullになります。これは、互換性上付き数字など、特別な処理を必要とする数
  # 字をカバーします。 Unicode 6.3.0以降、新たにエンコードされた数字には
  # Numeric_Type=Digitが付与されず、既存のNumeric_Type=Numericの文字も
  # Numeric_Type=Digitに変更されません。これら2つの型の区別は有用ではないと考え
  # られています。
  #
  # (8) 文字のプロパティ値が Numeric_Type=Numeric の場合、その文字の
  # Numeric_Value はこのフィールドで正または負の整数または有理数で表され、フィー
  # ルド6と7はNULLになります。これには分数も含まれます。例えば、U+2155 VULGAR
  # FRACTION ONE FIFTH を表す「1/5」などです。一部の文字は、Unihanデータファイル
  # の値に基づいてこれらのプロパティを持ちます。Numeric_Type、Hanを参照してくだ
  # さい。
  def numeric_type(fields)
    return :decimal if fields[6].present? && fields[7].present? && fields[8].present?
    return :digit   if fields[7].present? && fields[8].present?
    return :numeric if fields[8].present?
    nil
  end

  # See: https://www.unicode.org/reports/tr44/#Numeric_Value
  def numeric_value(fields)
    fields[8].presence
  end

  # See: https://www.unicode.org/reports/tr44/#Bidi_Mirrored
  #
  # (9) If the character is a "mirrored" character in bidirectional text, this
  # field has the value "Y"; otherwise "N". See Section 4.7, Bidi Mirrored of
  # [Unicode]. Do not confuse this with the Bidi_Mirroring_Glyph property.
  #
  # (9) 文字が双方向テキストにおいて「鏡像」文字である場合、このフィールドの値は
  # 「Y」、そうでない場合は「N」となります。[Unicode]のセクション4.7「Bidi
  # Mirrored」を参照してください。これをBidi_Mirroring_Glyphプロパティと混同しな
  # いでください。
  def bidi_mirrored(field)
    field == ?Y
  end

  # See: https://www.unicode.org/reports/tr44/#Unicode_1_Name
  #
  #	(10) Old name as published in Unicode 1.0 or ISO 6429 names for control
  #	functions. This field is empty unless it is significantly different from the
  #	current name for the character. No longer used in code chart production. See
  #	Name_Alias.
  #
  # (10) Unicode 1.0またはISO 6429で公開された制御機能の旧名称。このフィールド
  # は、文字の現在の名称と大きく異なる場合を除き、空欄のままです。コードチャート
  # の作成には使用されていません。Name_Aliasを参照してください。
  def unicode_1_name(field)
    field.presence
  end

  # See: https://www.unicode.org/reports/tr44/#ISO_Comment
  #
  # (11) ISO 10646 comment field. It was used for notes that appeared in
  # parentheses in the 10646 names list, or contained an asterisk to mark an
  # Annex P note. As of Unicode 5.2.0, this field no longer contains any
  # non-null values.
  #
  # (11) ISO 10646コメントフィールド。10646名称リストにおいて括弧内に記載された
  # 注記、または附属書Pの注記を示すアスタリスクを含む注記に使用されていた。
  # Unicode 5.2.0以降、このフィールドにはヌル以外の値は含まれなくなった。
  def iso_comment(field)
    field.presence
  end

  # See: https://www.unicode.org/reports/tr44/#Simple_Uppercase_Mapping
  #
  # (12) Simple uppercase mapping (single character result). If a character is
  # part of an alphabet with case distinctions, and has a simple uppercase
  # equivalent, then the uppercase equivalent is in this field. The simple
  # mappings have a single character result, where the full mappings may have
  # multi-character results. For more information, see Case and Case Mapping.
  #
  # (12) 単純な大文字マッピング（1文字の結果）。文字が大文字と小文字を区別するア
  # ルファベットの一部であり、単純な大文字の対応表がある場合、その大文字の対応表
  # がこのフィールドに入力されます。単純なマッピングでは1文字の結果になります
  # が、完全なマッピングでは複数文字の結果になる場合があります。詳細について
  # は、「大文字と小文字のマッピング」を参照してください。
  def simple_uppercase(field)
    field.presence&.to_i(16)
  end

  # See: https://www.unicode.org/reports/tr44/#Simple_Lowercase_Mapping
  #
  # (13) Simple lowercase mapping (single character result).
  #
  # （13）単純な小文字マッピング（単一文字の結果）。
  def simple_lowercase(field)
    field.presence&.to_i(16)
  end

  # See: https://www.unicode.org/reports/tr44/#Simple_Titlecase_Mapping
  #
  # (14) Simple titlecase mapping (single character result). Note: If this field
  # is null, then the Simple_Titlecase_Mapping is the same as the
  # Simple_Uppercase_Mapping for this character.
  #
  # (14) 単純なタイトルケースマッピング（単一文字の結果）。注: このフィールドが
  # nullの場合、この文字のSimple_Titlecase_MappingはSimple_Uppercase_Mappingと同
  # じになります。
  def simple_titlecase(field)
    field.presence&.to_i(16)
  end
end
