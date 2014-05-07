class Float

  def trunc(precision)
    (self*10**precision).truncate.to_f/10**precision
  end

end