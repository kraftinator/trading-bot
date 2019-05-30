class CreateIndexFundCoins < ActiveRecord::Migration[5.0]
  def change
    create_table :index_fund_coins do |t|
      t.integer :index_fund_id
      t.integer :exchange_trading_pair_id
      t.decimal :allocation_pct, {:precision=>5, :scale=>4}
      t.decimal :qty, {:precision=>16, :scale=>8}, :default => 0
      t.timestamps
    end
  end
end
