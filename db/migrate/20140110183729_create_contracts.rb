class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.integer :player_id
      t.integer :seller_id
      t.integer :team_id
      t.float :transfer_amount
      t.float :wage
      t.integer :type
      t.date :start_date
      t.date :end_date
    end
  end
end
