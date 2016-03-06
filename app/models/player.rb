# == Schema Information
#
# Table name: players
#
#  id          :integer          not null, primary key
#  game_id     :integer
#  name        :string(255)
#  role        :string(255)
#  avatar_type :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Player < ActiveRecord::Base
  extend Enumerize

  belongs_to :game

  validates :game, presence: true
  validates :name, presence: true
  validates :avatar_type, presence: true

  enumerize :name, in: [
    :townsperson,
    :mafia,
  ]
end
