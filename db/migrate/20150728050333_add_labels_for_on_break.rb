# encoding: utf-8
class AddLabelsForOnBreak < ActiveRecord::Migration
  def up
    pairs = [['on break', 'בהפסקה'], ['take a break', 'יציאה להפסקה'], ["You're now on break! Request a new task to come out of break.", 'יצאת להפסקה! כדי לחזור לפעילות, יש ללחוץ על לחצן בקשת משימה.']]
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
  end

  def down
  end
end

