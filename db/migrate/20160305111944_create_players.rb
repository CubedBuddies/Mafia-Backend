class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.belongs_to :game, index: true

      t.string :name
      t.string :role
      t.string :avatar_type

      t.timestamps null: false
    end
  end
end
