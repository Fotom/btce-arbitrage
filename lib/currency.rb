class Currency
  attr_accessor :amount

  def initialize(amount)
    self.amount = amount.to_f
  end

  def buy(bid)
    Currency.new(self.amount/bid.to_f)
  end
  def buy_rollback(bid)
    sell(bid)
  end

  def sell(ask)
    Currency.new(self.amount*ask.to_f)
  end
  def sell_rollback(ask)
    buy(ask)
  end

  def pay_big_tax
    pay_tax({:tax => Constants::TRADING_STRANGE_TAX})
  end
  def pay_tax(h = {})
    tax = h[:tax] || Constants::TRADING_TAX
    Currency.new(self.amount*(1 - tax))
  end

  def calc_big_tax
    calc_tax({:tax => Constants::TRADING_STRANGE_TAX})
  end
  def calc_tax(h = {})
    tax = h[:tax] || Constants::TRADING_TAX
    Currency.new(self.amount*tax)
  end

  def return_big_tax
    return_tax({:tax => Constants::TRADING_STRANGE_TAX})
  end
  def return_tax(h = {})
    tax = h[:tax] || Constants::TRADING_TAX
    Currency.new(self.amount/(1 - tax))
  end

end
