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

# Group files by their base name (without 'front'/'back' suffix)
paper_groups = paper_files.group_by do |file_path|
  filename = File.basename(file_path, '.*')
  filename.gsub(/_?front|_?back/i, '') # Remove front/back suffixes
end

paper_groups.each_with_index do |(base_name, files), index|
  name = base_name.titleize

  # Skip if paper with this name already exists
  next if Paper.exists?(name: name)

  # Find front and back images
  front_image = files.find { |f| f.downcase.include?('front') }
  back_image = files.find { |f| f.downcase.include?('back') }

  if front_image && back_image
    paper = Paper.new(name: name)
    paper.position = index + 1

    # Attach both images
    paper.images.attach([
      {
        io: File.open(front_image),
        filename: File.basename(front_image),
        content_type: Marcel::MimeType.for(front_image)
      },
      {
        io: File.open(back_image),
        filename: File.basename(back_image),
        content_type: Marcel::MimeType.for(back_image)
      }
    ])

    paper.save!
    puts "Created paper: #{name} with front and back images"

    json_filename = name.parameterize(separator: '_').downcase + '.json'
    json_path = Rails.root.join('app', 'assets', 'JSON', json_filename)

    if File.exist?(json_path)
      sample_elements = JSON.parse(File.read(json_path))
      paper.update!(elements: sample_elements)
      puts "Updated elements for paper: #{paper.name} from #{json_filename}"
    else
      puts "Warning: No JSON file found for #{paper.name} at #{json_path}"
      # Optionally fall back to default sample_elements.json
      # sample_elements = JSON.parse(File.read(Rails.root.join('app', 'assets', 'JSON', 'sample_elements.json')))
      # paper.update!(elements: sample_elements)
    end
  else
    puts "Warning: Skipping #{name} - missing front or back image"
  end
end
