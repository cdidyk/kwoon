Rails.application.routes.draw do
  #get 'users' => 'users#index', as: :users
  resources :users, only: [:index]
  resources :sessions, only: [:new, :create, :destroy]
  resources :applications, only: [:new, :create]

  get 'applications/confirmation' => 'applications#confirmation',
      as: 'application_confirmation'

  get 'courses/:course_id/registrations/confirmation' => 'registrations#confirmation',
      as: 'course_registration_confirmation'
  resources :courses, only: [] do
    resources :registrations, only: [:new, :create]
  end

  get 'events/:event_id/registrations/confirmation' => 'event_registrations#confirmation',
      as: 'event_registration_confirmation'
  resources :events, only: [] do
    resources :event_registrations,
      path: 'registrations',
      as: 'registrations',
      only: [:new, :create]
  end

  post 'webhook' => 'stripe#webhook'

  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  get 'info' => 'info#index'

  root to: 'application#redirect_to_new_application'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
