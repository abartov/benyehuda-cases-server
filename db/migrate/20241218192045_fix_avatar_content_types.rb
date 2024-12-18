class FixAvatarContentTypes < ActiveRecord::Migration[6.1]
  TRANSLATIONS = { 'image/pjpeg' => 'image/jpeg', 'image/x-png' => 'image/png', 'image/bmp' => 'image/jpeg' }
  def change
    # iterate over all users and fix avatar content types
    total = User.count
    count = 0
    processed = 0
    User.all.each do |user|
      unless user.valid?
        puts "User #{user.id} is invalid: #{user.errors.full_messages.join(', ')}"
        user.errors.each do |e|
          if e.attribute == :avatar_content_type
            user.avatar_content_type = TRANSLATIONS[user.avatar_content_type]
            user.save!
          end
        end
        count += 1
      end
      processed += 1
      puts "Processed #{processed} of #{total} users" if processed % 100 == 0
    end
    puts "Fixed #{count} avatar content types"
  end
end
