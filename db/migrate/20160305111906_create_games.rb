class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :token
      t.string :state
      t.string :winner

      t.text :data

      t.timestamps null: false
    end
  end
end
