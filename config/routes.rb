Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'pages#home'
  resources :images do
    collection do
      get 'my_images' => 'images#my_images'
      post 'convert_3d' => 'images#convert_3d'
      post 'confirm_3d' => 'images#confirm_convert_3d'
      post 'confirm_delete' => 'images#confirm_delete'
      post 'delete' => 'images#delete'
    end
    member do
      post 'single_data' => 'images#add_single_clinical_data'
      post 'upload_data' => 'images#add_upload_clinical_data'
      get 'get_slice' => 'images#get_slice'
    end
  end
  resources :annotations
  resources :runs do
    collection do
      get 'annotation_form' => 'runs#annotation_form'
    end

    member do 
      get 'download_results' => 'runs#download_results'
    end
  end
  resources :algorithms do
    collection do
      get 'parameter_form' => 'algorithms#parameter_form'
    end
  end

  resources :results do
    member do
      put 'exclude' => 'results#exclude'
      put 'include' => 'results#include'
    end
  end
  
  get '/about' => 'pages#about'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'


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
