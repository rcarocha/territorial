require 'places/brasil_symb_location'
require 'ibge/indicador'
require 'ibge/busca_indicadores_local'

EXTERIOR="99"

class AnalistasController < ApplicationController

   helper AnalistasHelper

    def index

      @indicadores = Indicador.Indicadores_disponiveis
      @PIB_PER_CAPTA = Indicador.get_indicadores(@indicadores[:PIB_PER_CAPTA])
      @geojson = {}

      @estado = Estado.estados["12"]
      @municipios = Municipio.municipios

      inicio = Time.now
      logger.info(Time.now.to_s + " - " + self.class.to_s + ": Recuperando indicadores de estado")
      pib_regiao = DadosIndicador.buscar(@estado, @PIB_PER_CAPTA)
      logger.info(Time.now.to_s + " - " + self.class.to_s + ": Recuperando indicadores em " + ("%.4f" % (Time.now - inicio)) + " s")
      gjson = get_geojson(@estado, tipo_res=:absoluta, resolucao=:macroregiao)
      logger.info("Geojson carregado")
      @geojson[@estado.id] = {:object => @estado, :geojson => gjson, :indicador => pib_regiao}
      logger.info(Time.now.to_s + " - " + self.class.to_s + ": Regioes e geojson pronto em " + ("%.4f" % (Time.now - inicio)) + " s")

      @territorios = {}
      Macroregiao.macroregioes.except(EXTERIOR).each do |id, macro|
         @territorios[id] = macro
      end


      @macros_geojson = {}
      Macroregiao.macroregioes.except(EXTERIOR).each do |id, macro|
         antes = Time.now
         @macros_geojson[id] = JSON.parse(get_geojson(macro, tipo_res=:absoluta, resolucao=:macroregiao))
         logger.debug("get_geojson(" + id.to_s + ", tipo_res=:absoluta, resolucao=:macroregiao)) em " + ("%.4f" % (Time.now - antes))+ " s")
      end

    end
  end
