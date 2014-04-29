class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name
      t.integer :espn_id
      t.string :api_id
    end
  end
end
