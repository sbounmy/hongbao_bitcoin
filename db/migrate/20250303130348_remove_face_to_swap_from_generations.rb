class RemoveFaceToSwapFromGenerations < ActiveRecord::Migration[8.0]
  def up
    # Remove associated Active Storage attachments and blobs
    ActiveStorage::Attachment.where(record_type: 'Ai::Generation', name: 'face_to_swap').find_each do |attachment|
      attachment.purge
    end
  end

  def down
    # No need for down migration since we can't restore deleted files
  end
end
