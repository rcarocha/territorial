class TesteController < ApplicationController

def index
   puts "EXECUTANDO TESTE CONTROLLER"
   @testes = [{:id => "452345", :nome => "ricardo"}, {:id => "4524499", :nome => "renata"}]
end

def create

   puts "************ CREATE ****************"
   puts "    criacao de " + params["nome"]
   @criado = {:nome => params["nome"], :filo => "temporanta!", :adendum => "mosca _ carioca"}
   respond_to do | format |
     format.html { redirect_to @teste, notice: "teste feito no controlador de teste"}
     format.js
   end
end

end
