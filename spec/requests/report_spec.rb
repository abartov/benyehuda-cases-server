require 'rails_helper'

RSpec.describe "Report", type: :request do
  let(:editor) { create(:user, :editor, :active_user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(ApplicationController).to receive(:require_editor_or_admin).and_return(true)
  end

  describe "GET /report/all_parts_ready" do
    # A parent qualifies when every one of its הקלדה children has at least one
    # הגהה child and all of those הגהה children are in the 'approved' state
    # (the state the UI labels "Approved by Editor").
    def typing_child(parent)
      create(:task, kind_id: :הקלדה, parent: parent)
    end

    def proofing_child(parent, state)
      create(:task, kind_id: :הגהה, parent: parent, state: state)
    end

    let!(:ready_parent) { create(:task, kind_id: :אחר) }
    let!(:partly_ready_parent) { create(:task, kind_id: :אחר) }
    let!(:unproofed_parent) { create(:task, kind_id: :אחר) }
    let!(:not_started_parent) { create(:task, kind_id: :אחר) }

    before do
      # every part fully proofread → included
      proofing_child(typing_child(ready_parent), 'approved')
      second_part = typing_child(ready_parent)
      proofing_child(second_part, 'approved')
      proofing_child(second_part, 'approved')

      # one part done, one part still waiting → excluded
      proofing_child(typing_child(partly_ready_parent), 'approved')
      proofing_child(typing_child(partly_ready_parent), 'waits_for_editor')

      # the only part's proofing was not approved → excluded
      proofing_child(typing_child(unproofed_parent), 'assigned')

      # the only part has no proofing task at all → excluded
      typing_child(not_started_parent)
    end

    it "successfully loads the page" do
      get report_all_parts_ready_path
      expect(response).to have_http_status(:success)
    end

    it "lists parents whose parts are all approved" do
      get report_all_parts_ready_path
      expect(response.body).to include(ready_parent.name)
    end

    it "excludes parents with a part that is not fully approved" do
      get report_all_parts_ready_path
      expect(response.body).not_to include(partly_ready_parent.name)
      expect(response.body).not_to include(unproofed_parent.name)
    end

    it "excludes parents with a part that has no הגהה task yet" do
      get report_all_parts_ready_path
      expect(response.body).not_to include(not_started_parent.name)
    end

    it "is linked from the reports index" do
      get report_path
      expect(response.body).to include(I18n.t('report.all_parts_ready'))
      expect(response.body).to include(report_all_parts_ready_path)
    end
  end

  describe "GET /report/few_tasks_left" do
    context "when tasks exist for הקלדה and הגהה" do
      # הקלדה (kind_id=1): group by parent_id
      let!(:parent_typing)  { create(:task, kind_id: :הקלדה) }

      # הגהה (kind_id=21): group by grandparent (parent's parent_id)
      let!(:grandparent_proofing) { create(:task, kind_id: :הגהה) }
      let!(:parent_proofing)      { create(:task, kind_id: :הגהה, parent: grandparent_proofing) }

      # Unassigned child tasks with fewer than 3 per group → appear in report
      let!(:typing_task1) { create(:task, kind_id: :הקלדה, state: 'unassigned', parent: parent_typing, assignee: nil) }
      let!(:typing_task2) { create(:task, kind_id: :הקלדה, state: 'unassigned', parent: parent_typing, assignee: nil) }
      let!(:proofing_task1) { create(:task, kind_id: :הגהה, state: 'unassigned', parent: parent_proofing, assignee: nil) }
      let!(:proofing_task2) { create(:task, kind_id: :הגהה, state: 'unassigned', parent: parent_proofing, assignee: nil) }

      it "successfully loads the page" do
        get report_few_tasks_left_path
        expect(response).to have_http_status(:success)
      end

      it "shows tasks from both kinds" do
        get report_few_tasks_left_path
        expect(response.body).to include(typing_task1.name)
        expect(response.body).to include(proofing_task1.name)
      end

      it "shows the kind filter dropdown" do
        get report_few_tasks_left_path
        expect(response.body).to include('סנן לפי סוג משימה')
        expect(response.body).to include('הכל')
      end

      it "filters by הקלדה when kind_id=הקלדה is given" do
        get report_few_tasks_left_path(kind_id: 'הקלדה')
        expect(response).to have_http_status(:success)
        expect(response.body).to include(typing_task1.name)
        expect(response.body).not_to include(proofing_task1.name)
      end

      it "filters by הגהה when kind_id=הגהה is given" do
        get report_few_tasks_left_path(kind_id: 'הגהה')
        expect(response).to have_http_status(:success)
        expect(response.body).to include(proofing_task1.name)
        expect(response.body).not_to include(typing_task1.name)
      end

      it "tasks are sorted by kind_id (integer ascending: הקלדה=1 before הגהה=21)" do
        proofing_id = Task.kind_ids[:הגהה]
        parent_sql = "CASE WHEN tasks.kind_id = #{proofing_id} THEN parent_tasks.parent_id ELSE tasks.parent_id END"
        tasks = Task
          .joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
          .where(kind_id: %w[הקלדה הגהה], state: 'unassigned')
          .where("#{parent_sql} IN (?)", [parent_typing.id, grandparent_proofing.id])
          .order('tasks.kind_id', 'tasks.created_at')
          .to_a

        # הקלדה (kind_id integer=1) should come before הגהה (kind_id integer=21)
        first_typing_index  = tasks.index { |t| t.kind_id == 'הקלדה' }
        first_proofing_index = tasks.index { |t| t.kind_id == 'הגהה' }
        expect(first_typing_index).to be < first_proofing_index
      end
    end
  end
end
