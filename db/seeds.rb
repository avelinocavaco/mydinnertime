# db/seeds.rb
# The main dataset is imported via: rails import:recipes
#
# This file runs a quick seed of 200 recipes so `rails db:seed`
# gives you something to work with immediately.
#
# For the full dataset:
#   rails import:recipes FILE=db/seeds/recipes-en.json
#
puts "Seeding 200 sample recipes from JSON..."

RecipeIngredient.delete_all
Recipe.delete_all
Ingredient.delete_all

require Rails.root.join("lib/ingredient_parser")

json_path = Rails.root.join("db/seeds/recipes-en.json")
raw = JSON.parse(File.read(json_path)).first(200)
ingredient_cache = {}

raw.each do |data|
  recipe = Recipe.create!(
    title:     data["title"],
    cook_time: data["cook_time"],
    prep_time: data["prep_time"],
    ratings:   data["ratings"],
    cuisine:   data["cuisine"].presence,
    category:  data["category"].presence,
    author:    data["author"].presence,
    image_url: data["image"].presence
  )

  Array(data["ingredients"]).compact.each_with_index do |raw_ing, seq|
    parsed     = IngredientParser.parse(raw_ing)
    ingredient = ingredient_cache[parsed[:name]] ||= Ingredient.find_or_create_by!(name: parsed[:name])
    RecipeIngredient.create!(
      recipe:      recipe,
      ingredient:  ingredient,
      preparation: parsed[:preparation],
      sequence:    seq + 1
    )
  end
end

puts "✅ Seeded #{Recipe.count} recipes, #{Ingredient.count} unique ingredients"
puts ""
puts "To import the full dataset:"
puts "  rails import:recipes FILE=db/seeds/recipes-en.json"
