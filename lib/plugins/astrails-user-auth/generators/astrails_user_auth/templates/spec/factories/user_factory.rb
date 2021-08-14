FactoryBot.define do
  factory :user do
    sequence(:name) {|n| "Name#{n}"}

    email {|a| "#{a.name}@example.com".downcase }

    password { 'qweqwe'}
    password_confirmation {'qweqwe'}

    skip_session_maintenance {true}
    factory :active_user do
      activated_at {1.month.ago.utc}
    end
  
  end

end

