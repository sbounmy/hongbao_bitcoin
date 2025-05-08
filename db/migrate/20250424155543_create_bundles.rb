class CreateBundles < ActiveRecord::Migration[8.0]
  def change
    create_table :bundles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :status
      t.timestamps
    end
  end
end
