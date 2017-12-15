require 'json'
require 'places/brasil_symb_location'
require 'places/location_model.rb'

class MesosController < ApplicationController

   def show
      id_meso = params[:id]
      meso = Mesorregiao.mesorregioes[id_meso]
      @mesorregiao = {}
      @mesorregiao[:id] = id_meso
      @mesorregiao[:nome] =  meso.nome
      @mesorregiao[:tipo] = :mesoregiao
      @mesorregiao[:microrregioes] = []
      meso.microrregioes.each do |micro|
         @mesorregiao[:microrregioes] << {:id => micro.id, :nome => micro.nome}
      end
   end

   def index
      id_estado = params[:estado_id].to_s

      @mesorregioes = []
      Estado.estados[id_estado].mesorregioes.each do |item_meso|
         meso = {}
         meso[:id] = item_meso.id
         meso[:tipo] = :mesoregiao
         meso[:nome] = item_meso.nome
         @mesorregioes << meso
      end
   end

end
