FactoryBot.define do
  factory :audit_log do
    backtrace { "MyString" }
    data { "MyString" }
    api_user { nil }
  end
end
