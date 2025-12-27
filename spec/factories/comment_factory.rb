FactoryBot.define do
  factory :comment do
    task
    user
    message { "Test comment message" }
    editor_eyes_only { false }
    is_rejection_reason { false }
    is_abandoning_reason { false }
    is_finished_reason { false }
    is_help_required_reason { false }
  end
end
