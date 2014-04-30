class AddValuesToPlayers < ActiveRecord::Migration
  def change
    change_table :players do |t|
      t.float :value
    end
  end
end
