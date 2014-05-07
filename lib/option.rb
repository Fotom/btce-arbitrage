class Option

  @@options = {}

  def self.parse!
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: [options]"

      opts.on("--config N", String) do |v|
        options[:config] = v
      end
      opts.on("--positions_file N", String) do |v|
        options[:positions_file] = v
      end
      opts.on("--start_trading") do |v|
        options[:start_trading] = true
      end
      opts.on("--debug") do |v|
        options[:debug] = true
      end
      opts.on("--loop") do |v|
        options[:loop] = true
      end
    end.parse!
    Option.create(options)
  end

  def self.create(options)
    @@options = options
  end

  def self.config
    return YAML.load_file(@@options[:config]) if @@options[:config]
    false
  end

  def self.method_missing(meth, *args, &block)
    if meth.to_s =~ /^(?:check|is)_([^?]+)\??$/
      if @@options.has_key?($1.to_sym)
        return @@options[$1.to_sym]
      else
        return false
      end
    else
      super
    end
  end

end
