namespace :notifications do
  desc 'Send one aggregate digest to each recipient whose email frequency is "daily"'
  task daily_digest: :environment do
    puts "Sent #{NotificationDigestJob.perform('daily')} daily notification digests"
  end

  desc 'Send one aggregate digest to each recipient whose email frequency is "weekly"'
  task weekly_digest: :environment do
    puts "Sent #{NotificationDigestJob.perform('weekly')} weekly notification digests"
  end

  desc 'Delete buffered notifications too old for any live schedule to deliver'
  task purge_stale_buffered: :environment do
    puts "Purged #{PurgeStaleBufferedNotifications.call} stale buffered notifications"
  end
end
