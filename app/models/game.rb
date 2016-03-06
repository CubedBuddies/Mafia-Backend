# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  token      :string(255)
#  state     :string(255)
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Game < ActiveRecord::Base
  extend Enumerize

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
      num_mafia = (num_players ** 0.5).floor
      num_townsperson = num_players - num_mafia

      roles = (['townsperson'] * num_townsperson) + (['mafia'] * num_mafia)
      roles.shuffle!

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
    return if Time.current < current_round['expires_at']

    if current_round['votes'].present?
      player_to_lynch_id = current_round['votes'].
        group_by(&:last).
        max_by { |source_player_id, votes_player_ids| votes_player_ids.count }.
        first

      self.players.find(player_to_lynch_id).update(state: 'dead')
    end

    if current_round['kills'].present?
      player_to_kill_id = current_round['kills'].
        group_by(&:last).
        max_by { |source_player_id, votes_player_ids| votes_player_ids.count }.
        first

      self.players.find(player_to_kill_id).update(state: 'dead')
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

  def add_player(name:, avatar_type:)
    unless self.state == 'initializing'
      raise InvalidActionError, "Game is not initializing.  Can't add player to non-initializing game."
    end

    Player.create!(
      game: self,
      name: name,
      avatar_type: avatar_type,
    )
  end

  def add_event(name:, source_player_id:, target_player_id:)
    unless self.state == 'in_progress'
      raise InvalidActionError, "Game is not in progress.  Can't add event to a game that is not in progress"
    end

    source_player = Player.find(source_player_id)
    target_player = Player.find(target_player_id)

    unless source_player.state == 'alive' && target_player.state == 'alive'
      raise InvalidActionError, "Either source player #{source_player_id} or target player #{target_player_id} is not alive"
    end

    case name
    when 'kill'
      unless source_player.role == 'mafia'
        raise InvalidActionError, 'Source player #{source_player_id} cannot perform `kill` action'
      end

      current_round['kills'][source_player_id] = target_player_id
    when 'vote'
      current_round['votes'][source_player_id] = target_player_id
    else
      raise InvalidActionError, 'Event name does not exist'
    end

    Event.create!(
      game: self,
      name: name,
      source_player: source_player,
      target_player: target_player,
    )

    save!
  end

  def current_round
    self.rounds.last
  end

  private

  def create_new_round
    self.rounds << {
      'player_ids' => self.players.where(state: 'alive').pluck(:id),
      'votes'      => {},
      'kills'      => {},
      'created_at' => Time.current,
      'expires_at' => Time.current + 5.minutes,
    }
  end

  def set_default_values
    self.state ||= 'initializing'
    self.token ||= SecureRandom.hex[0...6]
    self.rounds ||= []
  end
end
