d Encoding: utf-8
class AddLabelForTechEditText < ActiveRecord::Migration
  def self.up
    pairs = [['task event|Mark for technical editing', 'לעריכה טכנית'], ['task state|Technical editing', 'ממתינה לעריכה טכנית']]
    pairs.each do |pair|
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

    ts = TaskState.new
    ts.name = 'techedit'
    ts.value = 'task state|Technical editing'
    ts.save!
  end

  def self.down
  end
end
