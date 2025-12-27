FactoryBot.define do
  factory :audit do
    task
    user
    auditable_type { 'Task' }
    action { 3 } # update
    changed_attrs { {} }

    trait :task_audit do
      association :auditable, factory: :task
    end
  end
end
