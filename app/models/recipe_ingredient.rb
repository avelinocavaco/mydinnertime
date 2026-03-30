class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :preparation, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
