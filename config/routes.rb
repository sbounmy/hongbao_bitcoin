Rails.application.routes.draw do
  scope "(:locale)", locale: /en|zh-CN/ do
    resources :hong_baos, only: [ :new, :create, :show ] do
    end
    root "hong_baos#new"
  end
end
