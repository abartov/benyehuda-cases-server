require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#last_editor' do
    let(:volunteer) { create(:volunteer, :active_user) }
    let(:editor1) { create(:editor, :active_user) }
    let(:editor2) { create(:editor, :active_user) }

    it 'returns the editor from the most recent task' do
      # Create an older task with editor1
      old_task = create(:task, assignee: volunteer, editor: editor1, updated_at: 2.days.ago)
      
      # Create a newer task with editor2
      new_task = create(:task, assignee: volunteer, editor: editor2, updated_at: 1.day.ago)
      
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

  describe 'returning from break notification' do
    let(:volunteer) { create(:volunteer, :active_user, on_break: true) }
    let(:editor) { create(:editor, :active_user) }

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
      volunteer.update(on_break: false)
      
      # Mock the notification delivery
      notification_double = double('notification')
      allow(notification_double).to receive(:deliver)
      allow(Notification).to receive(:volunteer_returned_from_break).and_return(notification_double)
      
      # Simulate volunteer going on break
      volunteer.update(on_break: true)
      
      expect(Notification).not_to have_received(:volunteer_returned_from_break)
    end

    it 'does not send notification when on_break does not change' do
      volunteer.update(on_break: false)
      
      # Mock the notification delivery
      notification_double = double('notification')
      allow(notification_double).to receive(:deliver)
      allow(Notification).to receive(:volunteer_returned_from_break).and_return(notification_double)
      
      # Update another attribute without changing on_break
      volunteer.update(name: 'New Name')
      
      expect(Notification).not_to have_received(:volunteer_returned_from_break)
    end

    it 'does not send notification if volunteer has no last editor' do
      volunteer_without_editor = create(:volunteer, :active_user, on_break: true)
      
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
