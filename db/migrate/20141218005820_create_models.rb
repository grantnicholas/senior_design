class CreateModels < ActiveRecord::Migration
  def up
  	create_table :machines do |t|
      t.string :type 
  		t.column :time,  :float
  		t.column :xdata, :float
  		t.column :ydata, :float
  		t.column :zdata, :float
  	end
  end
 
  def down
  	drop_table :machines
  end
end