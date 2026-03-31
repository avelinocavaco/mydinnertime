# lib/tasks/import_recipes.rake
#
# Usage:
#   rails import:recipes                          # imports from default path
#   rails import:recipes FILE=path/to/file.json   # custom path
#   rails import:recipes FILE=... LIMIT=100        # import first N recipes (for testing)
#
require_relative "../ingredient_parser"
require "cgi"
require "uri"

namespace :import do
  desc "Import recipes from a JSON file into the database"
  task recipes: :environment do
    extract_image_url = lambda do |raw_image|
      image = raw_image.to_s.strip
      next if image.blank?

      begin
        uri = URI.parse(image)
        nested_url = CGI.parse(uri.query.to_s)["url"]&.first
        nested_url.present? ? nested_url : image
      rescue URI::InvalidURIError
        image
      end
    end

    file_path = ENV.fetch("FILE", Rails.root.join("db/seeds/recipes-en.json"))
    limit     = ENV["LIMIT"]&.to_i

    abort "File not found: #{file_path}" unless File.exist?(file_path)

    puts "→ Loading #{file_path}..."
    raw = JSON.parse(File.read(file_path))
    raw = raw.first(limit) if limit

    puts "→ Found #{raw.size} recipes. Starting import...\n\n"

    stats = { recipes: 0, ingredients: 0, skipped: 0, errors: [] }

    # Cache ingredients to avoid repeated DB lookups
    ingredient_cache = {}

    ActiveRecord::Base.transaction do
      raw.each_with_index do |data, idx|
        title = data["title"].to_s.strip
        if title.blank?
          stats[:skipped] += 1
          next
        end

        # Skip duplicate titles
        if Recipe.exists?(title: title)
          stats[:skipped] += 1
          next
        end

        recipe = Recipe.create!(
          title:      title,
          cook_time:  data["cook_time"].presence,
          prep_time:  data["prep_time"].presence,
          ratings:    data["ratings"].presence,
          cuisine:    data["cuisine"].presence,
          category:   data["category"].presence,
          author:     data["author"].presence,
          image_url:  extract_image_url.call(data["image"])
        )

        ingredients = Array(data["ingredients"]).compact.reject(&:blank?)

        ingredients.each_with_index do |raw_ingredient, seq|
          parsed = IngredientParser.parse(raw_ingredient)

          # Find or create ingredient, using cache to avoid N+1 queries
          ingredient = ingredient_cache[parsed[:name]] ||= Ingredient.find_or_create_by!(name: parsed[:name])

          RecipeIngredient.create!(
            recipe:      recipe,
            ingredient:  ingredient,
            preparation: parsed[:preparation],
            sequence:    seq + 1
          )

          stats[:ingredients] += 1
        end

        stats[:recipes] += 1

        # Progress indicator every 500 recipes
        if (idx + 1) % 500 == 0
          puts "  #{idx + 1}/#{raw.size} recipes imported..."
        end

      rescue ActiveRecord::RecordInvalid => e
        stats[:errors] << "Recipe ##{idx + 1} '#{title}': #{e.message}"
        next
      end
    end

    puts "\n✅ Import complete!"
    puts "   Recipes imported:  #{stats[:recipes]}"
    puts "   Ingredient lines:  #{stats[:ingredients]}"
    puts "   Unique ingredients:#{Ingredient.count}"
    puts "   Skipped:           #{stats[:skipped]}"

    if stats[:errors].any?
      puts "\n⚠️  #{stats[:errors].size} error(s):"
      stats[:errors].first(10).each { |e| puts "   #{e}" }
    end
  end
end
