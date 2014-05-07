class ArbitrageRURPreorder
  attr_accessor :arbitrage, :ask_value

  MULTIPLIERS = [0.3, 0.25, 0.35, 0.4, 0.45, 0.5]

  def initialize(arbitrage)
    self.arbitrage = arbitrage
  end

  def calc_ask_value!
    virtual_delta = self.arbitrage.probably_win_delta.to_i * MULTIPLIERS.sample
    self.ask_value = self.arbitrage.max_btc_rur_bid - virtual_delta
  end

  def trading_rur_start
    raise 'empty ask_value' unless self.ask_value
    Currency.new(Constants::TRADING_AMOUNT_IN_BTC * self.ask_value)
  end

end
