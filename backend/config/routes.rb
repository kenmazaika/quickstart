Rails.application.routes.draw do
  root "static_pages#index"
  get "api" => "api/health_checks#index"
  namespace :api do

    resources :tweets
  end
end
