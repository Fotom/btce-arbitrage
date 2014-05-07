class ArbitrageUSD < Arbitrage

  def win(h = {})
    usd = self.rur_start.buy(self.usd_rur_bid).pay_big_tax
    if Option.is_debug?
      puts "  I: buy usd by rur (rur_start: #{self.rur_start.amount})"
      puts "    usd virtual: #{self.rur_start.buy(self.usd_rur_bid).amount}, usd real: #{usd.amount}"
      puts "    tax usd: #{self.rur_start.buy(self.usd_rur_bid).calc_big_tax.amount}, tax rur: #{self.rur_start.calc_big_tax.amount}"
    end
    btc = usd.buy(self.btc_usd_bid).pay_tax
    if Option.is_debug?
      puts "  II: buy btc by usd (#{usd.amount})"
      puts "    btc virtual: #{usd.buy(self.btc_usd_bid).amount}, btc real: #{btc.amount}"
      puts "    tax btc: #{usd.buy(self.btc_usd_bid).calc_tax.amount}, tax rur: #{usd.buy(self.btc_usd_bid).calc_tax.amount*self.btc_rur_ask}"
    end
    rur = btc.sell(self.btc_rur_ask).pay_tax
    if Option.is_debug?
      puts "  III: sell btc by rur (#{btc.amount})"
      puts "    rur virtual: #{btc.sell(self.btc_rur_ask).amount}, rur real: #{rur.amount}"
      puts "    tax rur: #{btc.sell(self.btc_rur_ask).calc_tax.amount}"
    end

    rur.amount - self.rur_start.amount
  end

end
