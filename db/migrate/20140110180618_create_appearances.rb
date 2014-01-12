class CreateAppearances < ActiveRecord::Migration
  def change
    create_table :appearances do |t|
      t.integer :game_id
      t.integer :player_id
      t.integer :team_id
      t.float :time_on
      t.float :time_off
    end
  end
end
