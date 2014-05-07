class Trade
  attr_accessor :orders, :btc_rur_order_id, :btc_usd_order_id, :usd_rur_order_id, :arbitrage, :preorder, :trading_btc_partial_amount

  BUY  = 'buy'
  SELL = 'sell'

  def self.run(account, arbitrage, preorder = nil)
    trade = Trade.new({:arbitrage => arbitrage, :preorder => preorder})
    # allow trade with multiple orders:
    # trade.get_orders!
    # raise 'already exists order' if trade.has_orders?

    if !account.has_rur?(trade.arbitrage.start_trading_rur_amount)
      puts Color.red("NOT ENOUGH RUR NOW: #{account.info['funds']['rur']}, NEED: #{trade.arbitrage.start_trading_rur_amount}")
      return
    end

    trade.create_btc_rur_order!({
      :pair => Constants::BTC_RUR,
      :rate => trade.order_ask_value.round(5),
      :amount => Constants::TRADING_AMOUNT_IN_BTC})

    trade.wait_btc_rur_order_executed
  end

  def initialize(h = {})
    self.orders = {}
    self.arbitrage = h[:arbitrage]
    self.preorder = h[:preorder]
  end

  def get_orders
    resp = Btce::TradeAPI.new_from_keyfile.active_orders
    puts 'try get_orders'
    puts "get_orders resp: #{resp.to_s}"
    return false if !resp || !resp["success"]
    if resp["success"] == 1
      return resp
    elsif (resp["success"] == 0) && (resp["error"] == 'no orders')
      return {"return" => {}}
    else
      return false
    end
  end

  def get_orders!
    resp = nil
    while true do
      sleep(1.0/5.0)
      time = Time.now.to_i
      resp = self.get_orders
      break if resp
    end
    self.orders = resp["return"]
  end

  def has_orders?
    self.orders.keys.size > 0
  end

  def exists_btc_rur_order?
    exists_order?(self.btc_rur_order_id)
  end
  def exists_btc_usd_order?
    exists_order?(self.btc_usd_order_id)
  end
  def exists_usd_rur_order?
    exists_order?(self.usd_rur_order_id)
  end

  def exists_order?(id)
    self.orders.each do |k,v|
      return true if k.to_i == id.to_i
    end
    return false
  end

  def btc_rur_order_partial_executed?
    puts 'self.orders'
    puts self.orders.inspect
    puts self.orders[self.btc_rur_order_id.to_s].inspect
    return self.orders[self.btc_rur_order_id.to_s]["amount"].to_f == Constants::TRADING_AMOUNT_IN_BTC.to_f ? false : true
  end

  def set_trading_btc_partial_amount
    self.trading_btc_partial_amount = Constants::TRADING_AMOUNT_IN_BTC.to_f - self.orders[self.btc_rur_order_id.to_s]["amount"].to_f
  end

  def remove_trading_btc_partial_amount
    self.trading_btc_partial_amount = nil
  end

  def create_btc_rur_order!(h = {})
    resp = self.create_order!(h)
    self.btc_rur_order_id = resp["return"]["order_id"]
  end

  def create_order!(h = {})
    resp = create_order(h)
    raise "Cannot create order" if not resp
    return resp
  end

  def create_order(h = {})
    if not ([:pair, :rate, :amount] - h.keys).empty?
      puts 'empty params for create order'
      return false
    end
    resp = Btce::TradeAPI.new_from_keyfile.trade({
      :pair => h[:pair],
      :type => (h[:type] || BUY),
      :rate => h[:rate],
      :amount => h[:amount]
    })
    puts 'empty response on create order' if not resp
    if !resp || !resp["success"] || (resp["success"] != 1)
      puts 'not success response on create order: ' + resp.inspect.to_s
      return false
    end
    puts Color.green("Order created: #{resp.inspect}")
    File.open(Constants::TRADING_LOG_FILE, 'a') do |f|
      f.puts(resp)
    end
    return resp
  end

  def wait_btc_rur_order_executed
    while true do
      sleep(1.0/5.0)
      time = Time.now.to_i
      puts time.to_s + " wait btc rur order is executed"
      self.get_orders!
      is_order_executed = false
      if self.has_orders? && self.exists_btc_rur_order?
        # check on partial execution
        if self.btc_rur_order_partial_executed?
          puts Color.green('buy btc by rur order PARTIAL executed')
          self.set_trading_btc_partial_amount
          cancel_status = self.cancel_btc_rur_order!({:message => 'Cancelled by partial executed'})
          self.remove_trading_btc_partial_amount if cancel_status == 'already_executed'
          if self.is_very_low_btc_amount?
            puts Color.red('very low btc amount, order cancelled')
          else
            self.start_create_btc_usd_order
          end
          break
        end
        puts 'orders exists'
        # TODO: add check usd/rur now
        if self.is_btc_usd_ask_go_down?
          cancel_status = self.cancel_btc_rur_order!({:message => 'Cancelled by btc_usd is going down'})
          is_order_executed = true if cancel_status == 'already_executed'
          break if not is_order_executed
        end
        if !is_order_executed && self.is_btc_rur_ask_go_up?
          cancel_status = self.cancel_btc_rur_order!({:message => 'Cancelled by btc_rur ask is going up'})
          is_order_executed = true if cancel_status == 'already_executed'
          break if not is_order_executed
        end
      end
      if !self.has_orders? || !self.exists_btc_rur_order? || is_order_executed
        puts Color.green('buy btc by rur order executed')
        self.start_create_btc_usd_order
        break
      end
    end
  end

  def is_very_low_btc_amount?
    self.trading_btc_partial_amount && (self.trading_btc_partial_amount.to_f < Constants::MIN_PARTIAL_BTC_TRADING_AMOUNT.to_f) ? true : false
  end

  def start_create_btc_usd_order
    # TODO: rount(5) and trunc(5) - some hardcode for compatibility btc-e api format
    #   maybe there is more elegant solution?
    self.create_btc_usd_order_anyway({
      :type => SELL,
      :pair => Constants::BTC_USD,
      :rate => self.arbitrage.btc_usd_ask.round(5),
      :amount => self.real_trading_btc_for_usd_amount.trunc(5)})
    self.wait_btc_usd_order_executed
  end

  def real_trading_btc_for_usd_amount
    if self.trading_btc_partial_amount
      after_tax = ArbitrageRUR.trading_btc_for_usd_amount({:btc_amount => self.trading_btc_partial_amount})
      return after_tax < Constants::MIN_ALLOWED_BTC_TRADING_AMOUNT ? Constants::MIN_ALLOWED_BTC_TRADING_AMOUNT : after_tax
    else
      return ArbitrageRUR.trading_btc_for_usd_amount
    end
  end

  def wait_btc_usd_order_executed
    while true do
      sleep(1.0/5.0)
      time = Time.now.to_i
      puts time.to_s + " wait btc usd order is executed"
      self.get_orders!
      if self.has_orders? && self.exists_btc_usd_order?
        puts 'orders exists'
        # check condition for resell now anyway
      else
        puts Color.green('sell btc by usd order executed')
        self.start_create_usd_rur_order
        break
      end
    end
  end

  def start_create_usd_rur_order
    self.create_usd_rur_order_anyway({
      :type => SELL,
      :pair => Constants::USD_RUR,
      :rate => self.arbitrage.usd_rur_ask.round(5),
      :amount => self.real_trading_usd_rur_amount.trunc(5)})

    # TODO: fix or remove comments
    #   force exit from script, need check end rur and usd amount
    if self.trading_btc_partial_amount
      puts Color.red "Not expected partial order executed, check sell usd by rur correct and executed"
      # exit
    end

    self.wait_usd_rur_order_executed if false # no wait usd rur order, try next trading
  end

  def real_trading_usd_rur_amount
    if self.trading_btc_partial_amount
      return self.arbitrage.trading_usd_rur_amount({:btc_amount => self.real_trading_btc_for_usd_amount})
    else
      return self.arbitrage.trading_usd_rur_amount
    end
  end

  def wait_usd_rur_order_executed
    while true do
      sleep(1.0/5.0)
      time = Time.now.to_i
      puts time.to_s + " wait usd rur order is executed"
      self.get_orders!
      if self.has_orders? && self.exists_usd_rur_order?
        puts 'orders exists'
      else
        puts Color.green('sell usd by rur order executed')
        break
      end
    end
  end

  def is_btc_usd_ask_go_down?
    ticker = Btce::Ticker.new(Constants::BTC_USD)
    puts 'btc_usd sell: ' + ticker.sell.to_s + " [limit: #{self.arbitrage.min_btc_usd_ask.trunc(2)}]"
    ticker.sell <= self.arbitrage.min_btc_usd_ask
  end

  def is_btc_rur_ask_go_up?
    ticker = Btce::Ticker.new(Constants::BTC_RUR)
    puts 'btc_rur sell: ' + ticker.sell.to_s + " [limit: #{self.order_ask_value.trunc(2)}, bid: #{ticker.buy}]"
    ticker.sell > self.order_ask_value.round(5)
  end

  def order_ask_value
    self.preorder ? self.preorder.ask_value : self.arbitrage.btc_rur_bid
  end

  def create_usd_rur_order_anyway(h = {})
    resp = self.create_order_anyway(h)
    self.usd_rur_order_id = resp["return"]["order_id"]
  end
  def create_btc_usd_order_anyway(h = {})
    resp = self.create_order_anyway(h)
    self.btc_usd_order_id = resp["return"]["order_id"]
  end

  def create_order_anyway(h = {})
    resp = nil
    while true do
      sleep(1.0/5.0)
      time = Time.now.to_i
      puts Color.yellow("[#{time}] try create order anyway")
      resp = self.create_order(h)
      break if resp
    end
    return resp
  end

  def cancel_btc_rur_order!(h = {})
    puts 'Try cancel btc rur order'
    status = self.cancel_order!(self.btc_rur_order_id)
    self.btc_rur_order_id = nil
    puts h[:message]
    return status
  end

  def cancel_order!(id)
    status = 'cancelled'
    while true do
      sleep(1.0/5.0)
      time = Time.now.to_i
      puts time.to_s + " try cancel order"
      cancel_resp = self.cancel_order(id)
      if cancel_resp
        status = cancel_resp if cancel_resp.to_s != 'true'
        break
      end
    end
    return status
  end

  def cancel_order(id)
    resp = Btce::TradeAPI.new_from_keyfile.cancel_order({:order_id => id})
    puts 'empty response on cancel order' if not resp
    if !resp || !resp["success"]
      puts resp.inspect
      return false
    end
    if resp["success"] == 1
      return true
    end
    if (resp["success"] == 0) && (resp["error"] == "bad status")
      puts resp.inspect
      return 'already_executed'
    end
    File.open(Constants::TRADING_LOG_FILE, 'a') do |f|
      f.puts(resp)
    end
    return true
  end

end