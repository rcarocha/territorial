require 'json'
require 'places/brasil_symb_location'
require 'places/location_model.rb'

class LocationsController < ApplicationController


   def index
      @macroregioes = {}
      Macroregiao.macroregioes.each do |id, macro|
         @macroregioes[id] = macro.nome
      end

      @place = {:place => "Brasil",
                :id => "Brasil",
                :tipo => :root,
                :macroregioes => @macroregioes}

      Rails.logger.debug(@place)

   end
end
