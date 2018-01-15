class AddBuyPctAndSellPctAndCeilingPctToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :buy_pct, :decimal, :precision => 5, :scale => 4, :default => 0
    add_column :traders, :sell_pct, :decimal, :precision => 5, :scale => 4, :default => 0
    add_column :traders, :ceiling_pct, :decimal, :precision => 5, :scale => 4, :default => 0
  end
end
