# frozen_string_literal: true
require 'rufus-scheduler'

scheduler = Rufus::Scheduler::singleton

scheduler.every '5m' do
  Rails.logger.info 'Regenerating indices'
  system('bin/rake', 'ts:index')
end

# Every Sunday at 9:00AM
scheduler.cron '0 9 * * 0 Asia/Jerusalem' do
  system('bin/rake', 'tasks:send_idle_notifications')
end

# Notification digests. A re-fire of any of these (redeploy, second instance,
# manual re-run) is harmless: DigestDelivery, not the schedule, is what enforces
# at most one digest per recipient per period.
scheduler.cron '0 9 * * * Asia/Jerusalem' do
  system('bin/rake', 'notifications:daily_digest')
end

scheduler.cron '0 9 * * 1 Asia/Jerusalem' do
  system('bin/rake', 'notifications:weekly_digest')
end

scheduler.cron '30 9 * * 1 Asia/Jerusalem' do
  system('bin/rake', 'notifications:purge_stale_buffered')
end
