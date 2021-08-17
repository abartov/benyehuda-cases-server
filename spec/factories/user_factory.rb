FactoryBot.define do
  sequence(:uname) {|n| "Name#{n}"}
  factory :user do
    name { generate(:uname) }
    email {|a| "#{a.name}@example.com".downcase }

    password              {'qweqwe'}
#    password_confirmation {'qweqwe'}

#    skip_session_maintenance {true}
    factory :active_user do
      activated_at {1.month.ago.utc}
    end
    
    factory :admin do
      is_admin {true}
      factory :other_admin do
      end
    end
    
    factory :editor do
      is_editor {true}
      factory :another_editor do
      end
    end
    
    factory :volunteer do
      is_volunteer {true}
      factory :another_volunteer do
      end
      
      factory :volunteer_wanting_a_task do
        task_requested_at {Time.now.utc}
      end
  
    end
  end
end
