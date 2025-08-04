class ConvertPaperArrayColumnsToIntegers < ActiveRecord::Migration[8.0]
  def up
    # Convert string arrays to integer arrays for input_ids
    Paper.find_each do |paper|
      if paper.input_ids.present? && paper.input_ids.any? { |id| id.is_a?(String) }
        paper.update_columns(
          input_ids: paper.input_ids.map(&:to_i),
          input_item_ids: paper.input_item_ids.map(&:to_i)
        )
      end
    end
  end

  def down
    # Convert integer arrays back to string arrays
    Paper.find_each do |paper|
      if paper.input_ids.present? && paper.input_ids.any? { |id| id.is_a?(Integer) }
        paper.update_columns(
          input_ids: paper.input_ids.map(&:to_s),
          input_item_ids: paper.input_item_ids.map(&:to_s)
        )
      end
    end
  end
end
