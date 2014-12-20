class AddTimestamp < ActiveRecord::Migration
  def up
  	add_column :machines, :date, :string 
  end

  def down
  	remove_column :machines, :date
  end
end
