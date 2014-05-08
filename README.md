# Short description

This is a script that can automatically make trades on the exchange btc-e.com, through its standard api. This bot collects data at current prices BTC/USD, BTC/RUR, USD/RUR and analyzes the situation. If the arbitration is possible to make a profit, bot create suitable orders.

## Requirements

1 ruby 1.9 or higher

2 gem btce

Strongly recommended to install patched version of btce gem (https://github.com/Fotom/ruby-btce-fix-nonce) or make this monkey patchin on original gem.

## Installation

1 git clone https://github.com/Fotom/btce-arbitrage.git

2 cp btce-api-key.yml.sample btce-api-key.yml

3 add self key and secret from btc-e.com site into file btce-api-key.yml

## Run

### Quick

If you want quck run bot for real trading, then execute in command line:

```ruby
ruby api.rb --start_trading --loop
```

### Detail

api.rb can take additional parameters to run, which allows him to work in different modes.

Without params script simple make one step and check bid and ask for currencies and estimate available profit

```ruby
--config take bid and ask for currencies from predefined file (example: ruby api.rb --config config/config_for_preorder.yml). No real trading, you can test script and various situation with bid/ask for currency.

--start_trading bot can create orders and make real trading

--loop run in a loop

--debug display additional debug info
```

If you want run script as daemon with redirect output into log file, then run as:

```ruby
ruby api.rb --start_trading --loop > log/api.log &
```

Additionally script has minimalistic trading log for tracking: log/trading.log

### Trading logic

1 Check bid/ask for pairs BTC/RUR, BTC/USD, USD/RUR from btc-e.com through api

2 Calculate possible profit for operation:
```ruby
    1) Buy BTC by RUR
    2) Sell BTC by USD
    3) Sell USD by RUR
```
  Make trade if money win delta more predefined limit (set in lib/constants.rb). Taking into account the exchange commission

3 Calculate possible profit for preset order (same actions as in 2 step). Created order cannot be execute immediately. Preset order price set for positive win delta. We're just waiting for execution of the order at the suitable price

4 Create suitable orders, wait execution, logging trade

5 Next loop

### Features

Flexible set trading options. In file: lib/constants.rb. Important constant TRADING_AMOUNT_IN_BTC - this is amount of money that will be available for trading bot.

Take into account exchange commission.

Correct action in partial order execution.

Random pricing for preorder.

Permanent recheck win delta for created order, cancell order if win delta < 0.

### Some Clarifications

In december 2013 this bot work 24x7. At that time, was a very large volume of trades. BTC price jumped very significantly.
But profit was not big, about 30-60 RUR per day.

In current time the situation became worse.

You can use this bot at your own risk.
