namespace :papers do
  desc "Compress all Paper PNG images to JPG using vips"
  task compress_to_jpg: :environment do
    # Helper method to process a single Active Storage attachment
    def process_attachment(attachment)
      return unless attachment.attached?

      blob = attachment.blob
      return unless blob.content_type == "image/png"

      puts "Processing #{attachment.record.class.name} #{blob.content_type} ##{attachment.record.id}, attachment: #{attachment.name}..."

      processed_file = nil
      begin
        # blob.open downloads the file to a temporary location
        blob.open do |tempfile|
          processed_file = ImageProcessing::Vips
            .source(tempfile)
            .convert("jpg")
            .call # This returns a new Tempfile
        end

        new_filename = blob.filename.to_s.gsub(/\.png$/i, ".jpg")

        # This replaces the old attachment
        attachment.attach(
          io: processed_file,
          filename: new_filename,
          content_type: "image/jpeg"
        )
        puts "  -> Success: Replaced with #{new_filename}"
      rescue => e
        puts "  -> Error processing attachment: #{e.message}"
      ensure
        # Clean up the tempfile created by ImageProcessing
        processed_file&.close
        processed_file&.unlink
      end
    end

    # find all papers that have at least one of the images attached
    # using the | union operator to combine ids without having any duplicates
    paper_ids = Paper.with_attached_image_front.ids |
                Paper.with_attached_image_back.ids |
                Paper.with_attached_image_full.ids
    papers_to_check = Paper.where(id: paper_ids)

    # find all themes that have at least one of the images attached
    theme_ids = Input::Theme.with_attached_image_front.ids |
                Input::Theme.with_attached_image_back.ids |
                Input::Theme.with_attached_image_hero.ids
    themes_to_check = Input::Theme.where(id: theme_ids)

    puts "Found #{papers_to_check.count} papers with images to check."

    papers_to_check.find_each do |paper|
      puts "Checking Paper ##{paper.id}..."
      process_attachment(paper.image_front)
      process_attachment(paper.image_back)
      process_attachment(paper.image_full)
    end

    themes_to_check.find_each do |theme|
      puts "Checking Theme ##{theme.id}..."
      process_attachment(theme.image_front)
      process_attachment(theme.image_back)
      process_attachment(theme.image_hero)
    end

    puts "Image compression task finished."
  end
end
