FactoryBot.define do
  factory :task do
    sequence(:name) {|n| "some_#{n}"}
    creator factory: :admin
    assignee factory: :volunteer
    editor factory: :editor
    kind factory: :task_kind
    difficulty {"normal"}
    parent_id {nil}
    factory :unassigned_task do
      assignee {nil}
      editor {nil}
    end
  
    factory :assigned_task do
      state {"assigned"}
    end
  
    factory :waits_for_editor_approve_task do
      state {"waits_for_editor"}
    end
  
    factory :approved_task do
      state {"approved"}
    end
  
  end

end