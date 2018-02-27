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
  
  desc 'Run data migration for AddOrderUidToLimitOrders'
  task :init_order_uid => :environment do
    
    
    
    ## 20180215190627_add_order_uid_to_limit_orders.rb
    #orders = LimitOrder.all.to_a
   # orders = LimitOrder.where( "state != 'CANCELED' and order_uid is null").all.to_a
    orders = LimitOrder.where( "order_uid is null").take(10000)
    orders.each do |order|
      if order.order_uid.nil?
        order.update( order_uid: order.order_guid )
      end
    end
    
  end
  
  desc 'Run data migration for AddFiatPriceToLimitOrders'
  task :init_fiat_price => :environment do
    
    ## 20180223215024_add_fiat_price_to_limit_orders.rb
    #orders = LimitOrder.all.to_a
    orders = LimitOrder.where( "fiat_price = 0 and eth_price > 0").all.to_a
    orders.each do |order|
      if order.fiat_price == 0 && order.eth_price > 0
        order.update( fiat_price: order.eth_price )
      end
    end
    
  end
  
  desc 'Set stateless limit orders'
  task :init_state_and_filled_at => :environment do
    
    traders = Trader.all.to_a
    traders.each do |trader|
      orders = trader.limit_orders.where( "state is null" ).all.to_a
      puts "Updating stateless orders for Bot #{trader.id}" if orders.any?
      orders.each do |order|
        ## Find next order
        next_order = trader.limit_orders.where( "created_at > ?", order.created_at ).order( 'created_at asc' ).first
        if next_order
          if order.side == 'BUY'
            if next_order.side == 'BUY'
              order.update( state: LimitOrder::STATES[:canceled] )
              #puts "#{order.id} was cancelled."
            elsif next_order.side == 'SELL'
              order.update( state: LimitOrder::STATES[:filled], filled_at: order.updated_at )
              #puts "#{order.id} was filled."
            end
          elsif order.side == 'SELL'
            if next_order.side == 'BUY'
              order.update( state: LimitOrder::STATES[:filled], filled_at: order.updated_at )
              #puts "#{order.id} was filled."
            elsif next_order.side == 'SELL'
              order.update( state: LimitOrder::STATES[:canceled] )
              #puts "#{order.id} was cancelled."
            end
          end
      
        end
      end  
    end  
    
  end ## end init_state_and_filled_at
   
end