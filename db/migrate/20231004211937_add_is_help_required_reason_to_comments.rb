class AddIsHelpRequiredReasonToComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :is_help_required_reason, :boolean, default: false
  end
end
