FactoryBot.define do
  sequence(:uname) { |n| "Name#{n}" }
  factory :user do
    name { generate(:uname) }
    email { |a| "#{a.name}@example.com".downcase }

    password { 'qweqwe' }
    #    password_confirmation {'qweqwe'}

    #    skip_session_maintenance {true}
    trait :active_user do
      activated_at { 1.month.ago.utc }
    end

    trait :admin do
      is_admin { true }
      trait :other_admin do
      end
    end

    trait :editor do
      is_editor { true }
      trait :another_editor do
      end
    end

    trait :volunteer do
      is_volunteer { true }
      trait :another_volunteer do
      end

      trait :volunteer_wanting_a_task do
        task_requested_at { Time.now.utc }
      end
    end
  end
end
