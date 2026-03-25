# encoding: utf-8
# Tests for the cascade-to-parent ready_to_publish behaviour.
require 'rails_helper'

RSpec.describe 'Task#complete_related_ancestor_tasks', type: :model do
  let(:editor)    { create(:user, :editor) }
  let(:volunteer) { create(:user, :volunteer) }

  before do
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  # Helper: build a task already in `approved` state so `complete` is allowed.
  def approved_task(kind:, parent: nil)
    create(:task,
           kind_id:   kind,
           state:     'approved',
           editor:    editor,
           assignee:  volunteer,
           parent_id: parent&.id)
  end

  # Helper: build a parent task that a child was spun off from.
  # After `create_other_task` fires the parent moves to `other_task_creat`,
  # which is one of the valid `from` states for `complete`.
  def other_task_creat_task(kind:)
    t = create(:task,
               kind_id:  kind,
               state:    'other_task_creat',
               editor:   editor,
               assignee: volunteer)
    t
  end

  # ── הגהה cascades to הקלדה parent ─────────────────────────────────────────

  context 'when a הגהה task is completed' do
    context 'and its parent is a הקלדה task eligible for complete' do
      let(:parent_typing) { other_task_creat_task(kind: :הקלדה) }
      let(:proofing_task) { approved_task(kind: :הגהה, parent: parent_typing) }

      it 'returns the parent הקלדה task' do
        proofing_task.complete
        result = proofing_task.complete_related_ancestor_tasks
        expect(result).to eq([parent_typing])
      end

      it 'transitions the parent הקלדה task to ready_to_publish' do
        proofing_task.complete
        proofing_task.complete_related_ancestor_tasks
        expect(parent_typing.reload.state).to eq('ready_to_publish')
      end
    end

    context 'and its parent is NOT a הקלדה task' do
      let(:parent_other) { other_task_creat_task(kind: :אחר) }
      let(:proofing_task) { approved_task(kind: :הגהה, parent: parent_other) }

      it 'returns an empty array' do
        proofing_task.complete
        expect(proofing_task.complete_related_ancestor_tasks).to be_empty
      end

      it 'does not change the parent task state' do
        proofing_task.complete
        proofing_task.complete_related_ancestor_tasks
        expect(parent_other.reload.state).to eq('other_task_creat')
      end
    end

    context 'and there is no parent task' do
      let(:proofing_task) { approved_task(kind: :הגהה) }

      it 'returns an empty array' do
        proofing_task.complete
        expect(proofing_task.complete_related_ancestor_tasks).to be_empty
      end
    end

    context 'and the parent הקלדה task is not in a completable state' do
      let(:parent_typing) { create(:task, kind_id: :הקלדה, state: 'assigned', editor: editor, assignee: volunteer) }
      let(:proofing_task) { approved_task(kind: :הגהה, parent: parent_typing) }

      it 'returns an empty array' do
        proofing_task.complete
        expect(proofing_task.complete_related_ancestor_tasks).to be_empty
      end

      it 'does not change the parent task state' do
        proofing_task.complete
        proofing_task.complete_related_ancestor_tasks
        expect(parent_typing.reload.state).to eq('assigned')
      end
    end
  end

  # ── עריכה_טכנית cascades to direct הקלדה parent ──────────────────────────

  context 'when an עריכה_טכנית task is completed' do
    context 'and its direct parent is a הקלדה task' do
      let(:parent_typing) { other_task_creat_task(kind: :הקלדה) }
      let(:tech_edit_task) { approved_task(kind: :עריכה_טכנית, parent: parent_typing) }

      it 'returns the parent הקלדה task' do
        tech_edit_task.complete
        result = tech_edit_task.complete_related_ancestor_tasks
        expect(result).to eq([parent_typing])
      end

      it 'transitions the parent הקלדה task to ready_to_publish' do
        tech_edit_task.complete
        tech_edit_task.complete_related_ancestor_tasks
        expect(parent_typing.reload.state).to eq('ready_to_publish')
      end
    end

    context 'and its direct parent is a הגהה task (with no הקלדה grandparent)' do
      let(:parent_proofing) { other_task_creat_task(kind: :הגהה) }
      let(:tech_edit_task)  { approved_task(kind: :עריכה_טכנית, parent: parent_proofing) }

      it 'returns the parent הגהה task' do
        tech_edit_task.complete
        result = tech_edit_task.complete_related_ancestor_tasks
        expect(result).to eq([parent_proofing])
      end

      it 'transitions the parent הגהה task to ready_to_publish' do
        tech_edit_task.complete
        tech_edit_task.complete_related_ancestor_tasks
        expect(parent_proofing.reload.state).to eq('ready_to_publish')
      end
    end

    context 'and the chain is עריכה_טכנית → הגהה → הקלדה' do
      let(:grandparent_typing) { other_task_creat_task(kind: :הקלדה) }
      let(:parent_proofing) do
        other_task_creat_task(kind: :הגהה).tap { |t| t.update_column(:parent_id, grandparent_typing.id) }
      end
      let(:tech_edit_task) { approved_task(kind: :עריכה_טכנית, parent: parent_proofing) }

      it 'returns both ancestor tasks' do
        tech_edit_task.complete
        result = tech_edit_task.complete_related_ancestor_tasks
        expect(result).to contain_exactly(parent_proofing, grandparent_typing)
      end

      it 'transitions both ancestor tasks to ready_to_publish' do
        tech_edit_task.complete
        tech_edit_task.complete_related_ancestor_tasks
        expect(parent_proofing.reload.state).to eq('ready_to_publish')
        expect(grandparent_typing.reload.state).to eq('ready_to_publish')
      end
    end

    context 'and there is no parent task' do
      let(:tech_edit_task) { approved_task(kind: :עריכה_טכנית) }

      it 'returns an empty array' do
        tech_edit_task.complete
        expect(tech_edit_task.complete_related_ancestor_tasks).to be_empty
      end
    end
  end

  # ── Other task kinds are unaffected ───────────────────────────────────────

  context 'when a הקלדה task is completed' do
    let(:parent_other) { other_task_creat_task(kind: :אחר) }
    let(:typing_task)  { approved_task(kind: :הקלדה, parent: parent_other) }

    it 'returns an empty array regardless of parent' do
      typing_task.complete
      expect(typing_task.complete_related_ancestor_tasks).to be_empty
    end
  end
end
