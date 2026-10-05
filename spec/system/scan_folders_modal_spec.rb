require 'rails_helper'

RSpec.describe 'Scan folder thumbnails modal', type: :system, js: true do
  let(:admin) { create(:user, :admin, :active_user) }
  let!(:folder) { create(:scan_folder, name: 'modal-folder') }

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
    ScanStorage.upload('modal-folder', 'a.png', StringIO.new(`convert -size 400x200 xc:red png:-`))
  end

  it 'is centered in the viewport and fits inside it' do
    visit scan_folders_path
    click_link 'modal-folder'
    expect(page).to have_css('.scan-modal-content')
    rect = page.evaluate_script("(function(){var r=document.querySelector('#scan-modal').parentNode.getBoundingClientRect();" \
                                'return [r.top, r.bottom, r.left, r.right, document.documentElement.clientWidth, document.documentElement.clientHeight]})()')
    top, bottom, left, right, w, h = rect
    expect(top).to be >= 0
    expect(bottom).to be <= h
    expect((left + right) / 2.0).to be_within(5).of(w / 2.0)
    expect((top + bottom) / 2.0).to be_within(5).of(h / 2.0)
  end

  it 'scrolls with PageDown after clicking on a tile' do
    %w(b c d).each { |n| ScanStorage.upload('modal-folder', "#{n}.png", StringIO.new(`convert -size 400x200 xc:red png:-`)) }
    visit scan_folders_path
    click_link 'modal-folder'
    expect(page).to have_css('.bigthumb', minimum: 4)
    find(".bigthumb img", match: :first).click
    expect(page.evaluate_script("document.activeElement.id")).to eq "scan-modal"
    page.send_keys(:page_down)
    expect(page).to have_css('#scan-modal') # let scroll settle
    sleep 0.5
    expect(page.evaluate_script("document.querySelector('#scan-modal').scrollTop")).to be > 0
  end

  it 'performs the crop when Enter is pressed' do
    visit scan_folders_path
    click_link 'modal-folder'
    find('.crop-file').click
    expect(page).to have_css('#crop-pane .cropper-container')
    page.send_keys(:enter)
    expect(page).to have_no_css('#crop-pane')
    img = MiniMagick::Image.read(ScanStorage.read('modal-folder', 'a.png'))
    expect([img.width, img.height]).not_to eq [400, 200] # full-image auto-crop box is smaller than original
  end
end
