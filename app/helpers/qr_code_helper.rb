module QrCodeHelper
  private

  def format_amount(amount)
    return nil unless amount
    # Convert to decimal and remove trailing zeros
    amount.to_d.to_s("F")
  end
end
