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
fixtures = (ENV['FIXTURES'] || 'papers,ai/styles,ai/themes').split(',')

# Load papers and styles from fixtures
puts "Loading #{fixtures.join(', ')} from fixtures..."
Rake::Task["db:fixtures:load"].invoke(fixtures.join(','))

def attach(object, field, name, folders, suffix = nil)
  unless object.send(name).attached?
    title = object.send(field)
    image_path = Rails.root.join('spec', 'fixtures', 'files', *folders, "#{title.parameterize(separator: '_')}#{suffix ? "_#{suffix}" : ""}.jpg")
    if File.exist?(image_path)
      object.send(name).attach(
        io: File.open(image_path),
        filename: "#{title.parameterize(separator: '_')}_#{suffix}.jpg"
      )
      puts "Attached #{name} image for #{title}"
    else
      puts "Warning: #{name} image not found at #{image_path}"
    end
  end
end



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
end if fixtures.include?('payment_methods')



# Attach preview images for styles if they don't exist
Ai::Style.find_each do |style|
  attach(style, :title, :preview_image, [ 'ai', 'styles' ])
end if fixtures.include?('ai/styles')

# Attach images for papers if they don't exist
Paper.find_each do |paper|
  attach(paper, :name, :image_front, [ 'papers' ], "front")
  attach(paper, :name, :image_back, [ 'papers' ], "back")

  paper.save!
end if fixtures.include?('papers')

Ai::Theme.find_each do |theme|
  attach(theme, :path, :hero_image, [ 'ai', 'themes' ], "hero")
  theme.save!
end if fixtures.include?('ai/themes')
