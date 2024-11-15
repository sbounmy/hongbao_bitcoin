# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Get all image files from the papers directory
paper_files = Dir.glob(Rails.root.join('app', 'assets', 'images', 'papers', '*'))

paper_files.each_with_index do |file_path, index|
  filename = File.basename(file_path)
  name = File.basename(file_path, '.*').titleize

  # Skip if paper with this name already exists
  next if Paper.exists?(name: name)

  paper = Paper.new(name: name)
  paper.position = index + 1

  # Only attach image for new records
  paper.image.attach(
    io: File.open(file_path),
    filename: filename,
    content_type: Marcel::MimeType.for(file_path)
  )

  paper.save!
  puts "Created paper: #{name}"
end
