class HomeController < ApplicationController
  def index
    raw_ingredients = Array(params[:ingredients])
    raw_selected = Array(params[:ingredient_selected])
    seen = {}

    @ingredients = raw_ingredients.each_with_index.filter_map do |ingredient, index|
      name = ingredient.to_s.strip
      next if name.length < 3

      normalized = name.downcase
      next if seen[normalized]

      seen[normalized] = true

      {
        name: name,
        selected: raw_selected[index] != "false"
      }
    end

    @selected_ingredient_names = @ingredients.filter_map { |ingredient| ingredient[:name].downcase if ingredient[:selected] }
    @recipes = Recipe.rank_for_ingredients(@selected_ingredient_names)
  end
end
