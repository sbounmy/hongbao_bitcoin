require "digest/md5"

Rails.application.routes.draw do
  # sitepress_root
  sitepress_pages

  mount MissionControl::Jobs::Engine, at: "/jobs"

  resources :bundles, only: [ :create ]

  ActiveAdmin.routes(self)
  resource :session
  resources :passwords, param: :token
  resources :hong_baos, only: [ :show, :index ] do
    post :search, on: :collection
    post :transfer, on: :collection
  end

  scope "(:locale)", locale: /en|zh-CN/, defaults: { locale: "en" } do
    resources :hong_baos, only: [ :new, :show, :index ] do
      get :form, on: :member
      get :utxos, on: :member
    end
    resources :papers, only: [ :show, :new ] do
      get :explore, on: :collection
    end
    root "pages#index"
  end

  namespace :webhooks do
    post "mt_pelerin", to: "mt_pelerin#create"
  end

  resources :addrs, only: [ :show ], controller: "hong_baos"

  resources :tokens, only: [ :index ]

  resources :checkout, only: [ :create, :update ] do
    collection do
      get :success
      get :cancel
      post :webhook
    end
  end

  resources :inputs, only: [ :show ]

  resources :magic_links, only: [ :create ] do
    get :verify, on: :member  # /magic_links/:id/verify
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Add og-image route
  get "og-image/:size", to: "og_image#show", as: :og_image

  get "v1", to: "hong_baos#new" # for dev

  get "/pricing", to: "pages#pricing"
  get "/v2", to: "pages#v2"
  get "/dashboard", to: "papers#index"
  get "/dashboard-3", to: "papers#index_3"

  # Authentication routes
  get "login", to: "users#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "users#new"
  post "signup", to: "users#create"

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  if Rails.env.test?
    scope path: "/__e2e__", controller: "playwright" do
      post "force_login"
    end
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

  direct :github do
    "https://github.com/sbounmy/hongbao_bitcoin"
  end

  direct :satoshi_video do
    "https://drive.google.com/file/d/1SkxgeFFKGZfsk4ro7GwGhPJz8pJio7QP/preview"
  end

  direct :linkedin do
    "https://www.linkedin.com/company/hongbao-bitcoin"
  end

  direct :x do
    "https://x.com/hongbaobitcoin"
  end

  direct :etsy do
    "https://etsy.com/shop/HongBaoBitcoin"
  end

  direct :spotify_artist do
    "https://open.spotify.com/artist/3cBbIJWNXmi5JwCewN7SlN"
  end

  direct :reddit do
    "https://www.reddit.com/r/HongBaoBitcoin/"
  end

  # Direct route to generate Gravatar URLs
  # Note: Conventionally, this logic belongs in a helper (e.g., ApplicationHelper).
  direct :gravatar do |email, options = {}|
    email ||= ""
    size = options.fetch(:size, 80) # Default size 80
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=mp" # d=mp ensures a fallback image
  end

  get "instagram/feed", to: "instagram#feed"

  scope "/(:theme)" do
    get "/", to: "pages#index"
  end

  # Google OAuth Routes
  resource :oauth, only: [], controller: "oauth" do
    collection do
      get :authorize
      get :callback
    end
  end
end
