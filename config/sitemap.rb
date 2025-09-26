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

    # Get all products from Shopify
    begin
      products = Shopify::Product.all
      products.each do |product|
        # Build images array from product images
        product_images = []
        if product.images&.any?
          product.images.first(4).each do |image|
            product_images << {
              loc: image.url,
              title: "#{product.title} Bitcoin Gift Envelope",
              caption: product.description || "Bitcoin Gift Envelope Pack",
              geo_location: "Worldwide"
            }
          end
        end

        # Add main product page
        if product_images.any?
          add product_path(pack: product.handle),
              changefreq: "weekly",
              priority: 0.8,
              images: product_images
        else
          add product_path(pack: product.handle),
              changefreq: "weekly",
              priority: 0.8
        end

        # Add pages for each variant's color option
        if product.variants&.any?
          colors_added = Set.new
          product.variants.each do |variant|
            color_option = variant.selectedOptions&.find { |opt| opt.name.downcase == 'color' }
            if color_option && !colors_added.include?(color_option.value.downcase)
              colors_added.add(color_option.value.downcase)
              add variant_product_path(pack: product.handle, color: color_option.value.downcase),
                  changefreq: "weekly",
                  priority: 0.7
            end
          end
        end
      end
    rescue => e
      Rails.logger.error "Failed to fetch Shopify products for sitemap: #{e.message}"
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
