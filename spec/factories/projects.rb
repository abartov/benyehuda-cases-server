# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :project do
    name {"MyString"}
    description {"MyText"}
    status {1}
  end
end
