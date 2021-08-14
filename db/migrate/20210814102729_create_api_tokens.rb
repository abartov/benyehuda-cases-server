class CreateAPITokens < ActiveRecord::Migration[6.1]
  def change
    create_table :api_tokens do |t|
      t.string :token
      t.references :api_user, foreign_key: true
      t.datetime :expires_at

      t.timestamps
    end
  end
end
