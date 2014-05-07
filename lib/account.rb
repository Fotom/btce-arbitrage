class Account

  attr_accessor :info

  def initialize(h = {})
  end

  def get_info
    resp = Btce::TradeAPI.new_from_keyfile.get_info
    if !resp || !resp["success"] || (resp["success"] != 1)
      raise "incorrect info for resp: #{resp}"
    end
    self.info = resp["return"]
    self
  end

  def refresh
    get_info
    self
  end

  def to_human
    "rur: #{self.info['funds']['rur']}, usd: #{self.info['funds']['usd']}, btc: #{self.info['funds']['btc']}"
  end

  def has_rur?(amount)
    self.info['funds']['rur'].to_f >= amount.to_f
  end

end