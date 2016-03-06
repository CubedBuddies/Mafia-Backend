class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.belongs_to :game, index: true
      t.belongs_to :source_player_id, index: true
      t.belongs_to :target_player_id, index: true

      t.string :name
      t.timestamps null: false
    end
  end
end
