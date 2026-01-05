require 'rails_helper'

RSpec.describe 'Image Cropping', type: :system, js: true do
  let(:user) { create(:user, :volunteer, :active_user) }
  let(:task) { create(:task, assignee: user) }
  let(:image_document) do
    create(:document,
           task: task,
           user: user,
           file_file_name: 'test_image.jpg',
           file_file_size: 1024)
  end

  before do
    # Mock S3 URL for the image
    allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('https://via.placeholder.com/2000x3000.jpg')

    # Mock authentication - bypass auth checks
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(TasksController).to receive(:require_task_participant_or_editor).and_return(true)
  end

  it 'displays crop modal that fits within viewport' do
    # Visit the task page
    visit "/tasks/#{task.id}"

    # Wait for page to load
    expect(page).to have_content(task.name)

    # Click the crop link
    find('.crop-image-link').click

    # Wait for modal to open
    expect(page).to have_css('#image-crop-modal', visible: true)

    # Get viewport dimensions
    viewport_width = page.execute_script('return window.innerWidth')
    viewport_height = page.execute_script('return window.innerHeight')

    # Get modal dimensions
    modal_width = page.execute_script('return jQuery("#image-crop-modal").dialog("option", "width")')
    modal_height = page.execute_script('return jQuery("#image-crop-modal").dialog("option", "height")')

    # Get actual rendered dialog element
    dialog_element = page.execute_script('return jQuery("#image-crop-modal").parent(".ui-dialog").get(0)')
    actual_width = page.execute_script('return arguments[0].offsetWidth', dialog_element)
    actual_height = page.execute_script('return arguments[0].offsetHeight', dialog_element)

    puts "\n=== Viewport Dimensions ==="
    puts "Viewport: #{viewport_width}x#{viewport_height}"
    puts "\n=== Modal Dimensions ==="
    puts "Modal (configured): #{modal_width}x#{modal_height}"
    puts "Dialog (actual): #{actual_width}x#{actual_height}"

    # Check if modal fits within viewport (with some margin)
    expect(actual_width).to be <= viewport_width,
      "Modal width (#{actual_width}px) should be less than viewport width (#{viewport_width}px)"
    expect(actual_height).to be <= viewport_height,
      "Modal height (#{actual_height}px) should be less than viewport height (#{viewport_height}px)"

    # Get crop container dimensions
    container_height = page.execute_script('return jQuery(".crop-container").height()')
    container_max_height = page.execute_script('return parseInt(jQuery(".crop-container").css("max-height"))')

    puts "\n=== Crop Container ==="
    puts "Container height: #{container_height}px"
    puts "Container max-height: #{container_max_height}px"

    # Check that the image container doesn't overflow
    image_element = page.find('#crop-image', visible: :all)
    image_height = page.evaluate_script("document.getElementById('crop-image').offsetHeight")

    puts "\n=== Image Element ==="
    puts "Image height: #{image_height}px"

    # Check for scrollbars (indicates overflow)
    has_scroll = page.execute_script(<<-JS)
      var modal = jQuery("#image-crop-modal").get(0);
      return modal.scrollHeight > modal.clientHeight || modal.scrollWidth > modal.clientWidth;
    JS

    puts "\n=== Overflow Check ==="
    puts "Has scroll: #{has_scroll}"

    expect(has_scroll).to be_falsey, "Modal should not have scrollbars (indicating overflow)"
  end

  it 'modal buttons are visible and clickable' do
    visit "/tasks/#{task.id}"

    find('.crop-image-link').click

    # Wait for modal
    expect(page).to have_css('#image-crop-modal', visible: true)

    # Check buttons are visible
    expect(page).to have_button(I18n.t('documents.download_cropped_image'))
    expect(page).to have_button(I18n.t('common.cancel'))

    # Get button position
    button_top = page.execute_script('return jQuery("#download-cropped").offset().top')
    viewport_height = page.execute_script('return window.innerHeight')

    puts "\n=== Button Position ==="
    puts "Button top: #{button_top}px"
    puts "Viewport height: #{viewport_height}px"

    # Buttons should be within viewport
    expect(button_top).to be < viewport_height,
      "Buttons should be visible within viewport"
  end
end
