class UpdateDateFromString < ActiveRecord::Migration
  def change
  	remove_column :memos, :date
  	add_column :memos, :date, :datetime
  end
end
