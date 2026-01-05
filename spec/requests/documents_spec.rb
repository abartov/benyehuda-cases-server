require 'rails_helper'

RSpec.describe "Documents", type: :request do
  let(:user) { create(:user, :volunteer, :active_user) }
  let(:task) { create(:task, assignee: user) }
  let(:document) do
    create(:document,
           task: task,
           user: user,
           file_file_name: 'test_image.jpg',
           file_file_size: 1024)
  end

  before do
    # Mock S3 URL
    allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('https://s3.example.com/test.jpg')

    # Mock authentication
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
  end

  describe "GET /tasks/:task_id/documents/:id/proxy_image" do
    context "when user is task participant" do
      before do
        # Mock HTTParty response
        mock_response = double('response', body: 'fake image data', code: 200)
        allow(HTTParty).to receive(:get).and_return(mock_response)
      end

      it "proxies the image from S3" do
        get proxy_task_document_image_path(task, document)

        expect(response).to have_http_status(:success)
        expect(response.body).to eq('fake image data')
      end

      it "sets CORS headers" do
        get proxy_task_document_image_path(task, document)

        expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      end

      it "sets correct content type" do
        get proxy_task_document_image_path(task, document)

        expect(response.content_type).to match(/image/)
      end

      it "fetches from the document's S3 URL" do
        expect(HTTParty).to receive(:get).with('https://s3.example.com/test.jpg')

        get proxy_task_document_image_path(task, document)
      end
    end

    context "when user is not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(false)
      end

      it "returns forbidden" do
        get proxy_task_document_image_path(task, document)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not task participant" do
      let(:other_user) { create(:user, :volunteer, :active_user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)
      end

      it "returns forbidden" do
        get proxy_task_document_image_path(task, document)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
