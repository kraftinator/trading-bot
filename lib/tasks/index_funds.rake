namespace :index_funds do
  
  desc 'Process index funds'
  task :process_all => :environment do
    
    ## Usage:
    ## rake index_funds:process_all

    IndexFund.active.all.each do |index_fund|
      index_fund.assets.each do |asset|
        index_fund.process_open_sell_orders(asset)
        index_fund.process_open_buy_orders(asset)
      end
    end
    
    IndexFund.active.all.each do |index_fund|
      IndexFundSnapshot.generate_snapshot(index_fund)
    end
      
    IndexFund.active.all.each do |index_fund|
      index_fund.rebalance
    end
    
  end
 
end