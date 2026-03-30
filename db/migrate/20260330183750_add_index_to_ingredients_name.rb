class AddIndexToIngredientsName < ActiveRecord::Migration[8.1]
  def change
    add_index :ingredients, :name
  end
end
