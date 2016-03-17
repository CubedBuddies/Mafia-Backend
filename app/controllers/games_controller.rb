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

    unless Rails.env.test?
      @game.add_player(name: "Test Player 1")
      @game.add_player(name: "Test Player 2")
      @game.add_player(name: "Test Player 3")
      @game.add_player(name: "Test Player 4")
    end

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
    name = player_params[:name]
    if player_params[:avatar_file_data] && player_params[:avatar_file_name]
      avatar = Paperclip.io_adapters.for("data:image/png;base64,#{player_params[:avatar_file_data]}")
      avatar.original_filename = player_params[:avatar_file_name]
    end

    @game = Game.find_by(token: params[:token])
    @player = @game.add_player(
      name: name,
      avatar: avatar,
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
    params.require(:player).permit(:name, :avatar_file_name, :avatar_file_data)
  end

  def event_params
    params.require(:event).permit(:name, :source_player_id, :target_player_id)
  end

  # This part is actually taken from http://blag.7tonlnu.pl/blog/2014/01/22/uploading-images-to-a-rails-app-via-json-api. I tweaked it a bit by manually setting the tempfile's content type because somehow putting it in a hash during initialization didn't work for me.
  def parse_image_data(image_data)
    @tempfile = Tempfile.new('item_image')
    @tempfile.binmode
    @tempfile.write Base64.decode64(image_data[:content])
    @tempfile.rewind

    uploaded_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: @tempfile,
      filename: image_data[:filename]
    )

    uploaded_file.content_type = image_data[:content_type]
    uploaded_file
  end

  def clean_tempfile
    if @tempfile
      @tempfile.close
      @tempfile.unlink
    end
  end
end
