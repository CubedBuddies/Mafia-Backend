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

FactoryGirl.define do
  factory :player do
    game

    name        { Forgery(:name).first_name }
    avatar_type { ["boy1", "boy2", "girl1", "girl2"].sample }
  end
end
