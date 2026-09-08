class CreateDigestDeliveries < ActiveRecord::Migration[6.1]
  def change
    create_table :digest_deliveries do |t|
      t.string :recipient_email, limit: 100, null: false
      t.datetime :last_digest_sent_at, null: false
    end

    # This unique index -- not the scheduler -- is what enforces "at most one
    # digest per recipient per period".
    add_index :digest_deliveries, :recipient_email, unique: true
  end
end
