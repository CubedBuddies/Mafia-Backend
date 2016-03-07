# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  token      :string(255)
#  state      :string(255)
#  winner     :string(255)
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class GamesController < ApplicationController
  before_action :set_default_format

  rescue_from Game::InvalidActionError do |error|
    render json: {message: error.message}, status: :bad_request
  end

  def create
    @game = Game.create!

    render 'show', status: :created
  end

  def show
    @game = Game.find_by(token: params[:token])
    @game.update_state!

    render 'show', status: :ok
  end

  def start
    @game = Game.find_by(token: params[:token])
    @game.start!

    render 'show', status: :ok
  end

  def add_player
    @game = Game.find_by(token: params[:token])
    @game.add_player(
      name: player_params[:name],
      avatar_type: player_params[:avatar_type],
    )

    render 'show', status: :ok
  end

  def add_event
    @game = Game.find_by(token: params[:token])
    @game.update_state!
    @game.add_event(
      name: event_params[:name],
      source_player_id: event_params[:source_player_id],
      target_player_id: event_params[:target_player_id],
    )

    render 'show', status: :ok
  end

  private

  def set_default_format
    request.format = 'json'
  end

  def player_params
    params.require(:player).permit(:name, :avatar_type)
  end

  def event_params
    params.require(:event).permit(:name, :source_player_id, :target_player_id)
  end
end
