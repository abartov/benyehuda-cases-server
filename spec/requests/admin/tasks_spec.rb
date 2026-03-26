require 'rails_helper'

RSpec.describe "Admin::Tasks", type: :request do
  let(:admin_user) { create(:user, :admin, :active_user) }
  let(:regular_user) { create(:user, :volunteer, :active_user) }
  let(:editor)      { create(:user, :editor, :active_user) }
  let(:volunteer)   { create(:user, :volunteer, :active_user) }
  let(:project) { create(:project, name: "Test Project") }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  # ── cascade ready_to_publish via admin state override ────────────────────

  describe "PUT /admin/tasks/:id (admin_state set to ready_to_publish)" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
    end

    def other_task_creat_task(kind:)
      create(:task, kind_id: kind, state: 'other_task_creat', editor: editor, assignee: volunteer)
    end

    context 'when a הגהה task is set to ready_to_publish and its parent הקלדה is eligible' do
      let!(:parent_typing)  { other_task_creat_task(kind: :הקלדה) }
      let!(:proofing_task)  { create(:task, kind_id: :הגהה, state: 'assigned',
                                     editor: editor, assignee: volunteer,
                                     parent_id: parent_typing.id) }

      it 'also transitions the parent הקלדה task to ready_to_publish' do
        put admin_task_path(proofing_task),
            params: { task: { admin_state: 'ready_to_publish' } }

        expect(parent_typing.reload.state).to eq('ready_to_publish')
      end
    end

    context 'when the task was already ready_to_publish (no state change)' do
      let!(:parent_typing) { other_task_creat_task(kind: :הקלדה) }
      let!(:proofing_task) { create(:task, kind_id: :הגהה, state: 'ready_to_publish',
                                    editor: editor, assignee: volunteer,
                                    parent_id: parent_typing.id) }

      it 'does not cascade (parent remains unchanged)' do
        put admin_task_path(proofing_task),
            params: { task: { admin_state: 'ready_to_publish' } }

        expect(parent_typing.reload.state).to eq('other_task_creat')
      end
    end

    context 'when an עריכה_טכנית task is set to ready_to_publish with a הגהה → הקלדה chain' do
      let!(:grandparent_typing) { other_task_creat_task(kind: :הקלדה) }
      let!(:parent_proofing) do
        other_task_creat_task(kind: :הגהה).tap { |t| t.update_column(:parent_id, grandparent_typing.id) }
      end
      let!(:tech_edit_task) { create(:task, kind_id: :עריכה_טכנית, state: 'assigned',
                                     editor: editor, assignee: volunteer,
                                     parent_id: parent_proofing.id) }

      it 'transitions both ancestor tasks to ready_to_publish' do
        put admin_task_path(tech_edit_task),
            params: { task: { admin_state: 'ready_to_publish' } }

        expect(parent_proofing.reload.state).to eq('ready_to_publish')
        expect(grandparent_typing.reload.state).to eq('ready_to_publish')
      end
    end
  end

  describe "GET /tasks/:id/start_ingestion" do
    # Create necessary TaskState record
    let!(:approved_state) { create(:task_state, name: 'approved', value: 'state_approved') }

    let(:task) { create(:approved_task, name: "Test Task", genre: "שירה", source: "Test Publisher") }
    let(:volunteer_user) { create(:user, :volunteer, :active_user) }
    let!(:document) do
      create(:document,
             task: task,
             user_id: volunteer_user.id,
             document_type: 'maintext',
             file_file_name: 'test.docx')
    end

    before do
      # Mock Paperclip URL to return a .docx URL
      allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('https://s3.example.com/test.docx')
    end

    context "when user is admin" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
      end

      context "when task has an associated project" do
        before do
          task.update(project: project)
        end

        it "includes tasks_project_id in the response" do
          get task_start_ingestion_path(task), xhr: true

          expect(response).to have_http_status(:success)
          expect(response.body).to include("ingestible[tasks_project_id]")
          expect(response.body).to include("value=\"#{project.id}\"")
        end

        it "includes other required fields" do
          get task_start_ingestion_path(task), xhr: true

          expect(response.body).to include("ingestible[title]")
          expect(response.body).to include(task.name)
          expect(response.body).to include("ingestible[genre]")
          expect(response.body).to include("ingestible[publisher]")
        end
      end

      context "when task has no associated project" do
        before do
          task.update(project: nil)
        end

        it "does not include tasks_project_id in the response" do
          get task_start_ingestion_path(task), xhr: true

          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("ingestible[tasks_project_id]")
        end

        it "still includes other required fields" do
          get task_start_ingestion_path(task), xhr: true

          expect(response.body).to include("ingestible[title]")
          expect(response.body).to include(task.name)
          expect(response.body).to include("ingestible[genre]")
          expect(response.body).to include("ingestible[publisher]")
        end
      end

      context "when task has no .docx file" do
        before do
          document.update(file_file_name: 'test.doc')
          allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('https://s3.example.com/test.doc')
        end

        it "shows error message" do
          get task_start_ingestion_path(task), xhr: true

          expect(response).to have_http_status(:success)
          expect(response.body).to include("לא נמצא קובץ DOCX")
        end
      end
    end

    context "when user is not admin" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(regular_user)
      end

      it "denies access" do
        # The before_action :require_admin will redirect or deny access
        # The exact behavior depends on the require_admin implementation
        get task_start_ingestion_path(task), xhr: true

        # Expecting unauthorized or redirect
        expect(response).not_to have_http_status(:success)
      end
    end
  end
end
