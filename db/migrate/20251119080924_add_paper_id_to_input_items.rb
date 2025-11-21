class AddPaperIdToInputItems < ActiveRecord::Migration[8.0]
  def up
    add_reference :input_items, :paper, null: true, foreign_key: true

    Paper.find_each do |paper|
      input_ids = paper.read_attribute(:input_ids)
      next if input_ids.nil? || input_ids.empty?

      count = 0
      # Use read_attribute to access the array column directly
      input_ids.each do |input_id|
        next unless Input.exists?(input_id)

        # Create the input_item
        item = paper.input_items.create!(
          input_id: input_id,
          paper_id: paper.id
        )

        count += 1
        # Attach image if this was an image input with existing attachment
        if paper.bundle_id.present?
          existing_item = InputItem.find_by(
            bundle_id: paper.bundle_id,
            input_id: input_id
          )
          if existing_item&.image&.attached?
            item.image.attach(existing_item.image.blob)
          end
        end
      end
      puts "Created #{count} input items for paper##{paper.id}"
    end
  end

  def down
    # Destroy input_items that were created for papers during migration
    # (these are the ones with paper_id but no bundle_id)
    InputItem.where.not(paper_id: nil).where(bundle_id: nil).destroy_all

    # Remove the paper_id column
    remove_reference :input_items, :paper, foreign_key: true
  end
end