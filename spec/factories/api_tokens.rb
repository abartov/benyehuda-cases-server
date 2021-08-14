FactoryBot.define do
  factory :api_token do
    token { "MyString" }
    api_user
    expires_at { 1.day.from_now }
  end
end
