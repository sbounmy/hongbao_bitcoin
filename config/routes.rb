Rails.application.routes.draw do
  namespace :webhooks do
    post "/leonardo", to: "leonardo#webhook"
    post "/face_swap", to: "face_swap#webhook"
    post "/face_swap/process", to: "face_swap#process_face_swap"
    get "/face_swap/get_generation", to: "face_swap#get_generation"
  end

  resources :face_swap_process, only: [ :index ] do
    post :process_face_swap, on: :collection
  end

  ActiveAdmin.routes(self)
  resource :session
  resources :passwords, param: :token
  resources :hong_baos, only: [ :show, :index ] do
    post :search, on: :collection
    put :transfer, on: :member
  end

  scope "(:locale)", locale: /en|zh-CN/ do
    resources :hong_baos, only: [ :new, :show, :index ]
    root "hong_baos#new"
    post "/leonardo/generate", to: "leonardo#generate"
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
  get "login", to: "sessions#new"
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

  direct :github do
    "https://github.com/sbounmy/hongbao_bitcoin"
  end

  direct :youtube_arte do
    "https://youtu.be/qkNhjVJZ4N0?si=ENgRvjLTgiYw6aCL"
  end

  get "instagram/feed", to: "instagram#feed"

  resources :ai_designs, only: [ :create ] do
    get :complete, on: :collection
  end
end
