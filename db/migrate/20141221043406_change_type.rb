class ChangeType < ActiveRecord::Migration
  def change
  	remove_column :machines, :type
  	add_column :machines, :category, :string
  end
end
