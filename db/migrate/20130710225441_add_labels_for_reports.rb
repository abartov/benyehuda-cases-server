class AddLabelsForReports < ActiveRecord::Migration
  def self.up
    [['Stalled Tasks report', 'דו"ח משימות ללא תנועה'], ['Inactive Volunteers report', 'דו"ח מתנדבים לא פעילים'], ['Active Volunteers report', 'דו"ח מתנדבים פעילים'], ['New Volunteers report', 'דו"ח מתנדבים חדשים'], ['Reports','דו"חות'].each {|pair|
      k = TranslationKey.new(:key => pair[0])
      debugger
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
    }
  end

  def self.down
    # too lazy to bother, harmless to leave them in
  end
end
