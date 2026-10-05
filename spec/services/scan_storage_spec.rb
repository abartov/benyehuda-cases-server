require 'rails_helper'

RSpec.describe ScanStorage do
  let(:client) { Aws::S3::Client.new(stub_responses: true, region: 'us-east-1') }

  before { described_class.client = client }
  after { described_class.client = nil }

  def stub_keys(*keys)
    client.stub_responses(:list_objects_v2, contents: keys.map { |k| { key: "raw_scans/#{k}", size: 10 } },
                                            is_truncated: false)
  end

  it 'sorts naturally' do
    stub_keys('f/file11.jpg', 'f/file2.jpg', 'f/file1.jpg', 'f/notes.txt', 'f/sub/x.jpg')
    expect(described_class.list_files('f').map { |f| f[:name] }).to eq %w[file1.jpg file2.jpg file11.jpg]
  end

  it 'discovers folders holding scans with their ancestors' do
    stub_keys('עם עובד/A/1.jpg', 'עם עובד/B/1.pdf', 'עם עובד/readme.txt', 'solo/1.png')
    expect(described_class.discover_folders).to match_array [['עם עובד/A', ['עם עובד']], ['עם עובד/B', ['עם עובד']],
                                                             ['solo', []]]
  end

  it 'deletes a folder' do
    stub_keys('f/1.jpg', 'f/2.jpg')
    expect(client).to receive(:delete_objects).and_call_original
    described_class.delete_folder('f')
  end

  it 'refuses to rotate non-images' do
    expect { described_class.rotate('f', 'a.pdf') }.to raise_error(ArgumentError)
  end
end
