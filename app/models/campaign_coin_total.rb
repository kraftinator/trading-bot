class CampaignCoinTotal < ApplicationRecord
  
  belongs_to  :campaign
  
  def profit
    self.projected_coin2_total - self.initial_coin2_total
  end
  
  ## Print coin total info
  def show
    output = []
    output << "----------------------------"
    output << "Trading Pair:    #{campaign.trading_pair_display_name}"
    output << "Amount Invested: #{self.initial_coin2_total}"
    output << "Profit:          #{self.projected_coin2_total - self.initial_coin2_total}"
    output << "Total Value:     #{self.projected_coin2_total}"
    output << "Coin1 Total:     #{self.coin1_total}"
    output << "Coin2 Total:     #{self.coin2_total}"
    output << "----------------------------"
    puts output
  end
  
end
