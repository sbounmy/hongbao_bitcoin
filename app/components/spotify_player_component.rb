class SpotifyPlayerComponent < ApplicationComponent
  def initialize(path:, theme: 0)
    @path = path
    @theme = theme
  end

  def src
    "https://open.spotify.com/embed/#{@path}?utm_source=generator&theme=#{@theme}"
  end
end
