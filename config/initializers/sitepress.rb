Rails.configuration.to_prepare do
  Sitepress::SiteController.class_eval do
    allow_unauthenticated_access
  end
end
