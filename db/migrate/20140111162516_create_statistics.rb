class CreateStatistics < ActiveRecord::Migration
  def change
    create_table :statistics do |t|
      t.float :value
      t.integer :appearance_id
      t.integer :statistic_type_id      
    end
  end
end
