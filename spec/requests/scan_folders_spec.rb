require 'rails_helper'

RSpec.describe 'ScanFolders', type: :request do
  let(:admin) { create(:user, :admin, :active_user) }
  let(:current) { admin }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current)
    allow(ScanStorage).to receive(:list_files).and_return([{ name: 'a.jpg', size: 1000 }])
    allow(ScanStorage).to receive(:presigned_url).and_return('https://s3.example/x?sig=1')
  end

  context 'as a non-admin editor' do
    let(:current) { create(:user, :editor, :active_user) }

    it 'is denied' do
      get scan_folders_path
      expect(response).to redirect_to('/')
      post approve_scan_folder_path(create(:scan_folder))
      expect(response).to redirect_to('/')
    end
  end

  describe 'GET /scan_folders' do
    it 'lists and filters by status, name and ANDed tags' do
      x = create(:folder_tag)
      y = create(:folder_tag)
      create(:scan_folder, name: 'both-folder', folder_tags: [x, y])
      create(:scan_folder, name: 'x-folder', folder_tags: [x])
      create(:scan_folder, name: 'approved-one', status: 'approved')

      get scan_folders_path
      expect(response.body).to include('both-folder', 'x-folder', 'approved-one')
      get scan_folders_path, params: { tag_ids: [x.id, y.id] }
      expect(response.body).to include('both-folder')
      expect(response.body).not_to include('x-folder')
      get scan_folders_path, params: { status: 'approved' }
      expect(response.body).to include('approved-one')
      expect(response.body).not_to include('both-folder')
      get scan_folders_path, params: { q: 'x-fol' }
      expect(response.body).to include('x-folder')
      expect(response.body).not_to include('approved-one')
    end
  end

  describe 'GET /scan_folders size column' do
    it 'abbreviates megabytes with a double quote even if the global unit translation differs' do
      folder = create(:scan_folder, name: 'sized')
      allow_any_instance_of(ScanFolder).to receive(:total_size).and_return(5_000_000)
      get scan_folders_path
      expect(CGI.unescapeHTML(response.body)).to include('4.77 מ"ב')
      expect(response.body).not_to include('מ\\ב')
      expect(folder).to be_persisted
    end
  end

  describe 'POST /scan_folders' do
    let(:file) { fixture_file_upload('spec/fixtures/files/scan.jpg', 'image/jpeg') }

    after { FileUtils.rm_rf(ScanStorage::DiskBackend.root) }

    it 'does not touch an existing folder of the same name when a second upload is rejected' do
      ScanStorage.upload('dup', 'orig.jpg', StringIO.new('keep'))
      create(:scan_folder, name: 'dup')
      post scan_folders_path, params: { name: 'dup', files: [file] }
      expect(ScanStorage.list_objects(ScanStorage.folder_prefix('dup')).map { |o| File.basename(o[:key]) }).to eq ['orig.jpg']
      expect(ScanFolder.where(name: 'dup').count).to eq 1
    end

    def upload_named(name)
      Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/scan.jpg'), 'image/jpeg', original_filename: name)
    end

    it 'does not lose files or duplicate the row when discovery runs mid-upload, and is not actionable until done' do
      statuses = []
      calls = 0
      allow(ScanStorage).to receive(:upload).and_wrap_original do |m, *args, **kw|
        m.call(*args, **kw)
        if (calls += 1) == 1
          SyncScanFolders.call
          statuses << ScanFolder.find_by(name: 'racing').status
        end
      end
      post scan_folders_path, params: { name: 'racing', files: [upload_named('1.jpg'), upload_named('2.jpg')] }
      expect(statuses).to eq ['uploading']
      expect(ScanFolder.where(name: 'racing').count).to eq 1
      expect(ScanFolder.find_by(name: 'racing').status).to eq 'raw'
      expect(ScanStorage.list_objects(ScanStorage.folder_prefix('racing')).size).to eq 2
    end

    it 'rejects duplicate file names instead of silently overwriting one' do
      post scan_folders_path, params: { name: 'dupnames', files: [upload_named('x.jpg'), upload_named('x.jpg')] }
      expect(ScanFolder.where(name: 'dupnames')).to be_empty
      expect(ScanStorage.list_objects(ScanStorage.folder_prefix('dupnames'))).to be_empty
      expect(CGI.unescapeHTML(response.body)).to include(I18n.t('scans.duplicate_filenames'))
    end

    it 'cleans up partial uploads when a later file fails' do
      calls = 0
      allow(ScanStorage).to receive(:upload).and_wrap_original do |m, *args, **kw|
        calls += 1
        raise 'boom' if calls == 2

        m.call(*args, **kw)
      end
      expect { post scan_folders_path, params: { name: 'partial', files: [upload_named('1.jpg'), upload_named('2.jpg')] } }.to raise_error(RuntimeError, 'boom')
      expect(ScanStorage.list_objects(ScanStorage.folder_prefix('partial'))).to be_empty
      expect(ScanFolder.where(name: 'partial')).to be_empty
    end

    it 'rejects files too large to become documents' do
      stub_const('ScanFolder::MAX_FILE_SIZE', 1.byte)
      post scan_folders_path, params: { name: 'bigfolder', files: [file] }
      expect(ScanFolder.where(name: 'bigfolder')).to be_empty
      expect(CGI.unescapeHTML(response.body)).to include(I18n.t('scans.files_too_large'))
    end

    before do
      FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
      File.binwrite(Rails.root.join('spec/fixtures/files/scan.jpg'), 'x') unless File.exist?(Rails.root.join('spec/fixtures/files/scan.jpg'))
    end

    it 'creates a raw folder and uploads files' do
      expect(ScanStorage).to receive(:upload).with('newf', 'scan.jpg', anything, anything)
      post scan_folders_path, params: { name: 'newf', comment: 'hi', files: [file] }
      sf = ScanFolder.find_by(name: 'newf')
      expect([sf.status, sf.comment]).to eq %w[raw hi]
    end

    it 'rejects a duplicate name' do
      create(:scan_folder, name: 'newf')
      expect(ScanStorage).not_to receive(:upload)
      expect { post scan_folders_path, params: { name: 'newf', files: [file] } }.not_to change(ScanFolder, :count)
    end
  end

  describe 'workflow actions' do
    it 'flashes instead of failing when approving or postponing a folder that already moved on' do
      sf = create(:scan_folder, status: 'approved')
      post approve_scan_folder_path(sf)
      expect(response).to redirect_to(scan_folders_path)
      expect(flash[:error]).to eq I18n.t('scans.invalid_state')
      post postpone_scan_folder_path(sf), params: { expiration_year: 2030 }
      expect(flash[:error]).to eq I18n.t('scans.invalid_state')
      expect(sf.reload.status).to eq 'approved'
    end

    it 'approves a raw folder' do
      sf = create(:scan_folder)
      post approve_scan_folder_path(sf)
      expect(sf.reload.status).to eq 'approved'
    end

    it 'postpones with year-of-death fallback and tags' do
      existing = create(:folder_tag, name: 'old')
      sf = create(:scan_folder)
      post postpone_scan_folder_path(sf), params: { expiration_year: '', year_of_death: '1960',
                                                    tag_ids: [existing.id], new_tags: 'fresh, other' }
      sf.reload
      expect(sf.status).to eq 'postponed'
      expect(sf.copyright_expiration_year).to eq 2031
      expect(sf.folder_tags.map(&:name)).to match_array %w[old fresh other]
    end

    it 'creates a typing task with documents in natural order and completes the folder' do
      allow(ScanStorage).to receive(:list_files)
        .and_return([{ name: 'file1.jpg', size: 1 }, { name: 'file2.jpg', size: 1 }, { name: 'file11.jpg', size: 1 }])
      allow(ScanStorage).to receive(:read).and_return('data')
      allow_any_instance_of(Document).to receive(:save).and_return(true)
      allow(Document).to receive(:create!) { |attrs| attrs }
      sf = create(:scan_folder, status: 'approved')
      post create_task_scan_folder_path(sf), params: { title: 'T', author: 'A' }
      sf.reload
      task = Task.find(sf.task_id)
      expect(task.name).to eq 'T / A'
      expect(task.kind_id).to eq 'הקלדה'
      expect(sf.status).to eq 'complete'
      expect(Document).to have_received(:create!).exactly(3).times
    end

    it 'refuses a second conversion and non-approved folders' do
      allow(ScanStorage).to receive(:list_files).and_return([])
      done = create(:scan_folder, status: 'approved')
      post create_task_scan_folder_path(done), params: { title: 'T', author: 'A' }
      expect { post create_task_scan_folder_path(done), params: { title: 'T', author: 'A' } }.not_to change(Task, :count)
      raw = create(:scan_folder, status: 'raw')
      expect { post create_task_scan_folder_path(raw), params: { title: 'T', author: 'A' } }.not_to change(Task, :count)
      expect(raw.reload.task_id).to be_nil
    end

    it 'refuses folders with files too large for a Document, before creating a task' do
      allow(ScanStorage).to receive(:list_files).and_return([{ name: 'big.jpg', size: 51.megabytes }])
      sf = create(:scan_folder, status: 'approved')
      expect { post create_task_scan_folder_path(sf), params: { title: 'T', author: 'A' } }.not_to change(Task, :count)
      expect(flash[:error]).to include('big.jpg')
    end

    it 'requires title and author' do
      sf = create(:scan_folder, status: 'approved')
      expect { post create_task_scan_folder_path(sf), params: { title: '', author: '' } }.not_to change(Task, :count)
      expect(sf.reload.status).to eq 'approved'
    end
  end

  describe 'file actions' do
    let(:sf) { create(:scan_folder) }

    it 'GET show renders the modal with thumbnails' do
      get scan_folder_path(sf)
      expect(response.body).to include('a.jpg', 'rotate-file', 'crop-file', 'delete-file')
    end

    it 'shows TIFFs through the JPEG preview and serves it' do
      sf = create(:scan_folder)
      allow(ScanStorage).to receive(:list_files).and_return([{ name: 'a.tif', size: 1 }])
      allow(ScanStorage).to receive(:presigned_url).and_return('/orig/a.tif')
      allow(ScanStorage).to receive(:preview).with(sf.name, 'a.tif').and_return('jpegdata')
      get scan_folder_path(sf)
      expect(response.body).to include("src='#{preview_scan_folder_path(sf, filename: 'a.tif')}".sub(/\?.*/, ''))
      get preview_scan_folder_path(sf, filename: 'a.tif')
      expect([response.media_type, response.body]).to eq ['image/jpeg', 'jpegdata']
    end

    it 'deletes, rotates and crops only by base filename' do
      expect(ScanStorage).to receive(:delete_file).with(sf.name, 'passwd')
      delete delete_file_scan_folder_path(sf), params: { filename: '../../passwd' }
      expect(ScanStorage).to receive(:rotate).with(sf.name, 'a.jpg')
      post rotate_file_scan_folder_path(sf), params: { filename: 'a.jpg' }
      expect(ScanStorage).to receive(:crop).with(sf.name, 'a.jpg', x: '1', y: '2', width: '3', height: '4')
      post crop_file_scan_folder_path(sf), params: { filename: 'a.jpg', x: 1, y: 2, width: 3, height: 4 }
      expect(response).to have_http_status(:success)
    end

    it 'saves title and author' do
      patch scan_folder_path(sf), params: { title: 'Tt', author: 'Au' }
      expect([sf.reload.title, sf.author]).to eq %w[Tt Au]
    end
  end
end

RSpec.describe 'ScanFolders disk file serving', type: :request do
  let(:admin) { create(:user, :admin, :active_user) }

  around do |ex|
    old = ScanStorage.instance_variable_get(:@backend)
    ScanStorage.backend = ScanStorage::DiskBackend.new
    ex.run
    FileUtils.rm_rf(ScanStorage::DiskBackend.root)
    ScanStorage.backend = old
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
  end

  it 'uploads via the form and serves the stored file' do
    file = fixture_file_upload('spec/fixtures/files/scan.jpg', 'image/jpeg')
    post scan_folders_path, params: { name: 'disk1', files: [file] }
    expect(ScanFolder.find_by(name: 'disk1')).to be_present
    get file_scan_folders_path(folder: 'disk1', filename: 'scan.jpg')
    expect(response).to have_http_status(:success)
    get file_scan_folders_path(folder: '..', filename: 'passwd')
    expect(response).to have_http_status(:not_found)
  end
end
