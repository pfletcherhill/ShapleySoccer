class CreateGoals < ActiveRecord::Migration
  def change
    create_table :goals do |t|
      t.integer :appearance_id
      t.float :time
    end
  end
end
