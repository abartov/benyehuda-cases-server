desc "Grab all scans for task [task_id]"
task :grab_scans, [:task_id] => :environment do |taskname, args|
  print "Grabbing scans for Task ID: #{args.task_id}... "
  t = Task.find(args.task_id.to_i)
  unless t.nil?
    t.documents.each do |doc|
      `wget #{doc.file.url}`
    end
    puts "done!"
  else
    puts "no such task!"
  end
end


