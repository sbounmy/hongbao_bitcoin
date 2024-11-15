Rails.application.routes.draw do
  scope "(:locale)", locale: /en|zh-CN/ do
    resources :hong_baos, only: [ :new, :create, :show ] do
    end
    root "hong_baos#new"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Add og-image route
  get "og-image", to: "og_image#show", as: :og_image
end
