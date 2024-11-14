Rails.application.routes.draw do
  scope "(:locale)", locale: /en|zh-CN/ do
    resources :hong_baos, only: [ :new, :create, :show ] do
      member do
        get :print
        get :success
      end
    end
    root "hong_baos#new"
  end

  post "webhooks/stripe", to: "webhooks#stripe"
end
