Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'pages#home'
  resources :images do
    collection do
      get 'my_images' => 'images#my_images'
      post 'make_public' => 'images#make_public'
      post 'convert_3d' => 'images#convert_3d'
      post 'confirm_3d' => 'images#confirm_convert_3d'
      post 'confirm_delete' => 'images#confirm_delete'
      post 'delete' => 'images#delete'
      get 'autocomplete_user_email' => 'images#autocomplete_user_email'
    end
    member do
      post 'single_data' => 'images#add_single_clinical_data'
      post 'upload_data' => 'images#add_upload_clinical_data'
      get 'get_slice' => 'images#get_slice'
      get 'show_3d' => 'images#show_3d'
      post 'import_annotations' => 'images#import_annotations'
      get 'download_annotations' => 'images#download_annotations'
    end
  end
  resources :annotations
  resources :runs do
    collection do
      get 'annotation_form' => 'runs#annotation_form'
      post 'confirm_delete' => 'runs#confirm_delete'
      post 'delete' => 'runs#delete'
    end

    member do 
      get 'download_results' => 'runs#download_results'
      get 'get_results' => 'runs#get_results'
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

  resources :user_image_ownerships do
    get :autocomplete_user_email, :on => :collection
    post 'confirm_share' => 'user_image_ownerships#confirm_share', :on => :collection
  end

  resources :user_run_ownerships do
    get :autocomplete_user_email, :on => :collection
    post 'confirm_share' => 'user_run_ownerships#confirm_share', :on => :collection
  end

  
  get '/about' => 'pages#about'
  get '/algorithmguide' => 'pages#algorithmguide'

  authenticate :user, lambda { |u| u.admin? } do
    get '/admin' => 'users#admin_panel'
    get '/admin/new_user' => 'users#admin_create_user'
    get '/admin/new_algorithm' => 'users#admin_new_algorithm'
    put '/admin/users/promote' => 'users#promote'
    put '/admin/users/demote' => 'users#demote'


    post '/admin/users/create' => 'users#create'
    delete '/admin/users/delete' => 'users#delete'
    delete '/admin/algorithms/delete' => 'users#admin_delete_algorithm'
    get '/admin/users/resend' => 'users#resend_confirmation'
  end

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

end
