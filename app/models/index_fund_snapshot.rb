class IndexFundSnapshot < ApplicationRecord
  
  belongs_to  :index_fund
  
  def self.generate_snapshot(index_fund)
    assets, fund_total = index_fund.calculate_fund_stats
    self.create(index_fund: index_fund, total_fund_qty: fund_total, total_deposit_qty: index_fund.deposit_total)
  end
  
  def profit
    total_fund_qty-total_deposit_qty
  end
  
  def show
    output = []
    output << "----------------------------"
    output << "Index Fund:        #{index_fund.name}"
    output << "Base Coin:         #{index_fund.base_coin.symbol}"
    output << "Total Fund Qty:    #{total_fund_qty}"
    output << "Total Deposit Qty: #{total_deposit_qty}"
    output << "----------------------------"
    puts output
  end
  
end