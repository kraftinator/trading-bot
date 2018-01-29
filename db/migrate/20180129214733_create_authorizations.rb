class CreateAuthorizations < ActiveRecord::Migration[5.0]
  def change
    create_table :authorizations do |t|
      t.integer :user_id
      t.integer :exchange_id
      t.string :api_key
      t.string :api_secret
      t.string :api_pass
      t.timestamps
    end
  end
end
