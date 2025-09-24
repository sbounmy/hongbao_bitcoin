class ImportProductsFromStripe < ActiveRecord::Migration[8.0]
  def up
    puts "Importing products from Stripe..."

    # Create Option Types if they don't exist
    size_type = OptionType.find_or_create_by!(name: "size") do |ot|
      ot.presentation = "Size"
      ot.position = 1
    end

    color_type = OptionType.find_or_create_by!(name: "color") do |ot|
      ot.presentation = "Color"
      ot.position = 2
    end

    # Create Size Option Values
    mini_value = size_type.option_values.find_or_create_by!(name: "mini") do |ov|
      ov.presentation = "Mini"
      ov.position = 1
    end

    family_value = size_type.option_values.find_or_create_by!(name: "family") do |ov|
      ov.presentation = "Family"
      ov.position = 2
    end

    maximalist_value = size_type.option_values.find_or_create_by!(name: "maximalist") do |ov|
      ov.presentation = "Maximalist"
      ov.position = 3
    end

    # Create Color Option Values
    red_value = color_type.option_values.find_or_create_by!(name: "red") do |ov|
      ov.presentation = "Red"
      ov.hex_color = "#DC2626"
      ov.position = 1
    end

    orange_value = color_type.option_values.find_or_create_by!(name: "orange") do |ov|
      ov.presentation = "Orange"
      ov.hex_color = "#EA580C"
      ov.position = 2
    end

    green_value = color_type.option_values.find_or_create_by!(name: "green") do |ov|
      ov.presentation = "Green"
      ov.hex_color = "#16A34A"
      ov.position = 3
    end

    purple_value = color_type.option_values.find_or_create_by!(name: "purple") do |ov|
      ov.presentation = "Purple"
      ov.hex_color = "#9333EA"
      ov.position = 4
    end

    # Fetch products from Stripe
    begin
      stripe_products = StripeService.fetch_products
      puts "Found #{stripe_products.size} products from Stripe"
    rescue => e
      puts "Warning: Could not fetch Stripe products: #{e.message}"
      return
    end

    # Map Stripe products to our product structure
    stripe_products.each_with_index do |stripe_product, index|
      puts "Importing: #{stripe_product[:name]}"

      # Determine size value based on slug
      size_value = case stripe_product[:slug]
      when "mini" then mini_value
      when "family" then family_value
      when "maximalist" then maximalist_value
      else
        puts "  Unknown product slug: #{stripe_product[:slug]}"
        next
      end

      # Find or create product
      product = Product.find_or_initialize_by(slug: stripe_product[:slug])

      product.assign_attributes(
        name: stripe_product[:name],
        description: stripe_product[:description],
        meta_description: "#{stripe_product[:name]} - #{stripe_product[:description]}. Perfect Bitcoin gift for beginners.",
        metadata: {
          envelopes_count: stripe_product[:envelopes],
          tokens_count: stripe_product[:tokens]
        },
        stripe_product_id: stripe_product[:stripe_product_id],
        option_type_ids: [ size_type.id, color_type.id ],
        position: index,
        published_at: Time.current
      )

      product.save!
      puts "  Created/Updated product: #{product.name}"

      # Color configurations for image folders
      color_configs = [
        { value: red_value, folder: "001_red", is_master: true },
        { value: orange_value, folder: "002_orange", is_master: false },
        { value: green_value, folder: nil, is_master: false },
        { value: purple_value, folder: nil, is_master: false }
      ]

      # Create variants for each color
      color_configs.each_with_index do |color_config, color_index|
        sku = "#{stripe_product[:slug].upcase}-#{color_config[:value].name.upcase}"

        # Try to find by SKU first, then by option values
        variant = product.variants.find_by(sku: sku) ||
                  product.variants.find_or_initialize_by(
                    option_value_ids: [ size_value.id, color_config[:value].id ]
                  )

        variant.assign_attributes(
          sku: sku,
          price: stripe_product[:price],
          stripe_price_id: color_config[:is_master] ? stripe_product[:stripe_price_id] : nil,
          is_master: color_config[:is_master],
          position: color_index,
          option_value_ids: [ size_value.id, color_config[:value].id ]
        )

        variant.save!
        puts "    Created/Updated variant: #{variant.sku}"

        # Attach images if folder exists and variant doesn't have images
        if color_config[:folder] && variant.images.empty?
          image_dir = Rails.root.join("app/assets/images/plans", stripe_product[:slug], color_config[:folder])
          if Dir.exist?(image_dir)
            puts "      Attaching images from #{color_config[:folder]}..."
            image_files = Dir.glob(image_dir.join("*.{jpg,jpeg,png}")).sort

            image_files.each do |image_path|
              variant.images.attach(
                io: File.open(image_path),
                filename: File.basename(image_path),
                content_type: "image/jpeg"
              )
              puts "        Attached: #{File.basename(image_path)}"
            end
          end
        end
      end

      # Set master variant if not set
      if product.master_variant.nil?
        master = product.variants.find_by(is_master: true) || product.variants.first
        product.update!(master_variant: master)
        puts "  Set master variant: #{master.sku}"
      end
    end

    puts "\nStripe import completed!"
    puts "Products: #{Product.count}"
    puts "Variants: #{Variant.count}"
  end

  def down
    # Optional: Add logic to reverse the migration if needed
    puts "Rollback not implemented for this migration"
  end
end
