class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.belongs_to :game, index: true

      t.string :name
      t.string :avatar_type

      t.string :role
      t.string :state

      t.timestamps null: false
    end
  end
end
