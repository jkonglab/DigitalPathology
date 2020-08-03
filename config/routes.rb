Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'pages#home'

  resources :projects do
    collection do 
      post 'make_public' => 'projects#make_public'
      post 'make_private' => 'projects#make_private'
    end

    member do      
      get 'rerun' => 'projects#rerun'
      get 'download_all_annotations' => 'projects#download_all_annotations' 
    end
  end

  get 'my_projects' => 'projects#my_projects'

  resources :images do
    collection do
      post 'make_public' => 'images#make_public'
      post 'convert_3d' => 'images#convert_3d'
      post 'confirm_3d' => 'images#confirm_convert_3d'
      post 'confirm_delete' => 'images#confirm_delete'
      post 'confirm_move' => 'images#confirm_move'
      post 'move' => 'images#move'
      post 'delete' => 'images#delete'
      get 'autocomplete_user_email' => 'images#autocomplete_user_email'
    end
    member do
      post 'single_data' => 'images#add_single_clinical_data'
      post 'upload_data' => 'images#add_upload_clinical_data'
      get 'get_slice' => 'images#get_slice'
      get 'show_3d' => 'images#show_3d'
      get 'show_landmark_points_3d' => 'images#show_landmark_points_3d'
      post 'import_annotations' => 'images#import_annotations'
      get 'download_annotations' => 'images#download_annotations'
      get 'download_annotations_xml' => 'images#download_annotations_xml'
      get 'download_landmarks' => 'images#download_landmarks'
    end
  end
  resources :annotations do
    collection do
      post 'delete_selected' => 'annotations#delete_selected'
    end
  end

  resources :landmarks do
  end

  resources :runs do
    collection do
      get 'annotation_form' => 'runs#annotation_form'
      #get 'tilesize_form' => 'runs#tilesize_form'
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

  resources :user_project_ownerships do
    get :autocomplete_user_email, :on => :collection
    post 'confirm_share' => 'user_project_ownerships#confirm_share', :on => :collection
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
    put '/admin/users/promote' => 'users#promote'
    put '/admin/users/demote' => 'users#demote'
    put '/admin/users/approve' => 'users#approve' 

    post '/admin/users/create' => 'users#create'
    delete '/admin/users/delete' => 'users#delete'
    get '/admin/users/resend' => 'users#resend_confirmation'
  end

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

end
