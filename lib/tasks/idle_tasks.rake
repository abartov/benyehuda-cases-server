namespace :tasks do
  desc "Send weekly reminders for idle tasks and reports to editors"
  task send_idle_notifications: :environment do
    dry_run = ENV['DRY_RUN'].to_s.downcase == 'true' || Rails.env.development?

    if dry_run
      puts "=" * 70
      puts "DRY RUN MODE - No emails will be sent"
      puts "To send real emails, run: RAILS_ENV=production rake tasks:send_idle_notifications"
      puts "=" * 70
    end

    puts "Starting idle task notifications process..."

    # Find tasks idle for 4+ months and send assignee reminders
    puts "\n=== Processing 4-month idle tasks for assignee reminders ==="
    idle_4_months_count = send_assignee_reminders(dry_run)
    puts dry_run ? "Would send #{idle_4_months_count} assignee reminders" : "Sent #{idle_4_months_count} assignee reminders"

    # Find tasks idle for 5+ months and send editor reports
    puts "\n=== Processing 5-month idle tasks for editor reports ==="
    editor_reports_count = send_editor_reports(dry_run)
    puts dry_run ? "Would send #{editor_reports_count} editor reports" : "Sent #{editor_reports_count} editor reports"

    puts "\n✓ Idle task notifications process completed"
  end

  desc "Send reminders to assignees for tasks idle 4+ months"
  task send_assignee_reminders: :environment do
    dry_run = ENV['DRY_RUN'].to_s.downcase == 'true' || Rails.env.development?
    send_assignee_reminders(dry_run)
  end

  desc "Send reports to editors for tasks idle 5+ months"
  task send_editor_reports: :environment do
    dry_run = ENV['DRY_RUN'].to_s.downcase == 'true' || Rails.env.development?
    send_editor_reports(dry_run)
  end

  private

  def send_assignee_reminders(dry_run = false)
    idle_tasks = find_idle_tasks(4.months.ago)
    reminder_count = 0

    idle_tasks.each do |task|
      next unless task.assignee

      # Check if assignee has been disabled - if so, unassign the task
      if task.assignee.disabled_at.present?
        if dry_run
          puts "  [DRY RUN] Would unassign task ##{task.id} - assignee #{task.assignee.name} is disabled"
        else
          puts "  Unassigning task ##{task.id} - assignee #{task.assignee.name} is disabled"
          task.assignee_id = nil
          task._abandon!
          task.save!
        end
        next
      end

      next unless task.assignee.email.present?

      # Check if we already sent a reminder in the last week
      if TaskIdleReminder.sent_within?(task.id, task.assignee.id, 1.week)
        puts "  Skipping task ##{task.id} - reminder already sent within last week"
        next
      end

      begin
        if dry_run
          puts "  [DRY RUN] Would send reminder for task ##{task.id} (#{task.name.utf_snippet(30)}) to #{task.assignee.name}"
        else
          # Send notification
          Notification.task_idle(task, task.assignee, task.editor).deliver_now

          # Log the reminder
          TaskIdleReminder.create!(
            task_id: task.id,
            user_id: task.assignee.id,
            sent_at: Time.zone.now
          )

          puts "  ✓ Sent reminder for task ##{task.id} (#{task.name.utf_snippet(30)}) to #{task.assignee.name}"
        end
        reminder_count += 1
      rescue => e
        puts "  ✗ Error sending reminder for task ##{task.id}: #{e.message}"
      end
    end

    reminder_count
  end

  def send_editor_reports(dry_run = false)
    idle_tasks = find_idle_tasks(5.months.ago)

    # Group tasks by editor
    tasks_by_editor = idle_tasks.select { |t| t.editor.present? }.group_by(&:editor)

    # Preload all relevant reminders to avoid N+1 queries
    task_ids = idle_tasks.map(&:id)
    assignee_ids = idle_tasks.map(&:assignee_id).compact

    reminders = if task_ids.any? && assignee_ids.any?
      TaskIdleReminder.where(task_id: task_ids, user_id: assignee_ids)
    else
      []
    end

    reminders_index = reminders.group_by { |r| [r.task_id, r.user_id] }
                               .transform_values { |rs| rs.max_by(&:sent_at) }

    reports_sent = 0
    tasks_by_editor.each do |editor, tasks|
      next unless editor.email.present?

      # Build task data for the report
      idle_tasks_data = tasks.map do |task|
        assignee = task.assignee
        last_reminder = assignee && reminders_index[[task.id, assignee.id]]
        {
          task: task,
          assignee: assignee,
          last_reminder_date: last_reminder&.sent_at
        }
      end

      begin
        if dry_run
          puts "  [DRY RUN] Would send report to editor #{editor.name} with #{tasks.count} idle tasks"
        else
          # Send the editor report
          Notification.editor_idle_tasks_report(editor, idle_tasks_data).deliver_now
          puts "  ✓ Sent report to editor #{editor.name} with #{tasks.count} idle tasks"
        end
        reports_sent += 1
      rescue => e
        puts "  ✗ Error sending report to editor #{editor.name}: #{e.message}"
      end
    end

    reports_sent
  end

  def find_idle_tasks(idle_since)
    # Find tasks that meet ALL these criteria:
    # 1. Have an assignee
    # 2. Are not in 'approved' or 'ready_to_publish' states (already complete)
    # 3. Have not been updated since idle_since date
    # 4. Have no recent document activity (uploads or marking as done)

    puts "  Looking for tasks idle since #{idle_since.strftime('%Y-%m-%d')}..."

    # Start with tasks that have assignees and are not complete
    candidate_tasks = Task.where.not(assignee_id: nil)
                          .where.not(state: ['approved', 'ready_to_publish', 'other_task_creat'])
                          .where('tasks.updated_at < ?', idle_since)

    puts "  Found #{candidate_tasks.count} candidates based on task.updated_at"

    # Filter out tasks with recent document activity using set-based queries
    # 1. Tasks with recent document uploads
    recent_upload_task_ids = Document.where('documents.created_at >= ?', idle_since)
                                     .where(task_id: candidate_tasks.select(:id))
                                     .distinct
                                     .pluck(:task_id)

    puts "  Found #{recent_upload_task_ids.count} tasks with recent document uploads"

    # 2. Tasks with recent "done" markings on documents (via audits)
    # Build a mapping of document IDs to task IDs for all candidate tasks
    doc_id_to_task_id = Document.where(task_id: candidate_tasks.select(:id))
                                .pluck(:id, :task_id)
                                .to_h

    recent_done_task_ids = if doc_id_to_task_id.any?
      # Find audits for "done" changes on these documents
      # Match YAML serialized format where 'done' is a key with proper delimiters
      # Patterns: ":done:" for symbol keys or "done: " for string keys in YAML
      # This prevents false matches like 'undone' or 'abandoned' or values containing 'done'
      audits = Audit.where(auditable_type: 'Document')
                    .where(auditable_id: doc_id_to_task_id.keys)
                    .where('audits.created_at >= ?', idle_since)
                    .where("changed_attrs LIKE ? OR changed_attrs LIKE ?", "%\n:done:%", "%\ndone: %")
                    .pluck(:auditable_id)

      # Map document IDs back to task IDs
      audits.map { |doc_id| doc_id_to_task_id[doc_id] }.compact.uniq
    else
      []
    end

    puts "  Found #{recent_done_task_ids.count} tasks with recent 'done' changes"

    # Combine all task IDs that have recent document activity
    active_task_ids = (recent_upload_task_ids + recent_done_task_ids).uniq

    # Get idle tasks (exclude those with recent activity) with associations preloaded
    idle_tasks = candidate_tasks.where.not(id: active_task_ids).includes(:assignee, :editor, :documents)

    puts "  After filtering document activity: #{idle_tasks.count} truly idle tasks"
    idle_tasks
  end
end
