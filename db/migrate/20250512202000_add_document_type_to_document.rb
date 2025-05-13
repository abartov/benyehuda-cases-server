class AddDocumentTypeToDocument < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :document_type, :integer, default: 0
  end
end
