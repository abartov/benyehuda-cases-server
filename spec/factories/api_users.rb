FactoryBot.define do
  sequence :email do |n| 
    "apitest#{n}@mailinator.com"
  end
  factory :api_user, class: APIUser do
    password {"Passw0rd"}
    password_confirmation { |u| u.password }

    email
  end
end
