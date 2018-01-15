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
   
end