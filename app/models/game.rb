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

class Game < ActiveRecord::Base
  extend Enumerize

  store :data, accessor: [:rounds], coder: JSON

  has_many :events
  has_many :players

  before_create :set_initial_status
  before_create :set_token

  validates :status, presence: true
  validates :token, presence: true

  enumerize :status, in: [
    :initializing,
    :in_progress,
    :finished,
  ]

  def start!
    num_players = self.players.count
    num_mafia = (num_players ** 0.5).ceil
    num_townsperson = num_players - num_mafia

    roles = (['townsperson'] * num_townsperson) + (['mafia'] * num_mafia)
    roles.shuffle!

    self.players.zip(roles).each do |player, role|
      player.update!(
        role: role
      )
    end

    self.status = 'active'
    self.rounds = []
    self.rounds << {
      # votes:
      started_at: Time.current,
      expires_at: Time.current + 30.seconds
    }

    save!
  end

  def update_state!
    return if Time.current < self.current_round.expires_at
  end

  def add_player(name:, avatar_type:)
    Player.create!(
      game_id: self.id,
      name: name,
      avatar_type: avatar_type
    )
  end

  def add_event(name:, source_player_id:, target_player_id:)
    event = Event.create!(
      game_id: self.id,
      name: name,
      source_player_id: source_player_id,
      target_player_id: target_player_id,
    )
  end

  private

  def current_round
    self.rounds.last
  end

  def set_initial_status
    self.status = :initializing
  end

  def set_token
    self.token = SecureRandom.hex[0...6]
  end
end
