namespace :migrations do
  
  desc 'Run data migration for AddBuyPctAndSellPctAndCeilingPctToTraders'
  task :init_buy_pct_and_sell_pct => :environment do
    
    ## 20180115222637_add_buy_pct_and_sell_pct_and_ceiling_pct_to_traders.rb
    
    results = []
    Trader.all.each do |trader|
      trader.update( buy_pct: trader.percentage_range, sell_pct: trader.percentage_range )
      results << "#{trader.percentage_range.to_f}  #{trader.buy_pct.to_f}  #{trader.sell_pct.to_f}"
    end
    
    results.each { |r| puts r }
    
  end
  
  desc 'Run data migration for AddCampaignIdToTraders'
  task :init_campaigns => :environment do
    
    ## 20180205235439_add_campaign_id_to_traders.rb
    
    exchange = Exchange.where( name: 'Binance' ).first
    users = User.all
    users.each do |user|
      traders = user.traders
      traders.each do |trader|
        puts "Bot #{trader.id}"
        unless trader.campaign
          tp = trader.trading_pair
          ## Get exchange coin
          ec = ExchangeCoin.where( symbol: tp.token.symbol ).first
          break unless ec
          etp = ExchangeTradingPair.where( coin2: ExchangeCoin.where( symbol: 'ETH').first, coin1: ec ).first
          break unless etp
          campaign = Campaign.where( user: user, exchange_trading_pair: etp ).first
          unless campaign
            campaign = Campaign.create( user: user, exchange_trading_pair: etp, max_price: tp.max_price )
            puts "Created campaign #{campaign.id} for trading pair #{campaign.symbol}."
          end
          trader.update( campaign: campaign )
          puts "Added campaign #{campaign.id} to bot #{trader.id}."
        end
      end
    end
    
  end
   
end