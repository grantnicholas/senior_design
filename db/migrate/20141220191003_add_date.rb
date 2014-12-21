class AddDate < ActiveRecord::Migration
  def change
  	add_column :memos, :date, :string 
  end
end
