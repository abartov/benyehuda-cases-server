require 'rails_helper'
require 'rake'

RSpec.describe 'validate_scans rake task', type: :task do
  before(:all) do
    Rake.application.rake_require 'tasks/validate_scans'
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['validate_scans'] }
  let(:test_dir) { 'tmp/test_validate_scans' }
  let(:report_file) { 'page_validation_output.txt' }

  before(:each) do
    FileUtils.mkdir_p(test_dir)
    FileUtils.rm_f(report_file)
    task.reenable
  end

  after(:each) do
    FileUtils.rm_rf(test_dir)
    FileUtils.rm_f(report_file)
  end

  describe 'with valid images' do
    it 'generates a report file' do
      # Create a minimal test image
      create_test_image("#{test_dir}/page1.jpg", "1")

      task.invoke(test_dir)

      expect(File.exist?(report_file)).to be true
    end

    it 'detects complete sequence' do
      create_test_image("#{test_dir}/page1.jpg", "1")
      create_test_image("#{test_dir}/page2.jpg", "2")
      create_test_image("#{test_dir}/page3.jpg", "3")

      task.invoke(test_dir)

      report = File.read(report_file)
      expect(report).to include("Sequence seems complete!")
      expect(report).to include("Total files: 3")
      expect(report).to include("Gaps found: 0")
    end

    it 'detects gaps in sequence' do
      create_test_image("#{test_dir}/page1.jpg", "1")
      create_test_image("#{test_dir}/page3.jpg", "3")

      task.invoke(test_dir)

      report = File.read(report_file)
      expect(report).to include("There are gaps or duplicates!")
      expect(report).to include("Missing pages: 2-2")
    end

    it 'detects duplicate pages' do
      create_test_image("#{test_dir}/page1_a.jpg", "5")
      create_test_image("#{test_dir}/page1_b.jpg", "5")

      task.invoke(test_dir)

      report = File.read(report_file)
      expect(report).to include("There are gaps or duplicates!")
      expect(report).to include("Duplicates found: 1")
      expect(report).to include("Page 5 appears 2 times")
    end

    it 'handles unknown pages' do
      create_test_image("#{test_dir}/page1.jpg", "1")
      create_blank_image("#{test_dir}/page_unknown.jpg")
      create_test_image("#{test_dir}/page3.jpg", "3")

      task.invoke(test_dir)

      report = File.read(report_file)
      expect(report).to include("Unknown page numbers: 1")
    end

    it 'infers page numbers between known pages' do
      create_test_image("#{test_dir}/page1.jpg", "10")
      create_blank_image("#{test_dir}/page2.jpg")
      create_test_image("#{test_dir}/page3.jpg", "12")

      task.invoke(test_dir)

      report = File.read(report_file)
      expect(report).to include("Inferred page numbers: 1")
      expect(report).to include("11 (inferred)")
    end
  end

  describe 'edge cases' do
    it 'handles empty directory' do
      task.invoke(test_dir)

      report = File.read(report_file)
      expect(report).to include("Total files: 0")
    end

    it 'uses default directory when no argument provided' do
      FileUtils.mkdir_p('tmp/scans')

      task.invoke

      expect(File.exist?(report_file)).to be true

      FileUtils.rm_rf('tmp/scans')
    end

    it 'handles non-existent directory' do
      expect {
        task.invoke('non_existent_dir')
      }.to raise_error(SystemExit)
    end
  end

  private

  def create_test_image(filepath, page_number)
    # Create a simple image with text using ImageMagick
    # This will contain the page number that tesseract can read
    system("convert -size 200x100 xc:white -pointsize 24 -gravity center -draw \"text 0,0 '#{page_number}'\" '#{filepath}' 2>/dev/null")
  end

  def create_blank_image(filepath)
    # Create a blank image with no readable text
    system("convert -size 200x100 xc:white '#{filepath}' 2>/dev/null")
  end
end
