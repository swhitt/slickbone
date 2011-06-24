Rails.application.routes.draw do
  mount Slickbone::Engine => "/slickbone"
  root :to => redirect("/slickbone")
end
