class CreateTradingPairStats < ActiveRecord::Migration[5.0]
  def change
    create_table :trading_pair_stats do |t|
      t.integer :exchange_trading_pair_id
      t.decimal :last_price, {:precision=>15, :scale=>8}
      t.decimal :low_price, {:precision=>15, :scale=>8}
      t.decimal :high_price, {:precision=>15, :scale=>8}
      t.decimal :weighted_avg_price, {:precision=>15, :scale=>8}
      t.decimal :price_change_pct, {:precision=>15, :scale=>8}
      t.decimal :volume, {:precision=>15, :scale=>8}
      t.decimal :bid_total, {:precision=>15, :scale=>8}
      t.decimal :ask_total, {:precision=>15, :scale=>8}
      t.timestamps
    end
  end
end
