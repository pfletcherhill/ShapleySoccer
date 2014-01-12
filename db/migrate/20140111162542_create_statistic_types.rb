class CreateStatisticTypes < ActiveRecord::Migration
  def change
    create_table :statistic_types do |t|
      t.string :abbrev
      t.string :name
      t.text :description
    end
  end
end
