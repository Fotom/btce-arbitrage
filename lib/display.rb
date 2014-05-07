class Display

  def self.signed(value)
    value.to_f > 0 ? Color.green(value.to_s) : Color.red(value.to_s)
  end

  def self.boolean(value)
    value ? Color.green(value.to_s) : Color.red(value.to_s)
  end

end
