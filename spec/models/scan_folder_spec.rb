require 'rails_helper'

RSpec.describe ScanFolder, type: :model do
  before do
    allow(ScanStorage).to receive(:list_files).and_return([{ name: 'a.jpg', size: 100 }, { name: 'b.pdf', size: 250 }])
  end

  it 'defaults to raw and validates status and unique name' do
    sf = create(:scan_folder)
    expect(sf.status).to eq 'raw'
    expect(build(:scan_folder, name: sf.name)).not_to be_valid
    expect(build(:scan_folder, status: 'bogus')).not_to be_valid
  end

  it 'reports file count and total size from storage' do
    sf = build(:scan_folder)
    expect(sf.file_count).to eq 2
    expect(sf.total_size).to eq 350
  end

  describe '.tagged_with_all' do
    it 'ANDs the given tags' do
      x = create(:folder_tag)
      y = create(:folder_tag)
      both = create(:scan_folder, folder_tags: [x, y])
      only_x = create(:scan_folder, folder_tags: [x])
      create(:scan_folder)
      expect(ScanFolder.tagged_with_all([x.id, y.id])).to eq [both]
      expect(ScanFolder.tagged_with_all([x.id])).to match_array [both, only_x]
      expect(ScanFolder.tagged_with_all([])).to match_array ScanFolder.all
    end
  end

  describe '.name_like' do
    it 'filters by substring, escaping wildcards' do
      a = create(:scan_folder, name: 'abc_def')
      create(:scan_folder, name: 'abcxdef')
      expect(ScanFolder.name_like('c_d')).to eq [a]
    end
  end

  it 'computes expiration from year of death' do
    expect(ScanFolder.expiration_from_death_year('1950')).to eq 2021
    expect(ScanFolder.expiration_from_death_year('')).to be_nil
  end

  it 'creates and reuses tags by name' do
    existing = create(:folder_tag, name: 'old')
    sf = create(:scan_folder)
    sf.tag_names = ['old', ' new ', '']
    expect(sf.folder_tags.map(&:name)).to match_array %w[old new]
    expect(FolderTag.where(name: 'old')).to eq [existing]
  end

  it 'postpones with expiration year and tags' do
    sf = create(:scan_folder)
    sf.postpone!(expiration_year: 2030, tag_names: ['t1'])
    sf.reload
    expect([sf.status, sf.copyright_expiration_year, sf.folder_tags.map(&:name)]).to eq ['postponed', 2030, ['t1']]
  end

  it 'only approves or postpones raw folders, even from a stale form' do
    sf = create(:scan_folder)
    stale = ScanFolder.find(sf.id)
    sf.mark_complete!(create(:task)) rescue sf.update!(status: 'complete', task_id: 1, completed_at: Time.zone.now)
    expect { stale.postpone!(expiration_year: 2030) }.to raise_error(ScanFolder::InvalidState)
    expect { stale.approve! }.to raise_error(ScanFolder::InvalidState)
    expect(sf.reload.status).to eq 'complete'
    expect(sf.task_id).to be_present
  end

  it 'archives by deleting stored files' do
    sf = create(:scan_folder, status: 'complete')
    expect(ScanStorage).to receive(:delete_direct_files).with(sf.name)
    sf.archive!
    expect(sf.reload.status).to eq 'archived'
  end
end
