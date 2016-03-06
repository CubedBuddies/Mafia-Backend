# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  token      :string(255)
#  status     :string(255)
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class GamesController < ApplicationController
  def create
    @game = Game.create!
    @game.add_player(
      name: player_params[:name],
      avatar_type: player_params[:avatar_type]
    )
  end

  def show
    @game = Game.find_by(token: params[:id])
    @game.update_state!
  end

  def start
    @game = Game.find_by(token: params[:id])
    @game.start!
  end

  def add_player
    @game = Game.find_by(token: params[:id])
    @player = Player.create!(
      game_id: @game.id,
      name: player_params[:name],
      avatar_type: player_params[:avatar_type],
    )
  end

  def add_event
    @game = Game.find_by(token: params[:id])
    @game.add_event(
      name: event_params[:name],
      source_player_id: event_params[:source_player_id],
      target_player_id: event_params[:target_player_id],
    )
    @game.update_state!
  end

  private

  def player_params
    params.require(:player).permit(:name, :avatar_type)
  end

  def event_params
    params.require(:event).permit(:name, :source_player_id, :target_player_id)
  end
end
