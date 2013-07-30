class AddLabelsForRecentChanges < ActiveRecord::Migration
  def self.up
    [['Recent Changes', 'שינויים אחרונים'], ['Changes', 'שינויים']].each {|pair|
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
