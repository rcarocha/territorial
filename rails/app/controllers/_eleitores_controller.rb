#Controlador que retorna um resultado com multiplos estados, caso a requisicao venha com os ids dos estados separados por virgulas
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
	  estado = estado==nil ? nil : estado[","] ? estado.split(",") : [estado]#permite consultar multiplos estados

      @subnivel_loc = nil
      @hierarquia_lugares = "Brasil"
      @subnivel_titulo = nil
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


      #permite consultar multiplos estados
      elsif estado != nil then
         estatistica_eleicao = estado.map{ |state| EstatisticaEleicao.new($CARGOS[:deputado_federal], Estado.estados[state])}
         estatistica_eleicao.each{|state| state.compute_eleicao(2014, :estado)}
         @subnivel_loc = estado.map{|state| Estado.estados[state].mesorregioes}
         @subnivel_titulo = "Mesorregiões"
         @hierarquia_lugares = "Brasil - " + estado.each{ |state| Estado.estados[state].nome + ", "}.join(",")
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
      @ano=2014
      @eleicao = estatistica()

    end

    def charts
      @eleicao = estatistica()
      @messoregioes = ['Leste Goiano', 'Centro Goiano', 'Sul Goiano', 'Norte Goiano' ,'Noroeste Goiano']
      @id_stat = request['id_stat']
      @dados  = request['data'].to_s.html_safe

=begin
{"table":{"codigo_cargo":"6","sigla_partido":"PT","num_turno":"1","num_titulo_eleitoral_candidato":"344581031","descricao_cargo":"DEPUTADO FEDERAL","ano_eleicao":"2014","numero_partido":"13","numero_candidato":"1310","uf":"GO","nome_uf":"Goiás","qtde_votos":"58865","nome_urna_candidato":"PROFESSOR EDWARD MADUREIRA","des_situacao_candidatura":"DEFERIDO","desc_sit_tot_turno":"SUPLENTE","resultado_eleicao":"suplente","percentual_votos_localizacao":2.084,"percentual_votos_validos":1.938,"percentual_votos_gerais":1.675}
=end

      escopo_localizacao = nil
      hash_dados = JSON.parse(request['data'])
      candidato = hash_dados["table"]["num_titulo_eleitoral_candidato"]
      cargo = hash_dados["table"]["codigo_cargo"]
      escopo_localizacao = request['escopo'].to_sym
      localizacao = request['local']
      if escopo_localizacao != :estado then
         distribuicao_votacao = EstatisticaEleicao.distribuicao_votacao_candidato(2014, cargo.to_s, candidato.to_s, localizacao.to_s, escopo_localizacao)
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
            item_local["properties"]["votacao"] = distribuicao_votacao.locais[local_id]
         end

         puts "***************************************"
         puts hash_geojson.to_json
         puts "***************************************"

      end

# esquema de cores javascript para os mapas ['#feedde','#fdbe85','#fd8d3c','#e6550d','#a63603']


      puts "\n\n************* " + @dados.to_s + "*************\n\n"
      @meses = ['janeiro', 'fevereiro', 'marco', 'abril', 'maio', 'junho', 'julho']

    end
end

