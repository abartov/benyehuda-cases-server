# encoding: utf-8
class AddLabelsForEditorPasswordReset < ActiveRecord::Migration
  def up
    pairs = [['reset password', 'איפוס סיסמה למשתמש'], ['Instructions to reset their password have been e-mailed to the user.', 'הנחיות לאיפוס סיסמה נשלחו למשתמש.']]
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
