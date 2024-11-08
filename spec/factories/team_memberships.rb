FactoryBot.define do
  factory :team_membership do
    team { nil }
    user { nil }
    joined { "2024-11-08 07:20:43" }
    left { "2024-11-08 07:20:43" }
    user_role { 1 }
  end
end
