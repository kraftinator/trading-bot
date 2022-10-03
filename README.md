# Crypto Trading Bots

The Crypto Trading Bots application is a platform that allows users to create bots that trade cryptocurrencies. A bot is a computer program that performs automated tasks. In this case, it automatically trades cryptocurrencies for the user.

Each bot starts with a set amount of coins and attempts to increase its value by making profitable trades. Bots can implement different strategies provided by the platform. Strategies take advantage of volatility, so bots are (hopefully) able to profit in any kind of market condition. For example, a basic strategy is to set a buy order at 1% below the current price. When the buy order is executed, a sell order is placed 1% above the current price. The process is repeated over and over again.

The application consists of two parts — a front-end website where the user can create bots and monitor their performance, and a backend that is responsible for running the bots.

There are 3 steps to creating the bots:
1. Connect a cryptocurrency exchange (such as Coinbase or Binance) to your account
2. Create a campaign
3. Create and add bots to the campaign

To begin, the user goes to the website and creates an account. Then they select which exchange they want their bots to trade on, such as Coinbase or Binance. They authorize the Crypto Trading Bots application to trade on their behalf. This is done by entering an API key provided by the exchange. This is a unique key that allows a third party to trade on the user’s behalf.

The next step is to create a campaign. A campaign controls one or more bots that actively trade a certain coin. To create a campaign, the user selects an exchange, a trading pair (such as Bitcoin/Ethereum), and a maximum price. The maximum price determines when the campaign ends. When the coin’s price reaches or exceeds the maximum price, all bots in the campaign are immediately deactivated. The purpose of the maximum price is to provide a fail-safe in case the coin price gets too high. A campaign can be thought of as a fund, where multiple bots attempt different strategies based on market conditions and attempt to increase the value of the fund. Users can run multiple campaigns simultaneously.

Next, the user adds bots to the campaign. When creating a bot the user selects the bot’s attributes, such as strategy and buy/sell percentage values. There are currently 17 strategies to choose from. The user also sets the bot’s initial coin amount. This is the amount of coins the bot starts trading with. After a bot is created, it is automatically activated by the platform and starts trading.

The bots function by running at set time intervals. Every two minutes a bot “wakes up” and runs its strategy. First, the bot retrieves the status of its current order from the exchange. If it’s a buy order and it’s successfully filled, the bot then places a sell order based on its strategy. If it’s a sell order that is successfully filled, the bot recalculates its coin amount to reflect the profit and places a buy order. However, if the order has not been filled, the bot checks to see if it should adjust its order price. For example, if the bot’s buy order is placed at 2% below the current price,
but the current price has climbed higher, the bot will increase its order price until it’s back at 2% below the new current price.

The bots utilize trading data to run their strategies. Simple trading data is pulled from the exchanges and more sophisticated trading data is pulled from a site called CryptoCompare.

Having bots place trades (instead of manually doing it yourself) is advantageous for a few reasons. A bot can continuously trade for 24 hours, so while you’re sleeping your bot can make money for you. Also, bots are not prone to irrational human behavior — by following a logical, automated process the bot stays disciplined.
