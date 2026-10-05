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

  it 'deletes only a folder\'s direct files, leaving nested folders alone' do
    ScanStorage.upload('A', 'a.jpg', StringIO.new('1'))
    ScanStorage.upload('A/B', 'b.jpg', StringIO.new('2'))
    ScanStorage.delete_direct_files('A')
    expect(ScanStorage.list_files('A')).to be_empty
    expect(ScanStorage.list_files('A/B').size).to eq 1
  end

  it 'renders a JPEG preview of a TIFF with the same dimensions' do
    Tempfile.create(['p', '.tif']) do |f|
      MiniMagick::Tool::Convert.new { |c| c.size '40x20'; c << 'xc:red'; c << f.path }
      ScanStorage.upload('t', 'p.tif', StringIO.new(File.binread(f.path)))
    end
    img = MiniMagick::Image.read(ScanStorage.preview('t', 'p.tif'))
    expect([img.type, img.width, img.height]).to eq ['JPEG', 40, 20]
  end

  it 'rejects an unsupported SCAN_STORAGE value rather than falling back to disk' do
    ScanStorage.backend = nil
    stub_const('ENV', ENV.to_hash.merge('SCAN_STORAGE' => 's33'))
    expect { ScanStorage.backend }.to raise_error(ArgumentError, /s33/)
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
