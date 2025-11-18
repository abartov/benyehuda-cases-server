FactoryBot.define do
  sequence(:tname) { |n| "some_#{n}" }
  factory :task do
    name { generate(:tname) }
    creator { create :user, :admin }
    assignee { create :user, :volunteer }
    editor { create :user, :editor }
    kind { create :task_kind }
    difficulty { 'normal' }
    parent_id { nil }
    factory :unassigned_task do
      assignee { nil }
      editor { nil }
    end

    factory :assigned_task do
      state { 'assigned' }
    end

    factory :waits_for_editor_approve_task do
      state { 'waits_for_editor' }
    end

    factory :approved_task do
      state { 'approved' }
    end
  end
end
