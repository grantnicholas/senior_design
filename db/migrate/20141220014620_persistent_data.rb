class PersistentData < ActiveRecord::Migration

  def up
  	create_table :memos do |t|
  		t.column :type,  :string
  		t.column :count, :integer
  		t.column :time,  :float
  		t.timestamps
  	end
  end
 
  def down
  	drop_table :memos
  end

end
