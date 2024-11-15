module HongBaosHelper
  def number_to_btc(amount)
    number_with_precision(amount, precision: 8, delimiter: ",")
  end
end
