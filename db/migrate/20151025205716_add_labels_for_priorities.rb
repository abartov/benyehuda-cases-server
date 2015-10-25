# encoding: utf-8
class AddLabelsForPriorities < ActiveRecord::Migration
  def up
    pairs = [
              ['Priority','עדיפות'],
              ['First task of new volunteer', 'משימה ראשונה של מתנדב חדש'],
              ['Very old task', 'משימה ישנה מאוד'],
              ['Copyright expiring', 'זכויות יוצרים פוקעות'],
              ['Given permission', 'התקלבה רשות פרסום'],
              ['Completing an author', 'השלמת יוצר/ת']
            ]
    pairs.each {|pair|
      k = TranslationKey.new(:key => pair[0])
      k.save!
      ['he','en','ru'].each do |locale|
        k.translations.build(:locale => locale)
      end
      k.save!
      t = k.translations.find_by_locale('he')
      t.text = pair[1]
      t.save
      t = k.translations.find_by_locale('en')
      t.text = pair[0]
      t.save
    }
  end

  def down
  end
end
