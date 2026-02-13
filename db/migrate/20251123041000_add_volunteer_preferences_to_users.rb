class AddVolunteerPreferencesToUsers < ActiveRecord::Migration[6.0]
  # Minimal user model for use within this migration only.
  class User < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_column :users, :volunteer_preferences, :text
    add_column :users, :mobile_phone, :string
    add_column :users, :telephone, :string
    add_column :users, :address, :string

    # Backfill new columns from custom_properties if present.
    User.reset_column_information

    User.find_each do |user|
      # Skip if there is no custom_properties attribute or it's blank.
      next unless user.respond_to?(:custom_properties)
      props = user.custom_properties
      next if props.blank?

      mobile    = props["mobile_phone"] || props[:mobile_phone] rescue nil
      telephone = props["telephone"] || props[:telephone]       rescue nil
      address   = props["address"] || props[:address]           rescue nil

      # Do not perform a write if there is nothing to backfill.
      next if mobile.nil? && telephone.nil? && address.nil?

      updates = {}
      updates[:mobile_phone] = mobile if mobile.present? && user.mobile_phone.blank?
      updates[:telephone]    = telephone if telephone.present? && user.telephone.blank?
      updates[:address]      = address if address.present? && user.address.blank?

      next if updates.empty?

      # Use update_columns to avoid validations/callbacks in migrations.
      user.update_columns(updates)
    end
  end

  def down
    remove_column :users, :address if column_exists?(:users, :address)
    remove_column :users, :telephone if column_exists?(:users, :telephone)
    remove_column :users, :mobile_phone if column_exists?(:users, :mobile_phone)
    remove_column :users, :volunteer_preferences if column_exists?(:users, :volunteer_preferences)
  end
end
