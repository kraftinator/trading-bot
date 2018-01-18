class AddEthPriceToLimitOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :limit_orders, :eth_price, :decimal, :precision => 8, :scale => 2, :default => 0
  end
end
