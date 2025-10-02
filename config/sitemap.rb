require "rubygems"
require "sitemap_generator"

SitemapGenerator::Sitemap.default_host = "https://hongbaob.tc"

# Sitemap for the main application pages.
# Generates `app.xml.gz`
SitemapGenerator::Sitemap.create(filename: :sitemap) do
  add root_path, changefreq: "monthly", priority: 0.9
  add pricing_path, changefreq: "monthly"
  add dashboard_path, changefreq: "weekly"

  add calendar_path, changefreq: "monthly"
  add agenda_path, changefreq: "monthly"
  %w[january february march april may june july august september october november december].each do |month|
    add calendar_month_path(month), changefreq: "monthly"
    add agenda_month_path(month), changefreq: "monthly"
  end

  Input::Event.all.each do |event|
    add input_path(event), changefreq: "monthly"
  end

  app_pages_files = Dir[Rails.root.join("app", "content", "pages", "*.html.*")]
  app_pages_files.each do |file|
    slug = File.basename(file).split(".").first
    add "/#{slug}", changefreq: "weekly", priority: 0.8
  end

  group(filename: :sitemap_blog) do
    blog_post_files = Dir[Rails.root.join("app", "content", "pages", "blog", "*.*")]
    blog_post_files.each do |file|
      # Creates a path like /blog/hello-world from a file path like
      # /path/to/app/content/pages/blog/hello-world.html.md
      slug = File.basename(file).split(".").first
      add "/blog/#{slug}", changefreq: "weekly", priority: 0.8
    end
  end

  group(filename: :sitemap_products) do
    # Add products index page
    add products_path, changefreq: "weekly", priority: 0.8

    # Get all published products with their variants
    Product.published.includes(variants: { images_attachments: :blob }).each do |product|
      # Build comprehensive images array from ALL variants' images
      product_images = []
      product.variants.each do |variant|
        # Include ALL images from each variant, not just the first
        variant.images.each_with_index do |image, index|
          if Rails.application.routes.url_helpers.respond_to?(:rails_blob_url)
            variant_description = variant.options_text
            product_images << {
              loc: Rails.application.routes.url_helpers.rails_blob_url(image, host: SitemapGenerator::Sitemap.default_host),
              title: "#{product.name} - #{variant_description} Bitcoin Gift Envelope",
              caption: "#{product.description}. #{variant_description}. Perfect Bitcoin gift for beginners.",
              geo_location: "Worldwide"
            }
          end
        end
      end

      if product_images.any?
        add product_path(slug: product.slug),
            changefreq: "weekly",
            priority: 0.8,
            images: product_images # Include ALL images, not just first 4
      else
        add product_path(slug: product.slug),
            changefreq: "weekly",
            priority: 0.8
      end
    end
  end

  group(filename: :sitemap_contents) do
    Content::Quote.all.each do |quote|
      # Determine the best image for the quote
      image_url = if quote.best_image
        Rails.application.routes.url_helpers.url_for(quote.best_image)
      else
        "#{SitemapGenerator::Sitemap.default_host}/assets/bill_hongbao.jpg"
      end

      add bitcoin_content_path(klass: "quotes", slug: quote.slug),
          changefreq: "monthly",
          images: [ {
            loc: image_url,
            title: "#{quote.author} #{quote.text} - Bitcoin quote gift envelope hongbao",
            caption: quote.text,
            geo_location: "Worldwide",
            license: "https://creativecommons.org/licenses/by-sa/4.0/"
          } ]
    end
  end
end
