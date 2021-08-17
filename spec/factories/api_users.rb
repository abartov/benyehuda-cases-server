FactoryBot.define do
  sequence :email do |n| 
    "apitest#{n}@mailinator.com"
  end
  factory :api_user, class: APIUser do
    api_key {"valid_key"}
    email
  end
end
