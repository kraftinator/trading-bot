class AddOriginalCoinQtyToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :original_coin_qty, :decimal, :precision => 16, :scale => 8, :default => 0
  end
end
