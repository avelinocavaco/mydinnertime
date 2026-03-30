# lib/ingredient_parser.rb
#
# Parses a raw ingredient string like:
#   "1 ½ cups all-purpose flour, sifted"
#   "2 cloves garlic, minced"
#   "1 avocado - peeled, pitted, and diced"
#   "1 (4 ounce) container crumbled Gorgonzola cheese"
#
# Returns { name: "all-purpose flour", preparation: <original string> }
#
module IngredientParser
  UNITS = %w[
    cup cups tablespoon tablespoons tbsp tbs
    teaspoon teaspoons tsp
    pound pounds lb lbs
    ounce ounces oz
    gram grams g kg
    clove cloves
    pinch pinches dash dashes
    can cans tin tins
    package packages pkg
    container containers
    spear spears link links
    slice slices piece pieces
    stick sticks head heads
    bunch bunches stalk stalks
    quart quarts pint pints
    gallon gallons liter liters litre litres ml
    fluid
  ].freeze

  UNIT_RE = /\A(#{UNITS.join('|')})\s+/i

  DESCRIPTORS = %w[
    fresh dried frozen cooked ground chopped minced
    shredded sliced diced cubed peeled grated crumbled
    melted softened warm cold hot large small medium
    or bottle mini additional and a original bag to
    your favorite
  ].freeze

  DESCRIPTOR_RE = /\b(#{DESCRIPTORS.join('|')})\s+/i

  def self.parse(raw)
    return { name: raw.downcase.strip, preparation: raw } if raw.blank?

    preparation = raw.strip
    name = raw.strip

    # 1. Remove all content inside parentheses
    #    "1 (4 ounce) container cheese" → "1  container cheese"
    #    "¼ cup warm water (110 degrees F)" → "¼ cup warm water"
    name = name.gsub(/\([^)]*\)/, "").strip

    # 2. Split on " - " (spaced hyphen = prep instruction separator)
    #    "1 avocado - peeled, pitted, and diced" → "1 avocado"
    #    Preserves compound names: "all-purpose flour", "old-fashioned oats"
    name = name.split(" - ").first.to_s.strip

    # 3. Split on first comma — discard prep instructions on the right
    #    "1 red bell pepper, cut into strips" → "1 red bell pepper"
    name = name.split(",").first.to_s.strip

    # 4. Remove everything that is not a letter, space, or hyphen
    #    Strips quantities, fractions (½ ⅔), symbols, numbers
    name = name.gsub(/[^a-zA-Z\s\-]/, "").strip

    # 5. Remove leading measurement unit
    #    "cup all-purpose flour" → "all-purpose flour"
    name = name.sub(UNIT_RE, "").strip

    # 6. Remove keywords
    name = name.gsub(DESCRIPTOR_RE, "").strip

    # 7. Downcase, normalise whitespace, clean up stray leading/trailing hyphens
    name = name.downcase.gsub(/\s+/, " ").strip.gsub(/\A-+|-+\z/, "").strip

    # Fallback: if we stripped everything, use the original lowercased
    name = raw.downcase.strip if name.blank?

    { name: name, preparation: preparation }
  end
end