class CreateExchangeTradingPairs < ActiveRecord::Migration[5.0]
  def change
    create_table :exchange_trading_pairs do |t|
      t.integer :exchange_id
      t.integer :coin1_id
      t.integer :coin2_id
      t.integer :precision, :default => 0
      t.timestamps
    end
  end
end
