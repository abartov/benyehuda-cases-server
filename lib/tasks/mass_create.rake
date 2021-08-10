require 'yaml'
desc "Create tasks en masse from control file"
task :mass_create, [:control_file] => :environment do |taskname, args|
  print "Reading control file: #{args.control_file}... "
  cfile = args.control_file[0] == '/' ? args.control_file : './' + args.control_file
  cfg = YAML.load(File.open(cfile).read)
  # validate
  valid = true
  errmsg = ''
  ['workdir','fileglob','task_title','task_kind_id','creator_id'].each {|key| 
    unless cfg[key].present?
      valid = false
      errmsg = key
    end
  }
  unless valid
    puts "configuration error: missing required key: #{errmsg}"
    exit
  end
  puts "done!"
  Dir.glob("#{cfg['workdir']}/#{cfg['fileglob']}").each do |filename|
    puts "Processing #{filename}:"
    task_title = cfg['task_title'].dup
    if cfg['filename_regexp_captures'].present?
      thematch = filename.match(cfg['filename_regexp_captures'])
      if thematch.nil?
        puts "warning: regexp didn't match!"
      else
        # apply captures
        number = 1
        thematch.captures.each do |capture|
          task_title.sub!("$#{number}", capture)
          number += 1
        end
      end
    end
    print "  creating task... "
    t = Task.new(creator_id: cfg['creator_id'], kind_id: cfg['task_kind_id'], name: task_title)
    t.save!
    puts "done!"
    t.instructions = cfg['task_instructions'] if cfg['task_instructions'].present?
    print "  attaching file... "
    doc = t.documents.build
    doc.file = File.open(filename)
    doc.file_file_name = filename[filename.rindex('/')+1..-1]
    doc.user_id = cfg['creator_id']
    doc.save!
    puts "done!\n"
  end
end


