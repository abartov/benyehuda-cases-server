FactoryBot.define do
  factory :property do
    sequence(:title) {|n| "some_#{n}"}
    parent_type {"Editor"}
    property_type {"string"}
    factory :bool_property do
      property_type {"boolean"}
    end
  
    factory :text_property do
      property_type {"text"}
    end
  
  end

end