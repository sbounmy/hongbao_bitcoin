class AddPublicKeyCodeAndPassphraseToHongBaos < ActiveRecord::Migration[8.0]
  def change
    add_column :hong_baos, :public_key, :string
    add_column :hong_baos, :address, :string
    add_column :hong_baos, :passphrase, :string
    add_column :hong_baos, :mt_pelerin_response, :jsonb
    add_column :hong_baos, :mt_pelerin_request, :jsonb
    add_column :papers, :elements, :json
  end
end
