require 'json'
require 'places/brasil_symb_location'
require 'places/location_model.rb'

class MicrosController < ApplicationController

   def show
      id_micro = params[:id]
      micro = Microrregiao.microrregioes[id_micro]
      @microrregiao = {}
      @microrregiao[:id] = id_micro
      @microrregiao[:nome] =  micro.nome
      @microrregiao[:tipo] = :microrregiao
      @microrregiao[:municipios] = []
      micro.municipios.each do |municipio|
         @microrregiao[:municipios] << {:id => municipio.id, 
            :nome => municipio.nome,
            :estado => municipio.estado.id,
            :estado_id => municipio.estado.nome}
      end
   end

   def index
      @microrregioes = []
      Microrregiao.microrregioes.each do |id, item_micro|
         micro = {}
         micro[:id] = id
         micro[:tipo] = :microrregiao
         micro[:nome] = item_micro.nome
         @microrregioes << micro
      end
   end


end
