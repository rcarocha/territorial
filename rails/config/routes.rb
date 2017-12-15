Rails.application.routes.draw do
  # Documentacao adicional sobre rotas: http://guides.rubyonrails.org/routing.html

resources :locations, only: [:index] do
   resources :macros, only: [:index, :show] do
      resources :estados, only: [:index, :show] do
         resources :mesos, only: [:index, :show] do
            resources :micros, only: [:index, :show] do
               resources :municipios, only: [:index, :show]
            end
         end
      end
   end
end

get "/analista/:analise_page" => "analistas#index"
get "/analista" => "analistas#index"
get "/eleitor/:analise_page" => "eleitores#index"
get "/eleitor" => "eleitores#index"
get "/charts" => "eleitores#charts"
get "/charts/:id_stat" => "eleitores#charts"
get "/usuario" => "usuarios#index"

get "/stat" => "estatisticas#index"
get "/stat/:id_stat" => "estatisticas#show"

get "/teste" => "teste#index"
post "/teste" => "teste#create"

root :to => redirect('/usuario')

end
