# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

bills = YAML.load_file(Rails.root.join('db/seeds/bills.yml'))

bills.each do |bill_data|
  paper = Paper.find_or_initialize_by(name: bill_data['name'])

  elements_hash = {}
  bill_data['elements'].each do |element|
    elements_hash[element['name']] = element.except('name')
  end

  paper.elements = elements_hash

  front_image_path = Rails.root.join('app', bill_data['image_front_url'])
  if File.exist?(front_image_path)
    paper.image_front.attach(
      io: File.open(front_image_path),
      filename: File.basename(front_image_path)
    )
    puts "Attached front image for #{paper.name}"
  else
    puts "Warning: Front image not found at #{front_image_path}"
  end

  back_image_path = Rails.root.join('app', bill_data['image_back_url'])
  if File.exist?(back_image_path)
    paper.image_back.attach(
      io: File.open(back_image_path),
      filename: File.basename(back_image_path)
    )
    puts "Attached back image for #{paper.name}"
  else
    puts "Warning: Back image not found at #{back_image_path}"
  end

  paper.save!
  puts "Created paper: #{paper.name}"
end
