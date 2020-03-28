class AddHoursToTask < ActiveRecord::Migration
  def add_pair(en, he)
    pair = [en, he]
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

  def change
    add_column :tasks, :hours, :integer
    add_pair('Hours spent', 'משך העבודה, בשעות')
    add_pair('Below is an estimated calculation of hours it was likely to spend on this task, based on its number of files.  We have to collect this for our reporting to our grantmakers.  Please correct the estimate if you have a better estimate, or kept track yourself.', 'בשדה להלן מופיע אומדן של שעות שנדרשו להשלמת המשימה, שמחושב על פי כמות הקבצים במשימה. אנו נדרשים לאסוף את האומדנים הללו לצורך דיווח לרשם העמותות על היקף הפעילות הממוצע שלנו. באפשרותך להשאיר את האומדן על כנו, או להחליפו במספר (שלם) מדויק יותר אם יש בידיך.')
    add_pair('Volunteer hours report', 'דו"ח שעות מתנדבים לשנה החולפת')
  end
end
