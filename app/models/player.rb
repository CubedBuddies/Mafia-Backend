# == Schema Information
#
# Table name: players
#
#  id                  :integer          not null, primary key
#  game_id             :integer
#  name                :string(255)
#  role                :string(255)
#  state               :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  avatar_file_name    :string(255)
#  avatar_content_type :string(255)
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#

class Player < ActiveRecord::Base
  extend Enumerize

  has_attached_file :avatar,
                    styles: { medium: "300x300>", thumb: "100x100>" },
                    default_url: "/images/:style/missing.png"

  belongs_to :game

  validates :game,
            presence: true

  validates :name,
            presence: true,
            uniqueness: { scope: :game, message: 'name must be unique per game' }

  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  enumerize :role, in: [
    :townsperson,
    :mafia,
  ]

  enumerize :state, in: [
    :alive,
    :dead,
  ]
end
