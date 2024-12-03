class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_methods do |t|
      t.string :name, null: false
      t.text :instructions
      t.boolean :active, default: true
      t.json :settings, default: {}

      t.timestamps
    end

    add_index :payment_methods, :name, unique: true
    add_reference :hong_baos, :payment_method, foreign_key: true
  end
end
