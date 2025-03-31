# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Set fixtures path
ENV['FIXTURES_PATH'] = 'spec/fixtures'

# Load papers and styles from fixtures
puts "Loading papers and styles from fixtures..."
Rake::Task["db:fixtures:load"].invoke("FIXTURES=papers,ai/styles")

# Load payment methods from YAML
payment_methods = YAML.load_file(Rails.root.join('db/seeds/payment_methods.yml'))['payment_methods']

payment_methods.each do |attributes|
  pm = PaymentMethod.find_or_initialize_by(name: attributes['name'])
  pm.logo.attach(
    io: File.open(Rails.root.join("app/assets/images/payment-methods/#{attributes['logo']}")),
    filename: attributes['logo']
  )
  pm.instructions = attributes['instructions'].join("\n")
  pm.save!
end

puts "Created #{PaymentMethod.count} payment methods"

# Attach preview images for styles if they don't exist
Ai::Style.find_each do |style|
  next if style.preview_image.attached?

  # Look for preview images in spec/fixtures/files
  image_path = Rails.root.join('spec', 'fixtures', 'files', 'ai', 'styles', "#{style.title.parameterize(separator: '_')}.jpg")
  if File.exist?(image_path)
    style.preview_image.attach(
      io: File.open(image_path),
      filename: "#{style.title.parameterize(separator: '_')}.jpg",
      content_type: 'image/jpeg'
    )
    puts "Attached preview image for #{style.title}"
  else
    puts "Warning: Preview image not found at #{image_path}"
  end
end

# Attach images for papers if they don't exist
Paper.find_each do |paper|
  unless paper.image_front.attached?
    front_image_path = Rails.root.join('spec', 'fixtures', 'files', 'papers', "#{paper.name.parameterize(separator: '_')}_front.jpg")
    if File.exist?(front_image_path)
      paper.image_front.attach(
        io: File.open(front_image_path),
        filename: "#{paper.name.parameterize(separator: '_')}_front.jpg"
      )
      puts "Attached front image for #{paper.name}"
    else
      puts "Warning: Front image not found at #{front_image_path}"
    end
  end

  unless paper.image_back.attached?
    back_image_path = Rails.root.join('spec', 'fixtures', 'files', 'papers', "#{paper.name.parameterize(separator: '_')}_back.jpg")
    if File.exist?(back_image_path)
      paper.image_back.attach(
        io: File.open(back_image_path),
        filename: "#{paper.name.parameterize(separator: '_')}_back.jpg"
      )
      puts "Attached back image for #{paper.name}"
    else
      puts "Warning: Back image not found at #{back_image_path}"
    end
  end

  paper.save!
end
