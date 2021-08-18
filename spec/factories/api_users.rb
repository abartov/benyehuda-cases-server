FactoryBot.define do
  sequence :email do |n| 
    "apitest#{n}@mailinator.com"
  end
  sequence :api_key do |n|
    "random_hash_#{n}"
  end
  factory :api_user, class: APIUser do
    api_key
    email
  end
end
