require "digest/md5"

Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  resources :bundles, only: [ :create ]

  ActiveAdmin.routes(self)
  resource :session
  resources :passwords, param: :token
  resources :hong_baos, only: [ :show, :index ] do
    post :search, on: :collection
    put :transfer, on: :member
  end

  scope "(:locale)", locale: /en|zh-CN/ do
    resources :hong_baos, only: [ :new, :show, :index ] do
      get :form, on: :member
    end
    resources :papers, only: [ :show ]
    root "pages#index"
    post "/leonardo/generate", to: "leonardo#generate"
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

  resources :magic_links, only: [ :create ] do
    get :verify, on: :member  # /magic_links/:id/verify
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Add og-image route
  get "og-image", to: "og_image#show", as: :og_image

  get "v1", to: "hong_baos#new" # for dev

  get "/satoshi", to: "pages#satoshi"

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

  # Direct route to generate Gravatar URLs
  # Note: Conventionally, this logic belongs in a helper (e.g., ApplicationHelper).
  direct :gravatar do |email, options = {}|
    email ||= ""
    size = options.fetch(:size, 80) # Default size 80
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=mp" # d=mp ensures a fallback image
  end

  direct :base64 do |attachment|
    # Converts an Active Storage attachment to a Base64 data URL.
    # Returns an empty string if the attachment is not present, not attached,
    # or is not an image.
    # Check if attachment is provided, attached, and its blob is present
    return "" unless attachment.respond_to?(:attached?) && attachment.attached? && attachment.blob.present?

    blob = attachment.blob

    # Ensure it's an image type before proceeding
    return "" unless blob.content_type.start_with?("image/")

    # Download the file content from storage
    file_content = blob.download
    # Encode the content to Base64
    base64_encoded_content = Base64.strict_encode64(file_content)

    # Construct the data URL
    "data:#{blob.content_type};base64,#{base64_encoded_content}"
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
