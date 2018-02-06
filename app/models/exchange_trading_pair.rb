class ExchangeTradingPair < ApplicationRecord
  
   belongs_to :exchange
   belongs_to :coin1, :class_name => "ExchangeCoin"
   belongs_to :coin2, :class_name => "ExchangeCoin"
   
   has_many :campaigns
   has_many :trading_pair_stats
   
   def trading_pair_stat
     tps = current_trading_pair_stat
     #if tps.nil? or tps.updated_at < 1.minute.ago
     #   tps = TradingPairStat.refresh( self )
     # end
     tps     
   end
   
   def current_trading_pair_stat
     return nil if trading_pair_stats.empty?
     trading_pair_stats.order( 'created_at desc' ).first
   end
   
   def symbol
     "#{coin1.symbol}#{coin2.symbol}"
   end
  
   def display_name
     "#{coin1.symbol}/#{coin2.symbol}"
   end
  
end
