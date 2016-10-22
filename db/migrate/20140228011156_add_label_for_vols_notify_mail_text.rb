class AddLabelForVolsNotifyMailText < ActiveRecord::Migration
  def self.up
    pair = ['Hello %{user_name},

A task you have worked on has now been uploaded to the site!

Go take a look at http://benyehuda.org', 'שלום, %{user_name}.

משימה שעליה עבדת עברה עריכה טכנית והיצירות שבה עלו לאתר הפרויקט!

אנו מזמינים אותך לעיין ביצירות החדשות כאן: http://benyehuda.org']
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
  end
end
