class AddLabelsForVolsNotifyReport < ActiveRecord::Migration
  def self.up
    [['E-mails sent to volunteers','נשלח דואל למתנדבים'], ['Send notification to these users','שלח יידוע למתנדבים אלה עכשיו'], ['e-mail addresses to notify: ','כתובות דואל ליידע: '], ['Volunteers to Notify','מתנדבים ליידע'], ['No volunteers to notify','אין מתנדבים ליידע'], ['Volunteers to Notify report', 'יידוע מתנדבים על העלאת יצירות לאתר'], ['your work added to site subject|Your contributions are now published on the Ben-Yehuda site!', 'your work added to site subject|יצירות שהקלדת/הגהת עלו בחודש האחרון למאגר הפרויקט!']].each {|pair|
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
    }
  end

  def self.down
  end
end

