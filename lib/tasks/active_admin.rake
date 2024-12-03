namespace :active_admin do
  desc "Build Active Admin Tailwind stylesheets"
  task build: :environment do
    require "tailwindcss/ruby"
    system "#{Tailwindcss::Ruby.executable}",
      "-i", Rails.root.join("app/assets/stylesheets/active_admin.css").to_s,
      "-o", Rails.root.join("app/assets/builds/active_admin.css").to_s,
      "-c", Rails.root.join("config/tailwind-active_admin.config.js").to_s,
      exception: true
  end

  desc "Watch Active Admin Tailwind stylesheets"
  task watch: :environment do
    require "tailwindcss/ruby"
    system "#{Tailwindcss::Ruby.executable}",
      "--watch",
      "-i", Rails.root.join("app/assets/stylesheets/active_admin.css").to_s,
      "-o", Rails.root.join("app/assets/builds/active_admin.css").to_s,
      "-c", Rails.root.join("config/tailwind-active_admin.config.js").to_s
  end
end
