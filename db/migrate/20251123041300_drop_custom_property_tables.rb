class DropCustomPropertyTables < ActiveRecord::Migration[6.0]
  def up
    # Drop custom_properties table (polymorphic join table)
    drop_table :custom_properties if table_exists?(:custom_properties)
    
    # Drop properties table (metadata table)
    drop_table :properties if table_exists?(:properties)
  end

  def down
    # Recreate properties table
    create_table :properties do |t|
      t.string :title
      t.string :parent_type, limit: 32
      t.string :property_type, limit: 32
      t.timestamps
      t.boolean :is_public, default: true
      t.string :comment
    end

    # Recreate custom_properties table
    create_table :custom_properties do |t|
      t.integer :property_id
      t.integer :proprietary_id
      t.string :proprietary_type, limit: 32
      t.string :custom_value, limit: 8192
      t.timestamps
    end

    add_index :custom_properties, [:proprietary_id, :proprietary_type], name: "proprietary"
  end
end
