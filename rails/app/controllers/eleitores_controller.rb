require 'cepesp/consultas_cepesp'
require 'cepesp/eleicao'
require 'cepesp/estatisticas_eleicao'
require 'places/location_model'
require 'places/brasil_symb_location'
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
      @subnivel_titulo = ""
      @escopo = nil
      @local = nil
      estatistica_eleicao = nil

      if municipio != nil then
         Rails.logger.debug("Dados eleicao computados para municipio " + municipio)
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Municipio.municipios[municipio])
         estatistica_eleicao.compute_eleicao(2014, :municipio)
         @hierarquia_lugares = "Brasil / " + Municipio.municipios[municipio].estado.nome
         @escopo = :municipio
         @local = municipio

      elsif micro != nil then
         Rails.logger.debug("Dados eleicao computados para microrregiao " + micro)
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Microrregiao.microrregioes[micro])
         estatistica_eleicao.compute_eleicao(2014, :micro)
         @subnivel_loc = Microrregiao.microrregioes[micro].municipios
         @subnivel_titulo = "Municípios"
         @hierarquia_lugares = "Brasil / " + Microrregiao.microrregioes[micro].estado.nome
         @escopo = :micro
         @local = micro


      elsif meso != nil then
         Rails.logger.debug("Dados eleicao computados para mesorregiao " + meso)
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Mesorregiao.mesorregioes[meso])
         estatistica_eleicao.compute_eleicao(2014, :meso)
         @subnivel_loc = Mesorregiao.mesorregioes[meso].microrregioes
         @subnivel_titulo = "Microrregiões"
         @hierarquia_lugares = "Brasil / " + Mesorregiao.mesorregioes[meso].estado.nome
         @escopo = :meso
         @local = meso

      elsif estado != nil then
         estatistica_eleicao = EstatisticaEleicao.new($CARGOS[:deputado_federal], Estado.estados[estado])
         estatistica_eleicao.compute_eleicao(2014, :estado)
         @subnivel_loc = Estado.estados[estado].mesorregioes
         @subnivel_titulo = "Mesorregiões"
         @hierarquia_lugares = "Brasil / " + Estado.estados[estado].nome
         @escopo = :estado
         @local = estado

     else
         @subnivel_loc = Estado.estados.except("99").map{|k,v| v}.sort_by{ |estado| estado.sigla}
         @subnivel_titulo = "Estados"
      end
      Rails.logger.debug("Dados eleicao computados em " + ((Time.now - inicio)*1000).to_s + " ms")
      return estatistica_eleicao
    end

    def index
      begin
         @ano=2014
         @eleicao = estatistica()
      rescue ErroComunicacao => e
         @erro = e.to_s
         render action: "erro"
      end

    end

    def charts
      begin
         @subnivel_detalhamento_titulo = ""

         @eleicao = estatistica()
         @messoregioes = ['Leste Goiano', 'Centro Goiano', 'Sul Goiano', 'Norte Goiano' ,'Noroeste Goiano']
         @id_stat = request['id_stat']
         @dados  = request['data'].to_s.html_safe

         escopo_localizacao = nil
         @dataStates = "null"
         hash_dados = JSON.parse(request['data'])
         candidato = hash_dados["table"]["num_titulo_eleitoral_candidato"]
         cargo = hash_dados["table"]["codigo_cargo"]
         escopo_localizacao = request['escopo'].to_sym
         @escopoLocalizacao = escopo_localizacao
         localizacao = request['local']
         @distribuicao_votacao = EstatisticaEleicao.distribuicao_votacao_candidato(2014, cargo.to_s, candidato.to_s, localizacao.to_s, escopo_localizacao)
         if escopo_localizacao != :estado then
            #@distribuicao_votacao = EstatisticaEleicao.distribuicao_votacao_candidato(2014, cargo.to_s, candidato.to_s, localizacao.to_s, escopo_localizacao)
            hash_identificacao_localizacao = {}
            estado_localizacao = case escopo_localizacao
            when :meso
               Mesorregiao.mesorregioes[localizacao].estado
            when :micro
               Microrregiao.microrregioes[localizacao].estado
            when :municipio
               Municipio.municipios[localizacao].estado
            end
            hash_geojson = JSON.parse(get_geojson(estado_localizacao, :absoluta, escopo_localizacao))


            geo_locais = hash_geojson["features"]
            # adiciona informacao de votacao nas features
            geo_locais.each do |item_local|
               local_id = item_local["properties"]["codarea"]
               # modificar para usar funcao anonima definida no case/when acima
               item_local["properties"]["name"] = case escopo_localizacao
               when :meso
                  @subnivel_detalhamento_titulo = "Mesorregião"
                  Mesorregiao.mesorregioes[item_local["properties"]["codarea"]].nome
               when :micro
                  @subnivel_detalhamento_titulo = "Microrregião"
                  Microrregiao.microrregioes[item_local["properties"]["codarea"]].nome
               when :municipio
                  @subnivel_detalhamento_titulo = "Município"
                  Municipio.municipios[item_local["properties"]["codarea"]].nome
               end
               item_local["properties"]["votacao"] = @distribuicao_votacao.locais[local_id]
               item_local["properties"]["total_votacao"] = @distribuicao_votacao.total_votacao
            end

            @dataStates = hash_geojson.to_json.to_s.html_safe
         end

         @meses = ['janeiro', 'fevereiro', 'marco', 'abril', 'maio', 'junho', 'julho']
      rescue ErroComunicacao => e
         @erro = e.to_s
         render action: "erro"
      end
    end

    def erro
    end
end
