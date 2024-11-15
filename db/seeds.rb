# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create default papers
papers = [
  {
    name: 'Bitcoin Bill',
    filename: 'bitcoin-bill-1250.jpg',
    style: :classic
  },
  {
    name: 'Paper Design',
    filename: 'bitcoin-paper.png',
    style: :modern
  }
]

papers.each_with_index do |paper_data, index|
  paper = Paper.find_or_initialize_by(name: paper_data[:name])
  paper.position = index + 1
  paper.style = paper_data[:style]

  if paper.new_record?
    paper.image.attach(
      io: File.open(Rails.root.join('app', 'assets', 'images', paper_data[:filename])),
      filename: paper_data[:filename]
    )
  end

  paper.save!
end
