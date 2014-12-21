class ChangeTypeToCategory < ActiveRecord::Migration
  def change
  	remove_column :memos, :type 
  	add_column :memos, :category, :string
  end
end
