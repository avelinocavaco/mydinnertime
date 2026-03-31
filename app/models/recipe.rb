class Recipe < ApplicationRecord
  SearchResult = Struct.new(:recipe, :matched_count, :total_count, :match_ratio, :ingredients, keyword_init: true)

  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true

  def self.rank_for_ingredients(names)
    selected_names = names.map { |name| name.to_s.downcase.strip }.reject(&:blank?).uniq
    return [] if selected_names.empty?

    matched_count_sql = sanitize_sql_array([
      "SUM(CASE WHEN ingredients.name IN (?) THEN 1 ELSE 0 END)",
      selected_names
    ])
    total_count_sql = "COUNT(recipe_ingredients.id)"
    match_ratio_sql = "(#{matched_count_sql})::float / #{total_count_sql}"

    recipes = joins(recipe_ingredients: :ingredient)
      .select(
        "recipes.*",
        "#{matched_count_sql} AS matched_count",
        "#{total_count_sql} AS total_count"
      )
      .group("recipes.id")
      .having("#{matched_count_sql} > 0")
      .order(
        Arel.sql("#{matched_count_sql} DESC"),
        Arel.sql("#{match_ratio_sql} DESC"),
        Arel.sql("COALESCE(recipes.ratings, 0) DESC")
      )
      .preload(recipe_ingredients: :ingredient)

    recipes.map do |recipe|
      ordered_ingredients = recipe.recipe_ingredients.sort_by(&:sequence)
      matched_count = recipe.read_attribute(:matched_count).to_i
      total_count = recipe.read_attribute(:total_count).to_i

      SearchResult.new(
        recipe: recipe,
        matched_count: matched_count,
        total_count: total_count,
        match_ratio: matched_count.to_f / total_count,
        ingredients: ordered_ingredients
      )
    end
  end
end
