FactoryBot.define do
  factory :volunteer_request do
    sequence(:preferences) {|n| "Some reason #{n}"}
    user factory: :active_user
    factory :confirmed_volunteer_request do
      approved_at {1.month.ago.utc}
    end
  
  end
end
