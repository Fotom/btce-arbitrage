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

-- without params script simple make one step and check bid and ask for currencies and estimate available profit

--config take bid and ask for currencies from predefined file (example: ruby api.rb --config config/config_for_preorder.yml). No real trading, you can test script and various situation with bid/ask for currency.

--start_trading bot can create orders and make real trading

--loop run in a loop

--debug display additional debug info

If you want run script as daemon with redirect output into log file, then run as:

```ruby
ruby api.rb --start_trading --loop > log/api.log &
```

Additionally script has minimalistic trading log for tracking: log/trading.log

### Trading logic

in progress...
