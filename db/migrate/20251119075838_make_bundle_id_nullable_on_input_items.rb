class MakeBundleIdNullableOnInputItems < ActiveRecord::Migration[8.0]
  def up
    change_column_null :input_items, :bundle_id, true
  end

  def down
    # Delete input_items that have null bundle_id before making it NOT NULL
    change_column_null :input_items, :bundle_id, false
  end
end
