class AddPrecisionFieldsToExchangeTradingPairs < ActiveRecord::Migration[5.0]
  def change
    add_column :exchange_trading_pairs, :price_precision, :integer, :default => 0
    add_column :exchange_trading_pairs, :qty_precision, :integer, :default => 0
  end
end
