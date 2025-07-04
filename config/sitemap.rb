require "rubygems"
require "sitemap_generator"

SitemapGenerator::Sitemap.default_host = "https://hongbaob.tc"

# Sitemap for the main application pages.
# Generates `app.xml.gz`
SitemapGenerator::Sitemap.create(filename: :sitemap) do
  add "/", changefreq: "monthly", priority: 0.9
  add "/pricing", changefreq: "monthly"
  add "/dashboard", changefreq: "weekly"

  app_pages_files = Dir[Rails.root.join("app", "content", "pages", "*.html.*")]
  app_pages_files.each do |file|
    slug = File.basename(file).split(".").first
    add "/#{slug}", changefreq: "weekly", priority: 0.8
  end

  group(filename: :sitemap_blog) do
    blog_post_files = Dir[Rails.root.join("app", "content", "pages", "blog", "*.md")]
    blog_post_files.each do |file|
      # Creates a path like /blog/hello-world from a file path like
      # /path/to/app/content/pages/blog/hello-world.html.md
      slug = File.basename(file).split(".").first
      add "/blog/#{slug}", changefreq: "weekly", priority: 0.8
    end
  end
end
