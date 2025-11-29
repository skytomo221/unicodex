# frozen_string_literal: true

namespace :unicode do
  desc "data の内容をデータベースへ取り込む"
  task import_all: %i[environment import_unicode_data import_blocks import_derived_name]
end
