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

class Game < ActiveRecord::Base
  extend Enumerize

  MIN_PLAYERS_FOR_GAME = 5

  NIGHT_ROUND_LENGTH = 30.seconds
  DAY_ROUND_LENGTH = 45.seconds

  store :data, accessors: [:rounds], coder: JSON

  has_many :events
  has_many :players

  before_validation :set_default_values

  validates :state, presence: true
  validates :token, presence: true

  enumerize :state, in: [
    :initializing,
    :in_progress,
    :finished,
  ]

  enumerize :winner, in: [
    :mafia,
    :townsperson,
  ]

  class InvalidActionError < StandardError; end

  def start!
    ActiveRecord::Base.transaction do
      unless self.state == 'initializing'
        raise InvalidActionError, "Game is not initializing.  Can't start a non-initializing game."
      end

      num_players = self.players.count

      if num_players < MIN_PLAYERS_FOR_GAME
        raise InvalidActionError, "Game has too few players.  Mafia requires #{MIN_PLAYERS_FOR_GAME} players to start and this game currently has #{num_players}."
      end

      num_mafia = (num_players ** 0.5).floor
      num_townsperson = num_players - num_mafia

      # TODO: remove this, rigging for demo
      if num_players == 6
        roles = ['mafia', 'townsperson', 'townsperson', 'townsperson', 'mafia', 'townsperson']
      else
        roles = (['townsperson'] * num_townsperson) + (['mafia'] * num_mafia)
        roles.shuffle!
      end

      self.players.zip(roles).each do |player, role|
        player.update!(
          role: role,
          state: 'alive',
        )
      end

      self.state = 'in_progress'
      create_new_round

      save!
    end
  end

  def update_state!
    return unless self.state == 'in_progress'
    return if Time.current < current_round['expires_at'].to_time

    if current_round['lynch_votes'].present?
      # TODO: Make this select a random person
      lynched_player_id = current_round['lynch_votes'].
        group_by(&:last).
        max_by { |source_player_id, votes_player_ids| votes_player_ids.count }.
        first

      current_round['lynched_player_id'] = lynched_player_id
      self.players.find(lynched_player_id).update(state: 'dead')
    end

    if current_round['kill_votes'].present?
      killed_player_id = current_round['kill_votes'].
        group_by(&:last).
        max_by { |source_player_id, votes_player_ids| votes_player_ids.count }.
        first

      current_round['killed_player_id'] = killed_player_id
      self.players.find(killed_player_id).update(state: 'dead')
    end

    num_mafia_remaining = self.players.where(role: 'mafia', state: 'alive').count
    num_players_remaining = self.players.where(role: 'townsperson', state: 'alive').count

    if num_mafia_remaining == 0
      self.state = 'finished'
      self.winner = 'townsperson'
      save!
      return
    end

    if num_players_remaining == num_mafia_remaining
      self.state = 'finished'
      self.winner = 'mafia'
      save!
      return
    end

    create_new_round
    save!
  end

  def add_player(name:, avatar: nil)
    unless self.state == 'initializing'
      raise InvalidActionError, "Game is not initializing.  Can't add player to a non-initializing game."
    end

    Player.create!(
      game: self,
      name: name,
      avatar: avatar,
    )
  end

  def remove_player(id:)
    unless self.state == 'initializing'
      raise InvalidActionError, "Game is not initializing.  Can't remove player from a non-initializing game."
    end

    self.players.find(id).destroy!
  end

  def add_event(name:, source_player_id:, target_player_id:)
    return unless self.state == 'in_progress'

    source_player = Player.find(source_player_id)
    target_player = Player.find(target_player_id)

    unless source_player.state == 'alive' && target_player.state == 'alive'
      raise InvalidActionError, "Either source player #{source_player_id} or target player #{target_player_id} is not alive"
    end

    # TODO: Fix this
    case name
    when 'kill'
      unless source_player.role == 'mafia'
        raise InvalidActionError, 'Source player #{source_player_id} cannot perform `kill` action'
      end

      current_round['kill_votes'][source_player_id] = target_player_id
    when 'lynch'
      current_round['lynch_votes'][source_player_id] = target_player_id
    else
      raise InvalidActionError, 'Event name does not exist'
    end

    save!

    Event.create!(
      game: self,
      name: name,
      source_player: source_player,
      target_player: target_player,
    )
  end

  def current_round
    self.rounds[-1]
  end

  def previous_round
    self.rounds[-2]
  end

  private

  def create_new_round
    # This will also force the first round to be 'night' since current_round will be nil
    if current_round&.fetch('type', 'DAY') == 'DAY'
      create_night_round
    else
      create_day_round
    end
  end

  def create_day_round
    self.rounds << {
      'player_ids'        => self.players.where(state: 'alive').pluck(:id),
      'type'              => 'DAY',
      'lynch_votes'       => {},
      'lynched_player_id' => nil,
      'kill_votes'        => {},
      'killed_player_id'  => nil,
      'created_at'        => (Time.current).to_json,
      'expires_at'        => (Time.current + DAY_ROUND_LENGTH).to_json,
    }
  end

  def create_night_round
    self.rounds << {
      'player_ids'        => self.players.where(state: 'alive').pluck(:id),
      'type'              => 'NIGHT',
      'lynch_votes'       => {},
      'lynched_player_id' => nil,
      'kill_votes'        => {},
      'killed_player_id'  => nil,
      'created_at'        => (Time.current).to_json,
      'expires_at'        => (Time.current + NIGHT_ROUND_LENGTH).to_json,
    }
  end

  def set_default_values
    self.state ||= 'initializing'
    self.token ||= SecureRandom.hex[0...6]
    self.rounds ||= []
  end
end
