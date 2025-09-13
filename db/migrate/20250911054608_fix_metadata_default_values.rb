class FixMetadataDefaultValues < ActiveRecord::Migration[8.0]
  def change
    # Change default from string "{}" to proper JSON object {}
    change_column_default :papers, :metadata, from: "{}", to: {}
    change_column_default :inputs, :metadata, from: "{}", to: {}
    change_column_default :tokens, :metadata, from: "{}", to: {}

    # Fix existing records that have string "{}" instead of proper JSON
    reversible do |dir|
      dir.up do
        # For papers
        execute <<-SQL
          UPDATE papers
          SET metadata = json('{}')
          WHERE metadata = '"{}"' OR metadata = '{}' OR metadata IS NULL
        SQL

        # For inputs
        execute <<-SQL
          UPDATE inputs
          SET metadata = json('{}')
          WHERE metadata = '"{}"' OR metadata = '{}' OR metadata IS NULL
        SQL

        # For tokens
        execute <<-SQL
          UPDATE tokens
          SET metadata = json('{}')
          WHERE metadata = '"{}"' OR metadata = '{}' OR metadata IS NULL
        SQL
      end
    end
  end
end
