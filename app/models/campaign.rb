class Campaign < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :exchange_trading_pair
  has_many    :traders
  has_one     :campaign_coin_total
  delegate    :exchange, :to => :exchange_trading_pair
  
  validates_presence_of :user_id, :exchange_trading_pair_id, :max_price
  
  scope :active, -> { where( 'deactivated_at is null' ) }
  
  def calculate_coin_totals
    
    unless self.campaign_coin_total
      CampaignCoinTotal.create( campaign: self )
    end
    
    traders = self.traders.active
    coin1_total = coin2_total = initial_coin2_total = projected_coin2_total = 0
    traders.each do |trader|
      coin1_total += trader.token_qty
      coin2_total += trader.coin_qty
      initial_coin2_total += trader.original_coin_qty
      projected_coin2_total += trader.coin_amount
    end

    self.campaign_coin_total.update( 
        coin1_total: coin1_total, 
        coin2_total: coin2_total, 
        initial_coin2_total: initial_coin2_total,
        projected_coin2_total: projected_coin2_total
        )

  end
  
  def cached_coin_total
    if !self.campaign_coin_total
      calculate_coin_totals
    end
    self.campaign_coin_total
  end
  
  def holdings
    traders = self.traders.active
    opts = {}
    opts[:coin_amount] = opts[:profit] = opts[:original_coin_amount] = 0
    traders.each do |trader|
      opts[:coin_amount] += trader.coin_amount
      opts[:profit] += trader.profit
      opts[:original_coin_amount] += trader.original_coin_qty
    end
    opts
  end
  
  # opts[:token_holdings] = Array
  
  def total_coins_and_tokens
    coins = tokens = 0
    traders = self.traders.active
    traders.each do |trader|
      coins += trader.coin_qty
      tokens += trader.token_qty
    end
    return coins, tokens      
  end
  
  def disable
    update( deactivated_at: Time.current )
  end

  def enable
    update( deactivated_at: nil )
  end
  
  def active?
    deactivated_at.nil?
  end
  
  def client
    authorization = user.authorization( exchange )
    authorization.client
  end
  
  def symbol
    exchange_trading_pair.symbol
  end
  
  def trading_pair_display_name
    exchange_trading_pair.display_name
  end
  
end
