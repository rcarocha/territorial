require 'cepesp/consultas_cepesp'
require 'cepesp/eleicao'
require 'cepesp/estatisticas_eleicao'
require 'places/location_model'
require 'json'

class EleitoresController < ApplicationController
    def estatistica
      logger.debug(self.class.to_s + ": index" )
      inicio = Time.now

      meso = request["meso"]
      micro = request["micro"]
      municipio = request["municipio"]
      estado = request["estado"]


      @subnivel_loc = nil
      @hierarquia_lugares = "Brasil"
      @subnivel_titulo = nil
      estatistica_eleicao = nil

      if municipio != nil then
         Rails.logger.debug("Dados eleicao computados para municipio " + municipio)
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Municipio.municipios[municipio])
         estatistica_eleicao.compute_eleicao(2014, :municipio)
         @hierarquia_lugares = "Brasil / " + Municipio.municipios[municipio].estado.nome
      elsif micro != nil then
         Rails.logger.debug("Dados eleicao computados para microrregiao " + micro)
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Microrregiao.microrregioes[micro])
         estatistica_eleicao.compute_eleicao(2014, :micro)
         @subnivel_loc = Microrregiao.microrregioes[micro].municipios
         @subnivel_titulo = "Municípios"
         @hierarquia_lugares = "Brasil / " + Microrregiao.microrregioes[micro].estado.nome
      elsif meso != nil then
         Rails.logger.debug("Dados eleicao computados para mesorregiao " + meso)
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Mesorregiao.mesorregioes[meso])
         estatistica_eleicao.compute_eleicao(2014, :meso)
         @subnivel_loc = Mesorregiao.mesorregioes[meso].microrregioes
         @subnivel_titulo = "Microrregiões"
         @hierarquia_lugares = "Brasil / " + Mesorregiao.mesorregioes[meso].estado.nome
      elsif estado != nil then
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Estado.estados[estado])
         estatistica_eleicao.compute_eleicao(2014, :estado)
         @subnivel_loc = Estado.estados[estado].mesorregioes
         @subnivel_titulo = "Mesorregiões"
         @hierarquia_lugares = "Brasil / " + Estado.estados[estado].nome
     else
         @subnivel_loc = Estado.estados.except("99").map{|k,v| v}.sort_by{ |estado| estado.sigla}
         @subnivel_titulo = "Estados"
      end
      Rails.logger.debug("Dados eleicao computados em " + ((Time.now - inicio)*1000).to_s + " ms")
      return estatistica_eleicao
    end

    def index
      @ano=2014
      @eleicao = estatistica()

    end

    def charts

      @eleicao = estatistica()
      @messoregioes = ['Leste Goiano', 'Centro Goiano', 'Sul Goiano', 'Norte Goiano' ,'Noroeste Goiano']
      @id_stat = request['id_stat']
      @dados     = request['data'].to_s.html_safe

      puts "\n\n************* " + @dados.to_s + "*************\n\n"
      @meses = ['janeiro', 'fevereiro', 'marco', 'abril', 'maio', 'junho', 'julho']

    end
end
