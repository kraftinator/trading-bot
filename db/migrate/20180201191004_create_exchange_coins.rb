class CreateExchangeCoins < ActiveRecord::Migration[5.0]
  def change
    create_table :exchange_coins do |t|
      t.integer :exchange_id
      t.integer :coin_id
      t.integer :precision, :default => 0
      t.string :symbol
      t.timestamps
    end
  end
end
