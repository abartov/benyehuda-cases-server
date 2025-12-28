require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#last_editor' do
    let(:volunteer) { create(:user, :volunteer, :active_user) }
    let(:editor1) { create(:user, :editor, :active_user) }
    let(:editor2) { create(:user, :editor, :active_user) }

    it 'returns the editor from the most recent task' do
      # Create an older task with editor1
      create(:task, assignee: volunteer, editor: editor1, updated_at: 2.days.ago)

      # Create a newer task with editor2
      create(:task, assignee: volunteer, editor: editor2, updated_at: 1.day.ago)

      expect(volunteer.last_editor).to eq(editor2)
    end

    it 'returns nil if volunteer has no tasks with an editor' do
      create(:task, assignee: volunteer, editor: nil)

      expect(volunteer.last_editor).to be_nil
    end

    it 'returns nil if volunteer has no tasks' do
      expect(volunteer.last_editor).to be_nil
    end
  end

  describe '.vols_active_in_last_n_months' do
    let!(:admin) { create(:user, :admin, :active_user, is_volunteer: true, on_break: false) }
    let!(:editor) { create(:user, :editor, :active_user, is_volunteer: true, on_break: false) }
    let!(:volunteer_with_login) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 3.months.ago) }
    let!(:volunteer_with_comment) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 2.years.ago) }
    let!(:volunteer_with_document) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 2.years.ago) }
    let!(:volunteer_with_audit) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 2.years.ago) }
    let!(:inactive_volunteer) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 2.years.ago) }

    before do
      # Create a task for testing
      task = create(:task)

      # Volunteer with recent comment
      comment = create(:comment, user: volunteer_with_comment, task: task)
      comment.update_column(:created_at, 3.months.ago)

      # Volunteer with recent document upload
      document = create(:document, user: volunteer_with_document, task: task)
      document.update_column(:created_at, 3.months.ago)

      # Volunteer with recent audit (task status change)
      audit = create(:audit, user: volunteer_with_audit, task: task)
      audit.update_column(:created_at, 3.months.ago)
    end

    it 'includes admins regardless of activity' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).to include(admin)
    end

    it 'includes editors regardless of activity' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).to include(editor)
    end

    it 'includes volunteers who logged in recently' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).to include(volunteer_with_login)
    end

    it 'includes volunteers who left comments recently' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).to include(volunteer_with_comment)
    end

    it 'includes volunteers who uploaded documents recently' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).to include(volunteer_with_document)
    end

    it 'includes volunteers who changed task status recently' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).to include(volunteer_with_audit)
    end

    it 'excludes volunteers with no recent activity' do
      result = User.vols_active_in_last_n_months(6)
      expect(result).not_to include(inactive_volunteer)
    end

    it 'excludes volunteers on break' do
      volunteer_with_login.update(on_break: true)
      result = User.vols_active_in_last_n_months(6)
      expect(result).not_to include(volunteer_with_login)
    end
  end

  describe '.vols_inactive_in_last_n_months' do
    let!(:admin) { create(:user, :admin, :active_user, is_volunteer: true, on_break: false, current_login_at: 2.years.ago) }
    let!(:editor) { create(:user, :editor, :active_user, is_volunteer: true, on_break: false, current_login_at: 2.years.ago) }
    let!(:active_volunteer) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 3.months.ago) }
    let!(:inactive_volunteer) { create(:user, :volunteer, :active_user, on_break: false, current_login_at: 2.years.ago) }

    it 'excludes admins' do
      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(admin)
    end

    it 'excludes editors' do
      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(editor)
    end

    it 'excludes volunteers with recent login' do
      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(active_volunteer)
    end

    it 'includes volunteers with no recent activity' do
      result = User.vols_inactive_in_last_n_months(6)
      expect(result).to include(inactive_volunteer)
    end

    it 'excludes volunteers on break' do
      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(inactive_volunteer.tap { |v| v.update(on_break: true) })
    end

    it 'excludes volunteers with recent comments' do
      task = create(:task)
      comment = create(:comment, user: inactive_volunteer, task: task)
      comment.update_column(:created_at, 3.months.ago)

      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(inactive_volunteer)
    end

    it 'excludes volunteers with recent document uploads' do
      task = create(:task)
      document = create(:document, user: inactive_volunteer, task: task)
      document.update_column(:created_at, 3.months.ago)

      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(inactive_volunteer)
    end

    it 'excludes volunteers with recent audits' do
      task = create(:task)
      audit = create(:audit, user: inactive_volunteer, task: task)
      audit.update_column(:created_at, 3.months.ago)

      result = User.vols_inactive_in_last_n_months(6)
      expect(result).not_to include(inactive_volunteer)
    end
  end

  describe 'returning from break notification' do
    let(:volunteer) { create(:user, :volunteer, :active_user, on_break: true) }
    let(:person_not_on_break) { create(:user, :volunteer, on_break: false) }
    let(:editor) { create(:user, :editor, :active_user) }

    before do
      # Create a task so the volunteer has an editor to notify
      create(:task, assignee: volunteer, editor: editor)
    end

    it 'sends notification to the last editor when volunteer returns from break' do
      # Mock the notification delivery
      notification_double = double('notification')
      allow(notification_double).to receive(:deliver)
      allow(Notification).to receive(:volunteer_returned_from_break).and_return(notification_double)

      # Simulate volunteer returning from break
      volunteer.update(on_break: false)

      expect(Notification).to have_received(:volunteer_returned_from_break).with(volunteer, editor)
      expect(notification_double).to have_received(:deliver)
    end

    it 'does not send notification when on_break changes from false to true' do
      # Mock the notification delivery
      notification_double = double('notification')
      allow(notification_double).to receive(:deliver)
      allow(Notification).to receive(:volunteer_returned_from_break).and_return(notification_double)

      # Simulate volunteer going on break
      person_not_on_break.update(on_break: true)

      expect(Notification).not_to have_received(:volunteer_returned_from_break)
    end

    it 'does not send notification when on_break does not change' do
      # Mock the notification delivery
      notification_double = double('notification')
      allow(notification_double).to receive(:deliver)
      allow(Notification).to receive(:volunteer_returned_from_break).and_return(notification_double)

      # Update another attribute without changing on_break
      volunteer.update(name: 'New Name')

      expect(Notification).not_to have_received(:volunteer_returned_from_break)
    end

    it 'does not send notification if volunteer has no last editor' do
      volunteer_without_editor = create(:user, :volunteer, :active_user, on_break: true)

      # Mock the notification delivery
      notification_double = double('notification')
      allow(notification_double).to receive(:deliver)
      allow(Notification).to receive(:volunteer_returned_from_break).and_return(notification_double)

      # Simulate volunteer returning from break
      volunteer_without_editor.update(on_break: false)

      expect(Notification).not_to have_received(:volunteer_returned_from_break)
    end
  end
end
