class ArbitrageRUR < Arbitrage

  def self.trading_btc_for_usd_amount(h = {})
    (h[:btc_amount] || Constants::TRADING_AMOUNT_IN_BTC)*(1-Constants::TRADING_TAX)
  end

  def start_trading_rur_amount
    Constants::TRADING_AMOUNT_IN_BTC*self.btc_rur_bid
  end

  def trading_usd_rur_amount(h = {})
    btc_amount = (h[:btc_amount] || ArbitrageRUR.trading_btc_for_usd_amount)
    usd = Currency.new(btc_amount).sell(self.btc_usd_ask).pay_tax
    usd.amount
  end

  def win(h = {})
    rur_start = h[:rur_start] || self.rur_start

    btc = rur_start.buy(self.btc_rur_bid).pay_tax
    usd = btc.sell(self.btc_usd_ask).pay_tax
    rur = usd.sell(self.usd_rur_ask).pay_big_tax

    rur.amount - rur_start.amount
  end

  def real_win
    self.win(:rur_start => Currency.new(Constants::TRADING_AMOUNT_IN_BTC * self.btc_rur_bid))
  end

  def max_btc_rur_bid
    rur = self.rur_start
    usd = rur.return_big_tax.sell_rollback(self.usd_rur_ask)
    btc = usd.return_tax.sell_rollback(self.btc_usd_ask)

    self.rur_start.amount/btc.return_tax.amount
  end

  # minimum ask for btc usd, in which order offered in btc rur can pay for itself
  def min_btc_usd_ask
    rur = Currency.new(self.rur_start.amount + Constants::TRADING_DEFENSE_LIMIT)
    usd = rur.return_big_tax.sell_rollback(self.usd_rur_ask)
    btc = self.rur_start.buy(self.btc_rur_bid).pay_tax

    usd.return_tax.amount/btc.amount
  end

  def probably_win_delta
    self.max_btc_rur_bid - self.btc_rur_ask
  end

  def win_is_possible?
    probably_win_delta > 0
  end

  def is_win?
    self.win > 0
  end

  def is_profitable_now?
    is_win? && is_sufficient_profit?(self.win)
  end

  def is_profitable_preorder?
    win_is_possible? && is_sufficient_profit?(probably_win_delta)
  end

end
