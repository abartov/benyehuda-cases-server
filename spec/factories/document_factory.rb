FactoryBot.define do
  factory :document do
    task
    file_file_size {123}
    user_id factory: :volunteer
    file_file_name {"foobar"}
    created_at {Time.now.utc}
  end
  
end

