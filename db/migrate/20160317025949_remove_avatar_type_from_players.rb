class RemoveAvatarTypeFromPlayers < ActiveRecord::Migration
  def change
    remove_column :players, :avatar_type
  end
end
