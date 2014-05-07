class Color

  def self.red(msg)
    "\e[31m" + msg + "\e[0m"
  end

  def self.green(msg)
    "\e[32m" + msg + "\e[0m"
  end

  def self.blue(msg)
    "\e[1;34m" + msg + "\e[0m"
  end

  def self.white(msg)
    "\e[1;37m" + msg + "\e[0m"
  end

  def self.yellow(msg)
    "\e[1;33m" + msg + "\e[0m"
  end

  def self.sea(msg)
    "\e[1;36m" + msg + "\e[0m"
  end

  def self.magenta(msg)
    "\e[1;35m" + msg + "\e[0m"
  end

end