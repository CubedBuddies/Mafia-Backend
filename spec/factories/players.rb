FactoryGirl.define do
  factory :player do
    game

    name        { Forgery(:name).first_name }
    avatar_type { 'asian' }
  end
end
