require 'json'
require 'places/brasil_symb_location'
require 'places/location_model.rb'

class EstadosController < ApplicationController

   def show
      id_estado = params[:id]
      estado = Estado.estados[id_estado]
      @estado = {}
      @estado[:id] = id_estado
      @estado[:nome] =  estado.nome
      @estado[:sigla] =  estado.sigla
      @estado[:tipo] = :estado
      @estado[:mesorregioes] = []
      estado.mesorregioes.each do |mesorregiao|
         @estado[:mesorregioes] << {:id => mesorregiao.id, :nome => mesorregiao.nome}
      end
   end

   def index
      id_macro = params[:macro_id].to_s

      @estados = []
      Macroregiao.macroregioes[id_macro].estados.each do |estado_macro|
         estado = {}
         estado[:id] = estado_macro.id
         estado[:tipo] = :estado
         estado[:nome] = estado_macro.nome
         estado[:sigla] = estado_macro.sigla
         @estados << estado
      end

   end

end
