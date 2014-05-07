class Ticker

  def self.create(pair, h = {})
    Option.config ? FakeTicker.new(Option.config[pair]) : Btce::Ticker.new(pair)
  end

end

class FakeTicker
  attr_accessor :buy, :sell

  def initialize(h = {})
    h.each do |k,v|
      instance_variable_set("@#{k}", v.to_f) if not v.nil?
    end
  end

end
