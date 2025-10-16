# frozen_string_literal: true

module SavedHongBaosHelper
  # Yields hong_baos with year separator info
  # Usage: with_year_separators(hong_baos) do |hong_bao, show_separator, year|
  def with_year_separators(hong_baos)
    previous_year = nil
    current_year = Date.current.year

    hong_baos.each do |hong_bao|
      hong_bao_year = hong_bao.gifted_at&.year || current_year

      # Determine if we should show a year separator
      show_separator = previous_year &&
                      previous_year != hong_bao_year &&
                      hong_bao_year != current_year

      yield(hong_bao, show_separator, hong_bao_year)

      previous_year = hong_bao_year
    end
  end

  # Renders a year separator for the given year
  def render_year_separator(year, options = {})
    type = options[:type] || :card # :card or :table

    if type == :table
      render "saved_hong_baos/year_separator_row", year: year
    else
      render "saved_hong_baos/year_separator", year: year
    end
  end
end
