# == Schema Information
#
# Table name: players
#
#  id          :integer          not null, primary key
#  game_id     :integer
#  name        :string(255)
#  avatar_type :string(255)
#  role        :string(255)
#  state       :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryGirl.define do
  factory :player do
    game

    name        { Forgery(:name).first_name }
    avatar_type { 'asian' }
  end
end
