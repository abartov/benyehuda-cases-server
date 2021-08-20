# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryBot.define do
  factory :task_state do
    name {"some name"}
    value {"some value"}
  end
end