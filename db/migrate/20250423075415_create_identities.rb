binclass CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider_name
      t.string :provider_uid

      t.timestamps
    end
  end
end
