require 'rails_helper'

RSpec.describe 'documents/_document', type: :view do
  let(:task) { create(:task) }
  let(:user) { create(:user, :volunteer, :active_user) }

  before do
    # Stub helper methods
    def view.current_user
      @current_user
    end
    def view.document_can_be_deleted_by?(_document, _user)
      false
    end
    view.instance_variable_set(:@current_user, user)
  end

  context 'when document is an image' do
    let(:image_document) do
      create(:document,
             task: task,
             user: user,
             file_file_name: 'test_image.jpg',
             file_file_size: 1024)
    end

    before do
      # Mock the file URL
      allow(image_document.file).to receive(:url).and_return('https://s3.example.com/test_image.jpg')
    end

    it 'displays the crop & download link' do
      render partial: 'documents/document', locals: { document: image_document }

      expect(rendered).to include('crop-image-link')
    end

    it 'includes correct data attributes for image URL' do
      render partial: 'documents/document', locals: { document: image_document }

      expect(rendered).to include("data-image-url='https://s3.example.com/test_image.jpg'")
    end

    it 'includes correct data attributes for image name' do
      render partial: 'documents/document', locals: { document: image_document }

      expect(rendered).to include("data-image-name='test_image.jpg'")
    end

    %w[jpg png tiff tif gif jpeg bmp].each do |ext|
      it "recognizes .#{ext} files as images" do
        image_doc = create(:document,
                           task: task,
                           user: user,
                           file_file_name: "test.#{ext}",
                           file_file_size: 1024)
        allow(image_doc.file).to receive(:url).and_return("https://s3.example.com/test.#{ext}")

        render partial: 'documents/document', locals: { document: image_doc }

        expect(rendered).to include('crop-image-link')
      end
    end
  end

  context 'when document is not an image' do
    let(:text_document) do
      create(:document,
             task: task,
             user: user,
             file_file_name: 'test_document.docx',
             file_file_size: 2048)
    end

    before do
      allow(text_document.file).to receive(:url).and_return('https://s3.example.com/test_document.docx')
    end

    it 'does not display the crop & download link' do
      render partial: 'documents/document', locals: { document: text_document }

      expect(rendered).not_to include('crop-image-link')
    end

    %w[doc docx txt rtf odt pdf].each do |ext|
      it "does not show crop link for .#{ext} files" do
        doc = create(:document,
                     task: task,
                     user: user,
                     file_file_name: "test.#{ext}",
                     file_file_size: 2048)
        allow(doc.file).to receive(:url).and_return("https://s3.example.com/test.#{ext}")

        render partial: 'documents/document', locals: { document: doc }

        expect(rendered).not_to include('crop-image-link')
      end
    end
  end

  context 'link text' do
    let(:image_document) do
      create(:document,
             task: task,
             user: user,
             file_file_name: 'test.png',
             file_file_size: 1024)
    end

    before do
      allow(image_document.file).to receive(:url).and_return('https://s3.example.com/test.png')
    end

    it 'displays the correct link text' do
      render partial: 'documents/document', locals: { document: image_document }

      expect(rendered).to include('crop-image-link')
      # Match the Hebrew translation or the pattern
      expect(rendered).to match(/\[.*\]/)
      expect(rendered).to include(I18n.t('documents.crop_and_download'))
    end
  end
end
