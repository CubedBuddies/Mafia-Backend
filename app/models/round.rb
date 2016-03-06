class Round
  include ActiveModel::Model

  attr_accessor :votes
  attr_accessor :kills
  attr_accessor :players
  attr_accessor :created_at
  attr_accessor :expires_at

  def initialize(players)
    self.players = players
    self.votes = {}
    self.kills = {}

    self.created_at = Time.current
    self.expires_at = self.created_at + 5.minutes
  end

  def add_event(event)
    unless players.include?(event.source_player_id)
      raise Game::InvalidActionError, 'Source player #{event.source_player_id} is no longer part of the game'
    end

    unless players.include?(event.target_player_id)
      raise Game::InvalidActionError, 'Target player #{event.target_player_id} is no longer part of the game'
    end

    case event.name
    when 'kill'
      unless event.source_player.role == 'mafia'
        raise Game::InvalidActionError, 'Source player #{event.source_player_id} cannot perform this action'
      end

      self.kills[event.source_player_id] = event.target_player_id
    when 'vote'
      self.votes[event.source_player_id] = event.target_player_id
    else
      raise Game::InvalidActionError, 'Event name does not exist'
    end
  end

  def player_to_lynch

  end

  def player_to_kill

  end
end