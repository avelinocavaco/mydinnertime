class Recipe < ApplicationRecord
  SearchResult = Struct.new(:recipe, :matched_count, :total_count, :match_ratio, :ingredients, keyword_init: true)

  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true

  def self.rank_for_ingredients(names)
    selected_names = names.map { |name| name.to_s.downcase.strip }.reject(&:blank?).uniq
    return [] if selected_names.empty?

    total_count_sql = "(SELECT COUNT(*) FROM recipe_ingredients ri WHERE ri.recipe_id = recipes.id)"
    match_ratio_sql = "COUNT(DISTINCT ingredients.id)::float / NULLIF(#{total_count_sql}, 0)"

    ranking_rows = joins(recipe_ingredients: :ingredient)
      .where(ingredients: { name: selected_names })
      .group("recipes.id", "recipes.ratings")
      .select(
        "recipes.id",
        "COUNT(DISTINCT ingredients.id) AS matched_count",
        "#{total_count_sql} AS total_count"
      )
      .order(
        Arel.sql("COUNT(DISTINCT ingredients.id) DESC"),
        Arel.sql("#{match_ratio_sql} DESC"),
        Arel.sql("COALESCE(recipes.ratings, 0) DESC")
      )
      .limit(100)

    recipes_by_id = where(id: ranking_rows.map(&:id))
      .preload(recipe_ingredients: :ingredient)
      .index_by(&:id)

    ranking_rows.filter_map do |row|
      recipe = recipes_by_id[row.id]
      next unless recipe

      ordered_ingredients = recipe.recipe_ingredients.sort_by(&:sequence)
      matched_count = row.read_attribute(:matched_count).to_i
      total_count = row.read_attribute(:total_count).to_i

      SearchResult.new(
        recipe: recipe,
        matched_count: matched_count,
        total_count: total_count,
        match_ratio: total_count > 0 ? matched_count.to_f / total_count : 0.0,
        ingredients: ordered_ingredients
      )
    end
  end
end
