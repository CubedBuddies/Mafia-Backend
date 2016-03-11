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

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: {message: error.message}, status: :bad_request
  end

  def create
    @game = Game.create!

    # TODO: remove this in future
    @game.add_player(name: "Test Player 1", avatar_type: "Blank")
    @game.add_player(name: "Test Player 2", avatar_type: "Blank")
    @game.add_player(name: "Test Player 3", avatar_type: "Blank")

    render template: 'games/show', status: :created
  end

  def show
    @game = Game.find_by(token: params[:token])
    @game.update_state!

    render template: 'games/show', status: :ok
  end

  def start
    @game = Game.find_by(token: params[:token])
    @game.start!

    render template: 'games/show', status: :ok
  end

  def add_player
    @game = Game.find_by(token: params[:token])
    @player = @game.add_player(
      name: player_params[:name],
      avatar_type: player_params[:avatar_type],
    )

    render template: 'players/show', status: :ok
  end

  def remove_player
    @game = Game.find_by(token: params[:token])
    @game.remove_player(id: params[:player_id])

    render template: 'games/show', status: :ok
  end

  def add_event
    @game = Game.find_by(token: params[:token])
    @game.update_state!

    @event = @game.add_event(
      name: event_params[:name],
      source_player_id: event_params[:source_player_id],
      target_player_id: event_params[:target_player_id],
    )

    render template: 'games/show', status: :ok
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
