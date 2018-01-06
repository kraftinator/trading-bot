class AddPrecisionToTradingPairs < ActiveRecord::Migration[5.0]
  def change
    add_column :trading_pairs, :precision, :integer, :default => 8
  end
end
