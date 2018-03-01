class User < ApplicationRecord

  has_many  :authorizations
  has_many  :campaigns
  has_many  :traders
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
         

  def connected?( exchange )
    self.authorizations.where( exchange: exchange ).any? ? true : false
  end
  
  def authorization( exchange )
    self.authorizations.where( exchange: exchange ).first
  end
  
  def total_holdings
    
    ## Group campaigns by base coin
    base_coins = {}
    campaigns.active.each do |campaign|
      etp = campaign.exchange_trading_pair
      key = etp.coin2.id
      if base_coins[key]
        base_coins[key] << campaign
      else
        base_coins[key] = [campaign]
      end
    end
    
    ## Create revenue object for each base coin
    results = []
    keys = base_coins.keys
    keys.each do |key|
      campaigns = base_coins[key]
      opts = {}
      opts[:coin] = ExchangeCoin.find( key )
      unless opts[:coin].fiat?
        fiat_tps = campaigns.first.exchange.cached_fiat_stats( opts[:coin] )
        opts[:fiat_price] = fiat_tps.last_price
      end      
      opts[:coin_amount] = opts[:profit] = opts[:original_coin_amount] = 0
      
      token_holdings = []
      campaigns.each do |campaign|

        opts[:coin_amount] += campaign.holdings[:coin_amount]
        opts[:profit] += campaign.holdings[:profit]
        opts[:original_coin_amount] += campaign.holdings[:original_coin_amount]
        
        ## Get token holdings
        coins = tokens = 0
        traders = campaign.traders.active
        token_holding = {}
        traders.each do |trader|
          coins += trader.coin_qty
          tokens += trader.token_qty
        end
        token_holding[:campaign] = campaign
        token_holding[:token_amount] = tokens
        token_holdings << token_holding if tokens > 0 and coins > 0
        
      end
      opts[:token_holdings] = token_holdings
      results << opts if opts[:coin_amount] > 0
    end
    
    results

  end

  def holdings
    trading_pairs = TradingPair.with_active_traders
    opts = {}
    opts[:coin_amount] = opts[:profit] = opts[:original_coin_amount] = 0
    trading_pairs.each do |trading_pair|
      opts[:coin_amount] += trading_pair.holdings[:coin_amount]
      opts[:profit] += trading_pair.holdings[:profit]
      opts[:original_coin_amount] += trading_pair.holdings[:original_coin_amount]
    end
    opts
  end

  def token_holdings
    results = []
    coin_total = 0
    trading_pairs = TradingPair.with_active_traders
    trading_pairs.each do |trading_pair|
      opts = {}
      opts[:trading_pair] = trading_pair
      coins, tokens = trading_pair.total_coins_and_tokens
      coin_total += coins
      opts[:token_amount] = tokens
      results << opts
    end
    return coin_total, results
  end
  
  def partially_filled_orders
    pfos = []
    traders.each { |t| pfos << t.current_order.partially_filled_order if t.current_order and t.current_order.partially_filled_order }
    pfos
  end
  
end
