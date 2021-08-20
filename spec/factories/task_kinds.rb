FactoryBot.define do
  sequence(:tkname) {|n| "some_kind_#{n}"}
  factory :task_kind do
    name { generate(:tkname) }
  end
end
