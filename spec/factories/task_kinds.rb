FactoryBot.define do
  factory :task_kind do
    sequence(:name) {|n| "some_kind_#{n}"}
  end
end
