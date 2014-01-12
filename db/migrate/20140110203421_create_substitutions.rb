class CreateSubstitutions < ActiveRecord::Migration
  def change
    create_table :substitutions do |t|
      t.float :time
      t.integer :player_in_id
      t.integer :player_out_id
      t.integer :game_id
      t.integer :team_id 
    end
  end
end
