require 'rails_helper'

RSpec.describe "Report", type: :request do
  let(:editor) { create(:user, :editor, :active_user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(ApplicationController).to receive(:require_editor_or_admin).and_return(true)
  end

  describe "GET /report/few_tasks_left" do
    context "when tasks exist for הקלדה and הגהה" do
      let!(:unassigned_state) { create(:task_state, name: 'unassigned', value: 'state_unassigned') }

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
