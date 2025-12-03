class PropListRecord < ApplicationRecord
  belongs_to :unicode_character

  validates :property_name, presence: true
end
