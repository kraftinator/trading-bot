namespace :strategies do
  
  desc 'List strategies'
  task :list => :environment do
    
    ## Usage:
    ## rake strategies:list
    
    puts "\nCURRENT STRATEGIES:"
    puts "-------------------"
    
    strategies = Strategy.all
    strategies.each do |strategy|
      puts strategy.name
    end
    
    puts ""
    
  end
  
  desc 'Create strategy'
  task :create => :environment do
    
    ## Usage:
    ## rake strategies:create NAME=KAPPA
    
    puts "Creating strategy..."
    
    ## Get params
    name = ENV["NAME"]
    unless name
      puts "ERROR: Strategy name not found."
      exit
    end
    
    ## Does strategy already exist?
    strategy = Strategy.where( name: name ).first
    if strategy
      puts "ERROR: Strategy #{strategy.name} already exists."
      exit
    end

    ## Create strategy
    strategy = Strategy.create( name: name )
    
    puts "SUCCESS: Strategy #{strategy.name} created."
    
  end
 
end