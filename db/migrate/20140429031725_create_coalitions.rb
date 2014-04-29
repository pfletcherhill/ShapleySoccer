class CreateCoalitions < ActiveRecord::Migration
  def change
    create_table :coalitions do |t|
      t.float :scored
      t.float :conceded
      t.float :minutes
    end
    
    create_join_table :coalitions, :players do |t|
      t.index :player_id
    end
    
    create_join_table :appearances, :coalitions do |t|
      t.index :appearance_id
    end
  end
end
