require 'rails_helper'

RSpec.describe ScanStorage::DiskBackend do
  around do |ex|
    old = ScanStorage.instance_variable_get(:@backend)
    ScanStorage.backend = described_class.new
    ex.run
    FileUtils.rm_rf(described_class.root)
    ScanStorage.backend = old
  end

  it 'round-trips upload, list, read, delete' do
    ScanStorage.upload('f', 'file2.jpg', StringIO.new('b'))
    ScanStorage.upload('f', 'file10.jpg', StringIO.new('cc'))
    ScanStorage.upload('g', 'x.jpg', StringIO.new('d'))
    expect(ScanStorage.list_files('f').map { |x| [x[:name], x[:size]] }).to eq [['file2.jpg', 1], ['file10.jpg', 2]]
    expect(ScanStorage.read('f', 'file2.jpg')).to eq 'b'
    expect(ScanStorage.folder_exists?('f')).to be true
    ScanStorage.delete_file('f', 'file2.jpg')
    expect(ScanStorage.list_files('f').size).to eq 1
    ScanStorage.delete_folder('f')
    expect(ScanStorage.folder_exists?('f')).to be false
    expect(ScanStorage.folder_exists?('g')).to be true
  end

  it 'refuses keys escaping the root' do
    expect { described_class.new.path_for('../../etc/passwd') }.to raise_error(ArgumentError)
  end

  it 'builds a servable url' do
    ScanStorage.upload('a b', 'p.jpg', StringIO.new('x'))
    expect(ScanStorage.presigned_url('a b', 'p.jpg')).to start_with('/scan_folders/file?')
    expect(ScanStorage.disk_path('a b', 'p.jpg')).to be_file
  end
end
