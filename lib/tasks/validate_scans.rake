desc "Validate scanned page sequence for gaps and duplicates"
task :validate_scans, [:scan_dir] => :environment do |taskname, args|
  # Set default directory if not specified
  scan_dir = args[:scan_dir] || 'tmp/scans/'

  # Ensure directory exists
  unless Dir.exist?(scan_dir)
    puts "Error: Directory '#{scan_dir}' does not exist"
    exit 1
  end

  # Supported image formats
  image_extensions = %w[.jpg .jpeg .png .JPG .JPEG .PNG]

  puts "Scanning directory: #{scan_dir}"
  puts "Looking for image files..."

  # Find all image files
  image_files = Dir.glob(File.join(scan_dir, '*')).select do |file|
    image_extensions.include?(File.extname(file))
  end

  if image_files.empty?
    puts "No image files found in #{scan_dir}"
    exit 0
  end

  puts "Found #{image_files.length} image files"
  puts "Extracting page numbers..."

  # Store results: filename => page_number (or nil if unknown)
  results = {}

  image_files.sort.each_with_index do |filepath, index|
    filename = File.basename(filepath)
    print "  [#{index + 1}/#{image_files.length}] Processing #{filename}... "

    page_number = extract_page_number(filepath)
    results[filename] = page_number

    if page_number
      puts "page #{page_number}"
    else
      puts "unknown"
    end
  end

  puts "\nAnalyzing sequence..."

  # Separate known and unknown pages
  known_pages = results.select { |_, page| !page.nil? }
  unknown_pages = results.select { |_, page| page.nil? }

  # Check for duplicates
  duplicates = known_pages.group_by { |_, page| page }
                          .select { |_, files| files.length > 1 }

  # Sort known pages by page number
  sorted_pages = known_pages.sort_by { |_, page| page }

  # Try to fill in unknown pages
  inferred_pages = infer_unknown_pages(results, sorted_pages)

  # Check for gaps
  all_pages = (known_pages.merge(inferred_pages)).sort_by { |_, page| page }
  gaps = find_gaps(all_pages.map { |_, page| page })

  # Generate report
  generate_report(results, inferred_pages, duplicates, gaps, scan_dir)

  puts "\nReport generated: page_validation_output.txt"
end

# Extract page number from image using OCR
def extract_page_number(filepath)
  begin
    # Try multiple strategies to find page numbers
    page_number = nil

    # Strategy 1: OCR on full image
    page_number = ocr_region(filepath, nil)
    return page_number if page_number

    # Strategy 2: OCR on top 15% of image (common for page numbers)
    page_number = ocr_region(filepath, 'top')
    return page_number if page_number

    # Strategy 3: OCR on bottom 15% of image (also common for page numbers)
    page_number = ocr_region(filepath, 'bottom')
    return page_number if page_number

    nil
  rescue => e
    # If OCR fails, return nil
    nil
  end
end

# Perform OCR on a specific region of the image
def ocr_region(filepath, region = nil)
  temp_image = nil
  temp_output = "/tmp/ocr_output_#{Process.pid}_#{Time.now.to_i}_#{rand(10000)}.txt"

  begin
    if region
      # Get image dimensions and extract region
      temp_image = "/tmp/crop_#{Process.pid}_#{Time.now.to_i}_#{rand(10000)}.jpg"

      case region
      when 'top'
        # Extract top 15% of image
        system("convert '#{filepath}' -gravity North -crop 100%x15%+0+0 +repage '#{temp_image}' 2>/dev/null")
      when 'bottom'
        # Extract bottom 15% of image
        system("convert '#{filepath}' -gravity South -crop 100%x15%+0+0 +repage '#{temp_image}' 2>/dev/null")
      end

      ocr_file = temp_image
    else
      ocr_file = filepath
    end

    # Run tesseract with settings optimized for finding page numbers
    # PSM 6 = assume a single uniform block of text
    # PSM 7 = treat the image as a single text line
    system("tesseract '#{ocr_file}' '#{temp_output.gsub('.txt', '')}' -l heb+eng --psm 7 2>/dev/null")

    # Read the OCR output
    if File.exist?(temp_output)
      text = File.read(temp_output)
      File.delete(temp_output)

      # Look for Arabic numerals (most common in printed books)
      # Find all numbers that could be page numbers
      numbers = text.scan(/\b\d+\b/).map(&:to_i).select { |n| n > 0 && n < 10000 }

      # Filter out numbers that are too large or too small to be page numbers
      # Prefer numbers in reasonable page number range (1-9999)
      page_candidates = numbers.select { |n| n >= 1 && n <= 9999 }

      # If we found page numbers, prefer smaller ones (more likely to be page numbers)
      # and avoid very large numbers (might be ISBNs, dates, etc.)
      if page_candidates.any?
        # Prefer numbers under 1000 (typical book length)
        small_candidates = page_candidates.select { |n| n < 1000 }
        return small_candidates.first if small_candidates.any?
        return page_candidates.first
      end
    end

    nil
  ensure
    # Clean up temporary files
    File.delete(temp_image) if temp_image && File.exist?(temp_image)
    File.delete(temp_output) if File.exist?(temp_output)
  end
end

# Infer unknown page numbers based on their position between known pages
def infer_unknown_pages(results, sorted_pages)
  inferred = {}

  # Get list of filenames in sorted order (maintain file order)
  filenames = results.keys.sort

  # Find groups of consecutive unknown pages between known pages
  i = 0
  while i < filenames.length
    filename = filenames[i]

    # If this is an unknown page, try to infer it
    if results[filename].nil?
      # Find the known page before this unknown page
      before_page = nil
      before_idx = i - 1
      while before_idx >= 0
        if results[filenames[before_idx]]
          before_page = results[filenames[before_idx]]
          break
        end
        before_idx -= 1
      end

      # Find the known page after this unknown page (and count unknowns in between)
      after_page = nil
      after_idx = i + 1
      unknown_count = 1  # Count this unknown page

      while after_idx < filenames.length
        if results[filenames[after_idx]]
          after_page = results[filenames[after_idx]]
          break
        else
          unknown_count += 1
        end
        after_idx += 1
      end

      # If we have both before and after pages, we can infer
      if before_page && after_page
        gap = after_page - before_page - 1  # Number of pages that should be between them

        # If the gap matches the number of unknown pages, we can infer all of them
        if gap == unknown_count && gap > 0
          # Assign sequential page numbers to all unknown pages in this gap
          current_page = before_page + 1
          (i...(i + unknown_count)).each do |j|
            inferred[filenames[j]] = current_page
            current_page += 1
          end
        end

        # Skip past the unknown pages we just processed
        i += unknown_count
        next
      end
    end

    i += 1
  end

  inferred
end

# Find gaps in page sequence
def find_gaps(page_numbers)
  return [] if page_numbers.empty?

  sorted = page_numbers.sort
  gaps = []

  sorted.each_cons(2) do |a, b|
    if b - a > 1
      gaps << [a + 1, b - 1]
    end
  end

  gaps
end

# Generate output report
def generate_report(results, inferred, duplicates, gaps, scan_dir)
  File.open('page_validation_output.txt', 'w') do |f|
    # Summary
    if duplicates.empty? && gaps.empty?
      f.puts "=" * 60
      f.puts "VALIDATION RESULT: Sequence seems complete!"
      f.puts "=" * 60
    else
      f.puts "=" * 60
      f.puts "VALIDATION RESULT: There are gaps or duplicates!"
      f.puts "=" * 60
    end

    f.puts

    # Summary statistics
    f.puts "SUMMARY:"
    f.puts "-" * 60
    f.puts "Directory: #{scan_dir}"
    f.puts "Total files: #{results.length}"
    f.puts "Known page numbers: #{results.count { |_, p| !p.nil? }}"
    f.puts "Unknown page numbers: #{results.count { |_, p| p.nil? }}"
    f.puts "Inferred page numbers: #{inferred.length}"
    f.puts "Duplicates found: #{duplicates.length}"
    f.puts "Gaps found: #{gaps.length}"
    f.puts

    # Duplicates
    unless duplicates.empty?
      f.puts "DUPLICATES:"
      f.puts "-" * 60
      duplicates.each do |page, files|
        f.puts "Page #{page} appears #{files.length} times:"
        files.each { |filename, _| f.puts "  - #{filename}" }
      end
      f.puts
    end

    # Gaps
    unless gaps.empty?
      f.puts "GAPS:"
      f.puts "-" * 60
      gaps.each do |start_page, end_page|
        f.puts "Missing pages: #{start_page}-#{end_page}"
      end
      f.puts
    end

    # Detailed log
    f.puts "DETAILED LOG:"
    f.puts "-" * 60
    f.puts "%-50s %s" % ["Filename", "Page Number"]
    f.puts "-" * 60

    results.sort_by { |filename, _| filename }.each do |filename, page|
      if page
        f.puts "%-50s %d" % [filename, page]
      elsif inferred[filename]
        f.puts "%-50s %d (inferred)" % [filename, inferred[filename]]
      else
        f.puts "%-50s unknown" % filename
      end
    end
  end
end
