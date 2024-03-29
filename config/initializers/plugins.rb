Dir[Rails.root.join('lib', 'plugins', '*')].each do |plugin|
  next if File.basename(plugin) == 'initializers'

  lib = File.join(plugin, 'lib')
  $LOAD_PATH.unshift lib

  begin
    require File.join(plugin, 'init.rb')
  rescue LoadError
    puts $!
   begin
     require File.join(lib, File.basename(plugin) + '.rb')
   rescue LoadError
     begin
       require File.join(lib, File.basename(plugin).underscore + '.rb')
     rescue LoadError
       puts "meh"# guess there's nothing to require?
     end
   end
  end

  initializer = File.join(File.dirname(plugin), 'initializers', File.basename(plugin) + '.rb')
  require initializer if File.exist?(initializer)
end
