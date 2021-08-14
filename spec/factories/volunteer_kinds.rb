FactoryBot.define do
  factory :volunteer_kind do
    sequence(:name) {|n| "some_kind_#{n}"}
  end
end
