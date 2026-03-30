class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :title
      t.float :ratings
      t.string :cuisine
      t.string :category
      t.string :author
      t.string :image_url
      t.integer :cook_time
      t.integer :prep_time

      t.timestamps
    end
  end
end
