require 'rails_helper'

RSpec.describe 'Image Cropping Modal', type: :system, js: true do
  it 'modal fits within viewport and does not overflow' do
    # Create a simple test page with the modal HTML
    test_html = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <link rel="stylesheet" href="https://code.jquery.com/ui/1.9.2/themes/redmond/jquery-ui.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.css">
        <script src="https://code.jquery.com/jquery-1.9.1.min.js"></script>
        <script src="https://code.jquery.com/ui/1.9.2/jquery-ui.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.js"></script>
        <style>
          body { margin: 0; padding: 20px; }
        </style>
      </head>
      <body>
        <button id="test-open-modal">Open Crop Modal</button>

        <div id="image-crop-modal" title="Crop Image" style="display:none;">
          <div class="crop-container" style="overflow: hidden;">
            <img id="crop-image" src="https://via.placeholder.com/2000x3000.jpg" style="display: block; max-width: 100%;">
          </div>
          <div class="crop-buttons" style="margin-top: 10px; text-align: center;">
            <button id="download-cropped">Download</button>
            <button id="cancel-crop" style="margin-left: 10px;">Cancel</button>
          </div>
        </div>

        <script>
          var cropper;

          jQuery(document).ready(function() {
            // Calculate optimal modal size based on viewport
            var viewportWidth = jQuery(window).width();
            var viewportHeight = jQuery(window).height();
            var modalWidth = Math.floor(viewportWidth * 0.95);
            var modalHeight = Math.min(Math.floor(viewportHeight * 0.8), viewportHeight - 100);

            jQuery('#image-crop-modal').dialog({
              draggable: true,
              modal: true,
              resizable: true,
              autoOpen: false,
              position: { my: 'center', at: 'center', of: window },
              width: modalWidth,
              height: modalHeight,
              close: function() {
                if (cropper) {
                  cropper.destroy();
                  cropper = null;
                }
              }
            });

            jQuery('#test-open-modal').click(function() {
              jQuery('#image-crop-modal').dialog('open');

              setTimeout(function() {
                if (cropper) {
                  cropper.destroy();
                }
                var image = document.getElementById('crop-image');

                // Calculate available height for image (modal height - buttons - title bar - padding)
                var modalHeight = jQuery('#image-crop-modal').dialog('option', 'height');
                var buttonsHeight = jQuery('.crop-buttons').outerHeight(true) || 60;
                var titleBarHeight = jQuery('#image-crop-modal').prev('.ui-dialog-titlebar').outerHeight(true) || 40;
                var availableHeight = modalHeight - buttonsHeight - titleBarHeight - 40; // 40px for padding

                // Set container dimensions to prevent scrolling
                jQuery('.crop-container').css({
                  'max-height': availableHeight + 'px',
                  'height': availableHeight + 'px'
                });

                cropper = new Cropper(image, {
                  aspectRatio: NaN,
                  viewMode: 1,
                  background: false,
                  autoCropArea: 0.8,
                  responsive: true,
                  restore: true,
                  checkCrossOrigin: false,
                  ready: function() {
                    // Ensure cropper fits within container
                    var containerData = cropper.getContainerData();
                    if (containerData.height > availableHeight) {
                      jQuery('.crop-container').height(availableHeight);
                    }
                  }
                });
              }, 300);
            });

            jQuery('#cancel-crop').click(function() {
              jQuery('#image-crop-modal').dialog('close');
            });
          });
        </script>
      </body>
      </html>
    HTML

    # Write the test HTML to a file
    test_file = Rails.root.join('tmp', 'test_modal.html')
    File.write(test_file, test_html)

    # Visit the test page
    visit "file://#{test_file}"

    # Click to open modal
    find('#test-open-modal').click

    # Wait for modal to open and cropper to initialize
    sleep 1

    # Get viewport dimensions
    viewport_width = page.execute_script('return window.innerWidth')
    viewport_height = page.execute_script('return window.innerHeight')

    # Get modal dialog element
    dialog_width = page.execute_script('return jQuery("#image-crop-modal").parent(".ui-dialog").outerWidth()')
    dialog_height = page.execute_script('return jQuery("#image-crop-modal").parent(".ui-dialog").outerHeight()')

    # Get dialog position
    dialog_top = page.execute_script('return jQuery("#image-crop-modal").parent(".ui-dialog").offset().top')
    dialog_left = page.execute_script('return jQuery("#image-crop-modal").parent(".ui-dialog").offset().left')
    dialog_bottom = dialog_top + dialog_height
    dialog_right = dialog_left + dialog_width

    puts "\n=== Viewport ==="
    puts "Viewport: #{viewport_width}x#{viewport_height}"
    puts "\n=== Dialog Dimensions ==="
    puts "Dialog size: #{dialog_width}x#{dialog_height}"
    puts "Dialog position: top=#{dialog_top}, left=#{dialog_left}"
    puts "Dialog bounds: bottom=#{dialog_bottom}, right=#{dialog_right}"

    # Check modal fits within viewport
    expect(dialog_width).to be <= viewport_width,
      "Modal width (#{dialog_width}px) exceeds viewport width (#{viewport_width}px)"
    expect(dialog_height).to be <= viewport_height,
      "Modal height (#{dialog_height}px) exceeds viewport height (#{viewport_height}px)"

    # Check modal is not cut off at edges
    expect(dialog_top).to be >= 0,
      "Modal top (#{dialog_top}px) is above viewport"
    expect(dialog_left).to be >= 0,
      "Modal left (#{dialog_left}px) is left of viewport"
    expect(dialog_bottom).to be <= viewport_height,
      "Modal bottom (#{dialog_bottom}px) exceeds viewport height (#{viewport_height}px)"
    expect(dialog_right).to be <= viewport_width,
      "Modal right (#{dialog_right}px) exceeds viewport width (#{viewport_width}px)"

    # Check for scrollbars
    has_vertical_scroll = page.execute_script(<<-JS)
      var modal = jQuery("#image-crop-modal").get(0);
      return modal.scrollHeight > modal.clientHeight;
    JS

    has_horizontal_scroll = page.execute_script(<<-JS)
      var modal = jQuery("#image-crop-modal").get(0);
      return modal.scrollWidth > modal.clientWidth;
    JS

    puts "\n=== Scroll Check ==="
    puts "Has vertical scroll: #{has_vertical_scroll}"
    puts "Has horizontal scroll: #{has_horizontal_scroll}"

    expect(has_vertical_scroll).to be_falsey, "Modal should not have vertical scrollbar"
    expect(has_horizontal_scroll).to be_falsey, "Modal should not have horizontal scrollbar"

    # Get container and image dimensions
    container_height = page.execute_script('return jQuery(".crop-container").outerHeight()')
    image_height = page.execute_script('return jQuery("#crop-image").outerHeight()')

    # Check if cropper initialized
    cropper_exists = page.execute_script('return typeof cropper !== "undefined" && cropper !== null')
    cropper_ready = page.execute_script('return cropper && cropper.ready === true')

    # Get cropper container data if it exists
    if cropper_exists
      cropper_container = page.execute_script('return cropper ? cropper.getContainerData() : null')
      puts "\n=== Cropper Info ==="
      puts "Cropper exists: #{cropper_exists}"
      puts "Cropper ready: #{cropper_ready}"
      if cropper_container
        puts "Cropper container: #{cropper_container['width']}x#{cropper_container['height']}"
      end
    end

    puts "\n=== Content Dimensions ==="
    puts "Container height: #{container_height}px"
    puts "Image height: #{image_height}px"

    # Verify cropper initialized properly
    expect(cropper_exists).to be_truthy, "Cropper should be initialized"

    # Verify container has reasonable dimensions
    expect(container_height).to be > 400, "Container should have reasonable height (got #{container_height}px)"

    # Clean up
    File.delete(test_file) if File.exist?(test_file)
  end
end
