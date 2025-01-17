EarthdataSearchClient::Application.routes.draw do

  mount Cmep::Engine => "/cmep" if defined?(Cmep)

  get 'urs_callback' => 'oauth_tokens#urs_callback'
  get "login" => 'users#login'
  get "logout" => 'users#logout'
  get "contact_info" => 'users#contact_info'
  get 'refresh_token' => 'oauth_tokens#refresh_token'

  resources :users, only: [:new, :create] do
    collection do
      post 'username_recall'
      post 'password_reset'
      get 'get_preferences'
      post 'update_notification_pref'
      get 'site_preferences' => 'users#get_site_preferences'
      post 'site_preferences' => 'users#set_site_preferences'
    end
  end

  match 'static' => 'static_pages#index', :via => [:get]

  get 'collection_facets' => 'collections#facets'
  resources :collections, only: [:index, :show], defaults: {format: 'json'} do
    member do
      post 'use'
    end
  end

  resources :granules, only: [:create, :show], defaults: {format: 'json'} do
    collection do
      post 'timeline'
      get 'download', defaults: { format: ['html', 'sh'] }
    end
  end

  resources :docs
  resources :events

  resources :projects, only: [:show, :create], defaults: {format: 'text'}
  get 'projects' => 'projects#index', format: 'html'
  post 'projects/remove' => 'projects#remove', format: 'json'

  resources :placenames, only: [:index], defaults: {format: 'json'}

  post 'convert' => 'conversions#convert'
  resources :convert, only: [:create], defaults: {format: 'json'}

  match 'data/options' => 'data_access#options', format: 'json', via: [:get, :post]
  post 'data/configure' => 'data_access#configure'
  get 'data/configure' => 'data_access#configure'
  post 'data/retrieve' => 'data_access#retrieve'
  get 'data/retrieve/:id' => 'data_access#retrieval'
  get 'data/status' => 'data_access#status'
  post 'data/remove' => 'data_access#remove', format: 'json'

  get 'search(/*overlay_params)' => 'search#index'
  get 'health' => 'health#index', format: 'json'
  root :to => 'search#index'


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'static_pages#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
