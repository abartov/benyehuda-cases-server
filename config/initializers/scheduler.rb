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
