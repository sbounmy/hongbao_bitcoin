class UpdatePaperElementsFromThemeMetadata < ActiveRecord::Migration[8.0]
  # This migration updates Paper elements with AI coordinates from Input::Theme metadata.
  # It assumes that each Paper's name matches a Theme's name and that the Theme has 'ai' metadata.

  def up
    # Load all themes into a hash, keyed by name for efficient lookup.
    themes_by_name = Input::Theme.all.index_by(&:name)

    # Iterate over each Paper to update it.
    Paper.find_each do |paper|
      theme = themes_by_name[paper.name]

      if theme && theme.metadata && theme.metadata['ai']
        # Get the coordinate data from the theme.
        theme_ai_coords = theme.metadata['ai']

        # Merge the theme's coordinates into the paper's existing elements.
        # This will update matching keys and preserve any others.
        paper.elements.merge!(theme_ai_coords)

        # Use save! to ensure the migration fails if any record can't be saved.
        paper.save!

        puts "Updated Paper ##{paper.id} ('#{paper.name}')"
      else
        puts "Skipping Paper ##{paper.id} ('#{paper.name}'): No matching theme or theme AI metadata found."
      end
    end
  end

  def down
    puts "This data migration is not reversible."
  end
end
