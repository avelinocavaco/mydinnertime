class HomeController < ApplicationController
  def index
    @ingredients = Array(params[:ingredients]).filter_map do |ingredient|
      normalized = ingredient.to_s.strip
      normalized if normalized.length >= 3
    end.uniq
  end
end
