FactoryBot.define do
  factory :team do
    name { "MyString" }
    open { false }
    description { "" }
    status { 0 }
    targetdate { "2024-11-08" }
  end
end
