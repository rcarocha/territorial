require 'json'
require 'places/brasil_symb_location'
require 'places/location_model.rb'

class MunicipiosController < ApplicationController

   def show
      id_muni = params[:id]
      muni = Municipio.municipios[id_muni]
      @municipio = {}
      @municipio[:id] = id_muni
      @municipio[:nome] =  muni.nome
      @municipio[:tipo] = :municipio
      @municipio[:estado] = {:estado => muni.estado.nome, :estado_id => muni.estado.id}
   end

   def index
      @municipios = []
      Municipio.municipios.each do |id, item_muni|
         muni = {}
         muni[:id] = id
         muni[:tipo] = :municipio
         muni[:nome] = item_muni.nome
         muni[:estado] = item_muni.estado.nome
         muni[:estado_id] = item_muni.estado.id
         @municipios << muni
      end
   end


end
