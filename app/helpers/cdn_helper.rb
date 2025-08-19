module CdnHelper
  CDN_BASE_URL = "https://cdn.hongbaob.tc"

  def cdn_url(path)
    "#{CDN_BASE_URL}/#{path}"
  end

  def cdn_video_tag(path, options = {})
    default_options = {
      controls: true,
      class: "w-full rounded-lg shadow-lg",
      preload: "metadata"
    }

    video_tag cdn_url(path), default_options.merge(options)
  end

  def cdn_image_tag(path, options = {})
    image_tag cdn_url(path), options
  end
end
