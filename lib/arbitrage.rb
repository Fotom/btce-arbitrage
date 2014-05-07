class Arbitrage
  attr_accessor :btc_usd_bid, :btc_usd_ask, :btc_rur_bid, :btc_rur_ask, :usd_rur_bid, :usd_rur_ask, :rur_start

  def initialize(h = {})
    h.each do |k,v|
      instance_variable_set("@#{k}", (k.to_s == 'rur_start' ? v : v.to_f)) if not v.nil?
    end
  end

  def is_sufficient_profit?(amount)
    amount > Constants::MIN_ALLOWED_TRADING_WIN_DELTA
  end
end
