namespace :tokens do
  
  desc 'List tokens'
  task :list => :environment do
    
    ## Usage:
    ## rake tokens:list
    
    puts "\nCURRENT TOKENS:"
    puts "-------------------"
    
    tokens = Token.all
    tokens.each do |token|
      puts token.symbol
    end
    
    puts ""
    
  end
  
  desc 'Create token'
  task :create => :environment do
    
    ## Usage:
    ## rake tokens:create SYMBOL=ZRX
    
    puts "Creating token..."
    
    ## Get params
    symbol = ENV["SYMBOL"]
    unless symbol
      puts "ERROR: Token symbol not found."
      exit
    end
    
    ## Does token already exist?
    token = Token.where( symbol: symbol ).first
    if token
      puts "ERROR: Token #{token.symbol} already exists."
      exit
    end

    ## Create token
    token = Token.create( symbol: symbol )
    
    puts "SUCCESS: Token #{token.symbol} created."
    
  end
 
end