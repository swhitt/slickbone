Rails.application.routes.draw do
  mount Slickbone::Engine => "/slickbone"
  root :to => 'demo#index'
end
