require 'json'
require 'places/brasil_symb_location'
require 'places/location_model.rb'

class MacrosController < ApplicationController

   def show
      Rails.logger.debug(self.class.to_s + ": show")
      id_macro = params[:id]
      macro = Macroregiao.macroregioes[id_macro]
      @macroregiao = {}
      @macroregiao[:id] = id_macro
      @macroregiao[:nome] =  macro.nome
      @macroregiao[:tipo] = :macroregiao
      @macroregiao[:estados] = []
      macro.estados.each do |estado|
         @macroregiao[:estados] << {:id => estado.id, :nome => estado.nome,  :sigla => estado.sigla}
      end
      Rails.logger.debug(self.class.to_s + ": Enviando show " + @macroregiao.to_s)
   end

   def index
      Rails.logger.debug(self.class.to_s + ": show")
      @macroregioes = []
      Macroregiao.macroregioes.each do |id, item_macro|
         macro = {}
         macro[:id] = id
         macro[:tipo] = :macroregiao
         macro[:nome] = item_macro.nome
         @macroregioes << macro
      end
      Rails.logger.debug(self.class.to_s + ": Enviando index " + @macroregioes.to_s)

   end

end
