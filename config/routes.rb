Rails.application.routes.draw do
  devise_for :users
  authenticate :user do
    root "thumbnails#index"
    resources :thumbnails
    get "up" => "rails/health#show", as: :rails_health_check
  end
end
