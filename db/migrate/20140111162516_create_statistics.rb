class CreateStatistics < ActiveRecord::Migration
  def change
    create_table :statistics do |t|
      t.float :value
      t.integer :appearance_id
      t.string :stat_type      
    end
  end
end
