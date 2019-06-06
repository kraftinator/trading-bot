class AddBaseCoinQtyToIndexFundDeposits < ActiveRecord::Migration[5.0]
  def change
    add_column :index_fund_deposits, :base_coin_qty, :decimal, :precision=>16, :scale=>8, :default => 0
  end
end
