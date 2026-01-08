require 'rails_helper'

RSpec.describe "Report", type: :request do
  let(:editor) { create(:user, :editor, :active_user) }

  before do
    # Mock authentication - report controller requires editor or admin
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(ApplicationController).to receive(:require_editor_or_admin).and_return(true)
  end

  describe "GET /report/few_tasks_left" do
    context "when sorting by TaskKind and name" do
      # Create necessary TaskState record
      let!(:unassigned_state) { create(:task_state, name: 'unassigned', value: 'state_unassigned') }

      # Create task kinds with names that will test alphabetical sorting
      # We need to find or create the specific kinds that the query looks for (kind_id: [1, 21])
      let!(:kind1) { TaskKind.find_or_create_by(id: 1) { |k| k.name = 'Zebra Kind' } }
      let!(:kind21) { TaskKind.find_or_create_by(id: 21) { |k| k.name = 'Apple Kind' } }

      # Create parent tasks for grouping
      # For kind_id = 1: grouped by parent_id (parent1)
      let!(:parent1) { create(:task, name: 'Parent Z', kind: kind1) }

      # For kind_id = 21: grouped by grandparent (parent2's parent = grandparent2)
      let!(:grandparent2) { create(:task, name: 'Grandparent A', kind: kind21) }
      let!(:parent2) { create(:task, name: 'Parent A', kind: kind21, parent: grandparent2) }

      # Create child tasks with few tasks (< 3) to trigger the report
      # Tasks with kind_id = 1 (grouped by parent)
      let!(:task1_kind1_z) do
        create(:task,
               name: 'Zebra Task 1',
               kind: kind1,
               state: 'unassigned',
               parent: parent1,
               assignee: nil)
      end
      let!(:task2_kind1_a) do
        create(:task,
               name: 'Apple Task 1',
               kind: kind1,
               state: 'unassigned',
               parent: parent1,
               assignee: nil)
      end

      # Tasks with kind_id = 21 (grouped by grandparent)
      let!(:task3_kind21_z) do
        create(:task,
               name: 'Zebra Task 21',
               kind: kind21,
               state: 'unassigned',
               parent: parent2,
               assignee: nil)
      end
      let!(:task4_kind21_a) do
        create(:task,
               name: 'Apple Task 21',
               kind: kind21,
               state: 'unassigned',
               parent: parent2,
               assignee: nil)
      end

      it "successfully loads the page and executes the query with TaskKind and name sorting" do
        get report_few_tasks_left_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Apple Kind')
        expect(response.body).to include('Zebra Kind')

        # Verify the response contains task names
        expect(response.body).to include('Apple Task')
        expect(response.body).to include('Zebra Task')

        # Verify filter dropdown is present
        expect(response.body).to include('סנן לפי סוג משימה')
        expect(response.body).to include('הכל')
      end

      it "returns tasks sorted by TaskKind name alphabetically (verified via database query)" do
        # Directly test the query to verify sorting
        parent_group_sql = "CASE WHEN tasks.kind_id = 21 THEN parent_tasks.parent_id ELSE tasks.parent_id END"
        few_tasks_parents = Task.joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
                                .where(kind_id: [1, 21], state: 'unassigned')
                                .group(parent_group_sql)
                                .having('count(tasks.id) < 3')
                                .pluck(Arel.sql(parent_group_sql))
                                .compact

        tasks = Task.joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
                    .joins(:kind)
                    .where(kind_id: [1, 21], state: 'unassigned')
                    .where("#{parent_group_sql} IN (?)", few_tasks_parents)
                    .order('task_kinds.name', 'tasks.name')
                    .to_a

        # Verify we have tasks from both kinds
        kind_names = tasks.map { |t| t.kind.name }.uniq.sort
        expect(kind_names).to eq(['Apple Kind', 'Zebra Kind'])

        # Verify Apple Kind appears before Zebra Kind
        apple_index = tasks.index { |t| t.kind.name == 'Apple Kind' }
        zebra_index = tasks.index { |t| t.kind.name == 'Zebra Kind' }
        expect(apple_index).to be < zebra_index

        # Verify tasks within each kind are sorted by name
        tasks.group_by { |t| t.kind.name }.each do |kind_name, kind_tasks|
          task_names = kind_tasks.map(&:name)
          expect(task_names).to eq(task_names.sort),
            "Expected tasks of kind '#{kind_name}' to be sorted by name"
        end
      end

      it "filters tasks by TaskKind when kind_id parameter is provided" do
        # Filter by kind 21 (Apple Kind)
        get report_few_tasks_left_path(kind_id: 21)

        expect(response).to have_http_status(:success)

        # Verify only Apple Kind tasks appear
        expect(response.body).to include('Apple Kind')
        expect(response.body).to include('Apple Task 21')
        expect(response.body).to include('Zebra Task 21')

        # Verify Zebra Kind tasks do NOT appear
        expect(response.body).not_to include('Apple Task 1')
        expect(response.body).not_to include('Zebra Task 1')

        # Verify the query directly
        parent_group_sql = "CASE WHEN tasks.kind_id = 21 THEN parent_tasks.parent_id ELSE tasks.parent_id END"
        few_tasks_parents = Task.joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
                                .where(kind_id: [21], state: 'unassigned')
                                .group(parent_group_sql)
                                .having('count(tasks.id) < 3')
                                .pluck(Arel.sql(parent_group_sql))
                                .compact

        tasks = Task.joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
                    .joins(:kind)
                    .where(kind_id: [21], state: 'unassigned')
                    .where("#{parent_group_sql} IN (?)", few_tasks_parents)
                    .order('task_kinds.name', 'tasks.name')
                    .to_a

        # All tasks should be of kind 21
        expect(tasks.all? { |t| t.kind_id == 21 }).to be true
      end

      it "filters tasks by TaskKind when kind_id parameter is 1" do
        # Filter by kind 1 (Zebra Kind)
        get report_few_tasks_left_path(kind_id: 1)

        expect(response).to have_http_status(:success)

        # Verify only Zebra Kind tasks appear
        expect(response.body).to include('Zebra Kind')
        expect(response.body).to include('Apple Task 1')
        expect(response.body).to include('Zebra Task 1')

        # Verify Apple Kind (21) tasks do NOT appear
        expect(response.body).not_to include('Apple Task 21')
        expect(response.body).not_to include('Zebra Task 21')
      end
    end
  end
end
