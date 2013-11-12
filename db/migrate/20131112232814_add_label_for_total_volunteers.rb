class AddLabelForTotalVolunteers < ActiveRecord::Migration
  def self.up
    pair = ['Total Volunteers: ', 'סה"כ מתנדבים: ']
    k = TranslationKey.new(:key => pair[0])
    k.save
    ['he','en','ru'].each do |locale|
      k.translations.build(:locale => locale)
    end
    k.save
    t = k.translations.find_by_locale('he')
    t.text = pair[1]
    t.save
    t = k.translations.find_by_locale('en')
    t.text = pair[0]
    t.save
  end

  def self.down
    # too lazy to bother, harmless to leave them in
  end
end
