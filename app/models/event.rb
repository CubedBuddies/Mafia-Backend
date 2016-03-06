# == Schema Information
#
# Table name: events
#
#  id                  :integer          not null, primary key
#  game_id             :integer
#  source_player_id    :integer
#  target_player_id    :integer
#  name                :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Event < ActiveRecord::Base
  extend Enumerize

  belongs_to :game
  belongs_to :source_player, class_name: Player
  belongs_to :target_player, class_name: Player

  validates :game, presence: true
  validates :name, presence: true

  enumerize :name, in: [
    :kill,
    :vote,
  ]
end
