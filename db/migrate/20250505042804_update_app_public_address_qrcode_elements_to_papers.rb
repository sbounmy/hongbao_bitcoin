class UpdateAppPublicAddressQrcodeElementsToPapers < ActiveRecord::Migration[8.0]
  def up
    Paper.all.each do |paper|
      if !paper.elements.dig("app_public_address_qrcode", "x").present?
        paper.elements["app_public_address_qrcode"] = {
          "x" => paper.elements.dig("public_address_qrcode", "x") || 0.55,
          "y" => paper.elements.dig("public_address_qrcode", "y") || 0.24,
          "size" => paper.elements.dig("public_address_qrcode", "size") || 0.25,
          "color" => paper.elements.dig("public_address_qrcode", "color") || "224, 120, 1"
        }
        puts "Updating paper #{paper.id} with app_public_address_qrcode = #{paper.elements["app_public_address_qrcode"].inspect}"
        paper.elements["public_address_qrcode"]["hidden"] = true
        paper.save!
      end
    end if defined?(Paper)
  end
end
