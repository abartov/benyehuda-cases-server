desc "Dump all he i18n strings to allstr.txt"
task :dumpstr => :environment do
  print "Dumping strings to allstr.txt\n"
  File.open('allstr.txt', 'w') {|f|
    TranslationKey.all.each {|t|
      tt = TranslationText.find(:first, :conditions => "translation_key_id = #{t.id} and locale = 'he'")
      if tt
        f.print("#{t.id}\nen: #{t.key}\n#{tt.text}\n\n")
      else
        f.print("#{t.id}\nen: #{t.key}\n---NO TRANSLATION---\n\n")
      end
    }
  }
  
  print "Done."
end


