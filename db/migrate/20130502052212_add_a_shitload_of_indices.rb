class AddAShitloadOfIndices < ActiveRecord::Migration
  def change
    add_index :categories_products, :category_id
    add_index :categories_products, :product_id
    add_index :ratings, :product_id
    add_index :ratings, :user_id
    add_index :sales, :foreign_key
    add_index :sales, :group
    add_index :sales, :status
  end
end
