FactoryBot.define do
  factory :folder_tag do
    sequence(:name) { |n| "tag#{n}" }
  end

  factory :scan_folder do
    sequence(:name) { |n| "folder#{n}" }
    status { 'raw' }
  end
end
