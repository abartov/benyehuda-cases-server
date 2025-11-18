class VolReqPrefsToVolPrefs < ActiveRecord::Migration[6.1]
  def change
    # migrate volunteer request preferences to volunteer preferences unless they already exist
    total = User.count
    count = 0
    processed = 0
    User.all.each do |user|
      if user.valid?
        if user.volunteer_request.try(:preferences).present? && user.get_volunteer_preferences.blank?
          user.set_volunteer_preferences(user.volunteer_request.preferences)
          user.save!
          count += 1
        end
      else
        puts "User #{user.id} is invalid: #{user.errors.full_messages.join(', ')}"
      end
      processed += 1
      puts "Processed #{processed} of #{total} users" if processed % 100 == 0
    end
    puts "Migrated #{count} volunteer request preferences to volunteer preferences"
  end
end
