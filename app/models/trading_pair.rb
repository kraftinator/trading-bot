class TradingPair < ApplicationRecord
  
  belongs_to  :coin
  belongs_to  :token
  has_many  :traders
  
  def self.with_active_traders
    results = []
    TradingPair.all.each do |trading_pair|
      results << trading_pair if trading_pair.traders.any?
    end
    results
  end
  
  def symbol
    "#{token.symbol}#{coin.symbol}"
  end
  
  def display_name
    "#{token.symbol}/#{coin.symbol}"
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
  
  def total_coins_and_tokens
    coins = tokens = 0
    self.traders.active.each do |trader|
      coins += trader.coin_qty
      tokens += trader.token_qty
    end
    return coins, tokens      
  end
  
end
