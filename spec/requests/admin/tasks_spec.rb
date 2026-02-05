require 'rails_helper'

RSpec.describe "Admin::Tasks", type: :request do
  let(:admin_user) { create(:user, :admin, :active_user) }
  let(:regular_user) { create(:user, :volunteer, :active_user) }
  let(:project) { create(:project, name: "Test Project") }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
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
