# encoding: utf-8
# Tests for the download_pdf action: PDF-only tasks use pdfunite; image tasks use img2pdf.
# A single PDF is passed through directly; a single image still uses img2pdf.
require 'rails_helper'

RSpec.describe 'Tasks download_pdf', type: :request do
  let(:editor)    { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user) }
  let(:task)      { create(:task, state: 'approved', editor: editor, assignee: volunteer) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(Task).to receive(:participant?).and_return(true)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
    # S3 bucket is nil in test env; stub file.url so it doesn't raise
    allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('http://example.com/fake.pdf')
    allow(HTTParty).to receive(:get).and_return(double('resp', body: '%PDF-1.4 fake'))
  end

  def add_doc(task, filename, doc_type: 'maintext')
    create(:document,
           task: task,
           file_file_name: filename,
           file_content_type: 'application/octet-stream',
           file_file_size: 100,
           document_type: doc_type,
           user_id: volunteer.id)
  end

  def stub_img2pdf_ok
    allow_any_instance_of(TasksController).to receive(:run_img2pdf) do |_ctrl, _input, output|
      File.write(output, '%PDF-1.4 img2pdf-generated')
    end
  end

  def stub_pdfunite_ok
    allow_any_instance_of(TasksController).to receive(:run_pdfunite) do |_ctrl, _args, output|
      File.write(output, '%PDF-1.4 pdfunite-merged')
    end
  end

  context 'when a single PDF document exists' do
    before { add_doc(task, 'solo.pdf') }

    it 'streams the PDF directly without merging' do
      expect_any_instance_of(TasksController).not_to receive(:run_pdfunite)
      expect_any_instance_of(TasksController).not_to receive(:run_img2pdf)

      get task_download_pdf_path(task), params: { dtype: 'maintext' }

      expect(response.content_type).to eq('application/pdf')
    end
  end

  context 'when all documents are PDFs (multiple)' do
    before { add_doc(task, 'scan1.pdf') && add_doc(task, 'scan2.pdf') }

    it 'uses pdfunite to concatenate the PDFs' do
      pdfunite_called = false
      allow_any_instance_of(TasksController).to receive(:run_pdfunite) do |_ctrl, _args, output|
        pdfunite_called = true
        File.write(output, '%PDF-1.4 merged')
      end

      get task_download_pdf_path(task), params: { dtype: 'maintext' }

      expect(pdfunite_called).to be true
    end

    it 'does not call img2pdf' do
      stub_pdfunite_ok
      expect_any_instance_of(TasksController).not_to receive(:run_img2pdf)

      get task_download_pdf_path(task), params: { dtype: 'maintext' }
    end

    it 'returns a PDF response' do
      stub_pdfunite_ok
      get task_download_pdf_path(task), params: { dtype: 'maintext' }
      expect(response.content_type).to eq('application/pdf')
    end
  end

  context 'when documents include JPEG images' do
    before { add_doc(task, 'scan1.jpg') && add_doc(task, 'scan2.jpg') }

    it 'uses img2pdf for conversion' do
      img2pdf_called = false
      allow_any_instance_of(TasksController).to receive(:run_img2pdf) do |_ctrl, _input, output|
        img2pdf_called = true
        File.write(output, '%PDF-1.4 generated')
      end

      get task_download_pdf_path(task), params: { dtype: 'maintext' }

      expect(img2pdf_called).to be true
    end

    it 'does not call pdfunite' do
      stub_img2pdf_ok
      expect_any_instance_of(TasksController).not_to receive(:run_pdfunite)

      get task_download_pdf_path(task), params: { dtype: 'maintext' }
    end
  end

  context 'when documents include PNG images alongside a PDF' do
    before { add_doc(task, 'scan.png') && add_doc(task, 'appendix.pdf') }

    it 'uses img2pdf (image path) rather than pdfunite' do
      img2pdf_called = false
      allow_any_instance_of(TasksController).to receive(:run_img2pdf) do |_ctrl, _input, output|
        img2pdf_called = true
        File.write(output, '%PDF-1.4 generated')
      end

      get task_download_pdf_path(task), params: { dtype: 'maintext' }

      expect(img2pdf_called).to be true
    end
  end

  context 'when there are no matching image or PDF documents' do
    before { add_doc(task, 'report.docx') }

    it 'redirects back to the task with an error' do
      get task_download_pdf_path(task), params: { dtype: 'maintext' }
      expect(response).to redirect_to(task_path(task))
    end
  end
end
