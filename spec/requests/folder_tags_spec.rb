require 'rails_helper'

RSpec.describe 'FolderTags', type: :request do
  let(:admin) { create(:user, :admin, :active_user) }
  let(:current) { admin }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current)
  end

  context 'as a non-admin' do
    let(:current) { create(:user, :editor, :active_user) }

    it 'is denied' do
      get folder_tags_path
      expect(response).to redirect_to('/')
    end
  end

  it 'lists tags with folder counts' do
    tag = create(:folder_tag, name: 'ביאליק')
    create(:scan_folder, folder_tags: [tag])
    get folder_tags_path
    expect(response.body).to include('ביאליק')
  end

  it 'creates a tag' do
    expect { post folder_tags_path, params: { folder_tag: { name: ' new ' } } }.to change(FolderTag, :count).by(1)
    expect(FolderTag.last.name).to eq 'new'
  end

  it 'rejects a duplicate name' do
    create(:folder_tag, name: 'dup')
    expect { post folder_tags_path, params: { folder_tag: { name: 'dup' } } }.not_to change(FolderTag, :count)
  end

  it 'renames a tag, keeping its taggings' do
    tag = create(:folder_tag, name: 'old')
    sf = create(:scan_folder, folder_tags: [tag])
    patch folder_tag_path(tag), params: { folder_tag: { name: 'renamed' } }
    expect(tag.reload.name).to eq 'renamed'
    expect(sf.reload.folder_tags).to eq [tag]
  end

  it 'deletes a tag and all its taggings' do
    tag = create(:folder_tag)
    other = create(:folder_tag)
    sf = create(:scan_folder, folder_tags: [tag, other])
    expect { delete folder_tag_path(tag) }.to change(FolderTagging, :count).by(-1)
    expect(FolderTag.exists?(tag.id)).to be false
    expect(sf.reload.folder_tags).to eq [other]
  end

  it 'forces a scan of the raw ingestion folder' do
    allow(SyncScanFolders).to receive(:call).and_return(2)
    post sync_scan_folders_path
    expect(SyncScanFolders).to have_received(:call)
    expect(response).to redirect_to(scan_folders_path)
  end
end
