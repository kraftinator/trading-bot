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
   
  desc 'Set stateless limit orders'
  task :init_state_and_filled_at => :environment do
    
    traders = Trader.all.to_a
    traders.each do |trader|
      orders = trader.limit_orders.where( "state is null" ).all.to_a
      #puts "#{trader.id} - #{orders.size}" if orders.any?
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
    
  end
   
end