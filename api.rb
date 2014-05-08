require 'btce'
require 'optparse'
require 'yaml'
require './lib/color'
require './lib/constants'
require './lib/currency'
require './lib/arbitrage'
require './lib/arbitrage_rur'
require './lib/arbitrage_usd'
require './lib/arbitrage_rur_preorder'
require './lib/display'
require './lib/ticker'
require './lib/trade'
require './lib/float'
require './lib/option'
require './lib/account'

Option.parse!

def start
  account = Account.new.get_info
  puts account.to_human

  ticker_btc_usd = Ticker.create("btc_usd")
  ticker_btc_rur = Ticker.create("btc_rur")
  ticker_usd_rur = Ticker.create("usd_rur")

  puts Color.yellow '===== START ====='
  puts "BTC USD: bid: #{ticker_btc_usd.buy}, ask: #{ticker_btc_usd.sell}"
  puts Color.blue "BTC USD: bid: #{(ticker_btc_usd.buy.to_f*ticker_usd_rur.sell.to_f).trunc(2)}, ask: #{(ticker_btc_usd.sell.to_f*ticker_usd_rur.sell.to_f).trunc(2)} in RUR [#{(ticker_btc_usd.buy.to_f*ticker_usd_rur.buy.to_f).trunc(2)}, #{(ticker_btc_usd.sell.to_f*ticker_usd_rur.buy.to_f).trunc(2)}]"
  puts Color.blue "BTC RUR: bid: #{ticker_btc_rur.buy}, ask: #{ticker_btc_rur.sell}"
  puts "USD RUR: bid: #{ticker_usd_rur.buy}, ask: #{ticker_usd_rur.sell}"
  puts '================='

  params = {
    :rur_start => Currency.new(Constants::RUR_AMOUNT_START),
    :btc_usd_bid => ticker_btc_usd.buy,
    :btc_usd_ask => ticker_btc_usd.sell,
    :btc_rur_bid => ticker_btc_rur.buy,
    :btc_rur_ask => ticker_btc_rur.sell,
    :usd_rur_bid => ticker_usd_rur.buy,
    :usd_rur_ask => ticker_usd_rur.sell
  }

  arbitrage_rur = ArbitrageRUR.new(params)
  arbitrage_usd = ArbitrageUSD.new(params)

  puts 'Btc buy by rur sell by usd WIN: ' + arbitrage_rur.win.to_s + ' rur'
  puts 'Btc buy by usd sell by rur WIN: ' + arbitrage_usd.win.to_s + ' rur'

  puts '================='
  puts 'Min ask btc price in rur for WIN > 0: ' + arbitrage_rur.max_btc_rur_bid.to_s + ' rur'
  puts 'Win is possible: ' + arbitrage_rur.win_is_possible?.to_s
  puts 'Delta for win = 0: ' + Display.signed(arbitrage_rur.probably_win_delta)

  puts '================='
  puts 'Profit estimation opinion for RUR'
  puts "Profitably now: " + Display.boolean(arbitrage_rur.is_profitable_now?)
  puts "Profitably preorder: " + Display.boolean(arbitrage_rur.is_profitable_preorder?)

  if arbitrage_rur.is_profitable_now?
    puts Color.green('***********')
    puts "Expected profit for (#{Constants::RUR_AMOUNT_START} rur): " +
      arbitrage_rur.win.to_s +
      ", for #{Constants::TRADING_AMOUNT_IN_BTC} btc: " +
      arbitrage_rur.real_win.to_s
    puts 'Logic: '
    puts "    1) Buy BTC (#{Constants::TRADING_AMOUNT_IN_BTC}) by RUR, ask: #{arbitrage_rur.btc_rur_bid}"
    puts "    2) wait order is executed"
    puts "      2.1) cancel order if BTC USD ask <= #{arbitrage_rur.min_btc_usd_ask}"
    puts "      2.2) cancel order if BTC RUR current ask > #{arbitrage_rur.btc_rur_bid}"
    puts "    3) Sell BTC (#{ArbitrageRUR.trading_btc_for_usd_amount}) by USD, ask: #{arbitrage_rur.btc_usd_ask}"
    puts "    4) Sell all USD (#{arbitrage_rur.trading_usd_rur_amount}) by RUR, ask: #{arbitrage_rur.usd_rur_ask}"
    puts Color.green('***********')

    Trade.run(account, arbitrage_rur) if Option.is_start_trading?

  elsif arbitrage_rur.is_profitable_preorder?
    preorder = ArbitrageRURPreorder.new(arbitrage_rur)
    preorder.calc_ask_value!

    params[:btc_rur_bid] = preorder.ask_value # downgrade bid limit to calculated value, expect order will executed by this price
    arbitrage_rur_preorder = ArbitrageRUR.new(params)

    puts Color.sea('***********')
    puts "BTC rur ask to try value: #{preorder.ask_value}"
    puts "Expected profit for (#{Constants::RUR_AMOUNT_START} rur): " +
      arbitrage_rur_preorder.win.to_s +
      ", for #{Constants::TRADING_AMOUNT_IN_BTC} btc: " +
      arbitrage_rur_preorder.win({:rur_start => preorder.trading_rur_start}).to_s
    puts 'Logic: '
    puts "    1) Buy BTC (#{Constants::TRADING_AMOUNT_IN_BTC}) by RUR, ask: #{preorder.ask_value}"
    puts "    2) wait order is executed"
    puts "      2.1) cancel order if BTC USD ask <= #{arbitrage_rur_preorder.min_btc_usd_ask}"
    puts "      2.2) cancel order if BTC RUR current ask > #{preorder.ask_value}"
    puts "    3) Sell BTC (#{ArbitrageRUR.trading_btc_for_usd_amount}) by USD, ask: #{arbitrage_rur_preorder.btc_usd_ask}"
    puts "    4) Sell all USD (#{arbitrage_rur_preorder.trading_usd_rur_amount}) by RUR, ask: #{arbitrage_rur_preorder.usd_rur_ask}"
    puts Color.sea('***********')

    Trade.run(account, arbitrage_rur_preorder, preorder) if Option.is_start_trading?
  end

  puts Color.yellow '===== END ====='

  puts account.refresh.to_human
end


# loop for check btc state and available profit

sleep_time = 3
loop_max_count = (Option.is_loop? ? 1000000 : 0)
loop_count = 0

while true do
  sleep(sleep_time) if loop_count > 0
  time = Time.now.to_i
  puts Color.yellow("[#{time}] START CHECK LOOP")

  start()

  break if loop_count >= loop_max_count
  loop_count += 1
end

puts Color.yellow("[#{time}] END CHECK LOOP")


