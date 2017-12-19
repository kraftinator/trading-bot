# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

## Destroy previous records
Coin.destroy_all
Token.destroy_all
TradingPair.destroy_all
Strategy.destroy_all

## Create coins
puts "Create coins"
Coin.create( symbol: "ETH" )
Coin.create( symbol: "BTC" )

## Create tokens
puts "Create tokens"
Token.create( symbol: "REQ" )
Token.create( symbol: "LINK" )
Token.create( symbol: "AST" )

## Create trading pairs
puts "Create trading pairs"
TradingPair.create( coin: Coin.find_by_symbol( "ETH" ), token: Token.find_by_symbol( "REQ" ),  max_price: "0.00080000" )
TradingPair.create( coin: Coin.find_by_symbol( "ETH" ), token: Token.find_by_symbol( "LINK" ), max_price: "0.00130847" )
TradingPair.create( coin: Coin.find_by_symbol( "ETH" ), token: Token.find_by_symbol( "AST" ),  max_price: "0.00200000" )

## Create strategies
puts "Create strategies"
Strategy.create( name: "ALPHA" )
Strategy.create( name: "BETA" )
Strategy.create( name: "GAMMA" )
Strategy.create( name: "DELTA" )
Strategy.create( name: "EPSILON" )