Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  scope "(:locale)", locale: /en|zh-CN/ do
    resources :hong_baos, only: [ :new, :create, :show ] do
    end
    root "hong_baos#new"
  end

  namespace :webhooks do
    post "mt_pelerin", to: "mt_pelerin#create"
  end

  resources :magic_links, only: [ :create ] do
    get :verify, on: :member  # /magic_links/:id/verify
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Add og-image route
  get "og-image", to: "og_image#show", as: :og_image

  # Authentication routes
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "users#new"
  post "signup", to: "users#create"

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Basic validation for Bitcoin address format
  # Supports both Mainnet and Testnet addresses:
  # - Legacy (1, m, n)
  # - SegWit (3, 2)
  # - Native SegWit (bc1, tb1)
  direct :bitcoin do |address, options|
    raise ArgumentError, "Bitcoin address is required" if address.blank?
    raise ArgumentError, "Invalid Bitcoin address" unless address.match?(
      /\A(?:[13][a-km-zA-HJ-NP-Z1-9]{25,34}|[mn2][a-km-zA-HJ-NP-Z1-9]{25,34}|(?:bc|tb)1[a-zA-HJ-NP-Z0-9]{25,39})\z/
    )

    params = options.compact.to_param
    uri = "bitcoin:#{address}"
    uri << "?#{params}" if params.present?
    uri
  end
end
