class AddLabelForMakeCommentsEditorOnly < ActiveRecord::Migration
ENMSG = 'Make comments editor-only'
  def self.up
    k = TranslationKey.new(:key => ENMSG)
    k.save
    ['he', 'en', 'ru'].each do |locale|
      k.translations.build(:locale => locale)
    end
    k.save
    t = k.translations.find_by_locale('he')
    t.text = 'הפוך כל ההערות להערות עורך'
    t.save
    t = k.translations.find_by_locale('en')
    t.text = ENMSG
    t.save
  end

  def self.down
  end
end
