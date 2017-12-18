=begin
Implementa as estatisticas a respeito de uma eleicao, incluindo as estatisticas
(factuais) com nas simulacoes.

contexto
total votos
brancos
nulos

saída:
percentual dos votos gerais
percentual dos votos eleitos
percentual dos votos partido
percentual dos votos legenda
percentual nos próprios votos (contribuição)
posicao - partido - abs e em Qs
posicao - legenda
posicao - geral
posicoes em Qs
estatisticas temporais
=end

require 'places/location_model'
require 'cepesp/eleicao'
require 'descriptive_statistics/safe'

PRECISAO_PERCENTUAL=3

class EstatisticaEleicao

  attr_reader :cargo, :localizacao, :estatisticas

  def initialize(cargo, local)
    @cargo = cargo
    @local = local # deve ser objeto de places/location_model
    @local_id = (@local.is_a? Estado)? @local.sigla : @local.id # deve ser identificador usado no CEPESP
    @votacao_anos = {}
    @legendas_anos = {}
    @votos_legenda_anos = {}
    @resultado_anos = {}
    @estatisticas = {}
    @votacao_legendas_hash = {}
    @locais_analise = {} # lista das localizacoes consideradas na analise estatistica
  end

=begin

  # Acrescenta um local na lista de locais para analise de eleicao
  def add(local_analise)
    if @locais_analise[local_analise.to_sym] == nil then
      @locais_analise[local_analise.to_sym] = {}
    end
    @locais_analise[local_analise.to_sym][local_analise.id] = local_analise
    # recomputa analise
  end

  # Acrescenta um local na lista de locais para analise de eleicao
  def remove(local_analise)
    if @locais_analise[local_analise.to_sym] != nil then
      @locais_analise[local_analise.to_sym].delete(local_analise.id)
    end
    # recomputa analise
  end

  def locais_hash
    return @locais_analise
  end


Requisito: não podem existir duas localizacoes com intersecção de áreas, ou Todas
as localizações devem ser disjuntas. Se aparecerem duas

Algoritmo: Do escopo mais amplo (pais) ao mais específico (municipio)
Se escopo_candidatura é maior que da localizacao, então
   total_escopo = total_escopo?
   total_local = total_escopo_localizacao
   total_local_individual
Se escopo é igual, os dois são iguais
Se escopo é menor
   local <= escopo.

total_escopo: votação considerada a total para estatística coletada
total_local: votação considerada a total para o escopo da localizacao
total_local_individual: votação total para a localização específica

#  $AGREGACAO = { :brasil => 0 }

#  $ESCOPO_CARGO = { :presidente => 0 }


  def recompute_eleicao()
    escopos = [:brasil, :macro, :estado, :meso, :micro, :municipio]

    if @locais_analise[:macro] then
      @locais_analise[:macro].each do |local_id, local|
        total_escopo
        total_local
        total_individual
        if $ESCOPO_CARGO[@cargo] < $AGREGACAO[:macro] then

        end
      end
    end
  end
=end


  def compute_eleicao(ano, tipo_localizacao)
    dados_votacao = DadosCepesp.pesquisa_eleicao_votos_regiao(ano, @cargo, tipo_localizacao, @local_id)
    dados_candidatos = DadosCepesp.pesquisa_dados_candidato(ano, @cargo)

    @votacao_anos[ano] = {}
    @votacao_legendas_hash[ano] = {}
    Rails.logger.debug("[Legenda.get(ano, @cargo, @localizacao)]: " + ano.to_s + "," + @cargo.to_s + "," + @local.estado.sigla)
    @legendas_anos[ano] = Legenda.get(ano, @cargo, @local.estado.sigla) # atributos (sigla) deveriam ser escondidos em chamadas internas
    Rails.logger.debug("\n\n")

    if tipo_localizacao == :municipio then
      # Restricao do CEPESP.io para fins de escalabilidade:
      # Todas as consultas por municipios devem ser filtradas por estado
      # e id_municipio, do contrário a consulta é inválida
      eleicao_coligacao = DadosCepesp.get_eleicao_coligacao(@cargo,ano,tipo_localizacao,@local_id)
      Rails.logger.debug("[compute_eleicao] " + eleicao_coligacao.keys().to_s)
      @votacao_legendas_hash[ano] = totaliza_votos_legendas(eleicao_coligacao[@local_id])
    else
      eleicao_coligacao = DadosCepesp.get_eleicao_coligacao(@cargo,ano,tipo_localizacao)
      Rails.logger.debug("[compute_eleicao] " + eleicao_coligacao.keys().to_s)
      @votacao_legendas_hash[ano] = totaliza_votos_legendas(eleicao_coligacao[@local_id])
    end

    @votacao_legendas_hash[ano].each do |chave, votos_de_legenda|
      Rails.logger.debug(chave + " - " + votos_de_legenda[:total].to_s + "/" + votos_de_legenda[:votos_nominais].to_s + "/" + votos_de_legenda[:legendas_isoladas].to_s)
    end
    Rails.logger.debug("\n")

    # @votos_legenda_anos[ano] = dados_votacao["#NULO#"]
    dados_votacao.each do | titulo, dado |
      if titulo == $STRINGS_CEPESP[:titulo_votos_legenda] then
        @votos_legenda_anos[ano] = dado
      else
        @votacao_anos[ano][titulo] = dado
      end
    end

    # recupera resultado da eleicao (votos totais, brancos, ...)
    DadosCepesp.get_eleicao(@cargo,ano).each do |resultado_eleicao|
       if resultado_eleicao.uf == @local.estado.sigla then
          @resultado_anos[ano] = resultado_eleicao
      end
    end

    dados_votacao.each do | titulo, dados |
      if (dados_candidatos[titulo] == nil) then
         Rails.logger.error("[CEPESP.IO] Candidato com titulo de eleitor = #{titulo} inexistente! Detalhes: " + dados[0].to_s)
         dados[0].nome_urna_candidato = "Erro na base de dados: CANDIDATO DESCONHECIDO"
      else
         dados[0].nome_urna_candidato = dados_candidatos[titulo][0].nome_urna_candidato
         dados[0].des_situacao_candidatura = dados_candidatos[titulo][0].des_situacao_candidatura
         dados[0].desc_sit_tot_turno = dados_candidatos[titulo][0].desc_sit_tot_turno
         dados[0].resultado_eleicao = $RESULTADO_ELEICAO[dados_candidatos[titulo][0].cod_sit_tot_turno.to_i]
      end
   end
   estatistica_legendas(ano)
   estatistica_votos_candidatos(ano)
  end

  # Totaliza os votos das legendas, computando um único valor pela coligação,
  # necessario pois os dados de coligações vindos do CEPESP vem repetidos,
  # incluindo votos nominais da legenda e votos de cada partido.
  # Exemplo: (coligações para deputado federal em Goias, 2014)
  # PSB / PSC / PRP - 144960
  # PSB / PSC / PRP - 2284
  # PSB / PSC / PRP - 13691
  # PSB / PSC / PRP - 1746
  # Deve ser interpretado: 144960 são votos nominais e o restante os votos dados
  # a cada partido.
  def totaliza_votos_legendas(votos_legendas_discriminados)
    votos_totalizados = {}
    votos_legendas_discriminados.each do | legenda |
      if votos_totalizados[legenda.composicao_coligacao] == nil then
        votos_totalizados[legenda.composicao_coligacao] = {}
        votos_totalizados[legenda.composicao_coligacao][:votos_nominais] = legenda.qtde_votos.to_i
        votos_totalizados[legenda.composicao_coligacao][:legendas_isoladas] = 0
        votos_totalizados[legenda.composicao_coligacao][:total] = legenda.qtde_votos.to_i
      else
        votos_totalizados[legenda.composicao_coligacao][:legendas_isoladas] += legenda.qtde_votos.to_i
        votos_totalizados[legenda.composicao_coligacao][:total] += legenda.qtde_votos.to_i
      end
    end
    return votos_totalizados
  end


  def candidatos(ano)
    return @votacao_anos[ano]
  end

# Estatisticas planejadas e nao incorporadas
# percentual de votos no partidos
# percentual de votos na legenda
#  percentual dos votos eleitos
#  percentual nos próprios votos (contribuição)
#  posicao - partido - abs e em Qs
# posicao - legenda
# posicao - geral
# posicao - eleitos
# posicoes em Qs

  def estatistica_votos_candidatos(ano)
    @estatisticas["votos_candidatos"] = ["percentual_votos_localizacao"]
    @estatisticas["votos_candidatos"] << ["percentual_votos_gerais"]
    @estatisticas["votos_candidatos"] << ["percentual_votos_validos"]

    total_votos_localizacao = 0
    total_votos_gerais = resultado(ano).qtd_comparecimento.to_i
    total_votos_validos = resultado(ano).qtd_comparecimento.to_i -
              resultado(ano).qt_votos_brancos.to_i -
              resultado(ano).qt_votos_nulos.to_i
    self.candidatos(ano).each do |titulo, cand|
      if cand[0].des_situacao_candidatura == "DEFERIDO" then
         total_votos_localizacao += cand[0].qtde_votos.to_i
     end
    end
    self.candidatos(ano).each do |titulo, cand|
       cand[0].percentual_votos_localizacao = (100*(cand[0].qtde_votos.to_f / total_votos_localizacao)).round(PRECISAO_PERCENTUAL)
       cand[0].percentual_votos_validos = (100*(cand[0].qtde_votos.to_f / total_votos_validos)).round(PRECISAO_PERCENTUAL)
       cand[0].percentual_votos_gerais = (100*(cand[0].qtde_votos.to_f / total_votos_gerais)).round(PRECISAO_PERCENTUAL)
    end
  end

  def legendas(ano)
    return @legendas_anos[ano]
  end
  ## numero de partidos por legenda
  def estatistica_legendas(ano)
    @estatisticas["legendas"] = "numero_partidos"
    @legendas_anos[ano].each do | partido, legenda |
      partidos_str = legenda.composicao_coligacao
      legenda.numero_partidos = partidos_str.split("/").size
    end
  end


  def votos_legenda(ano)
    return @votos_legenda_anos[ano]
  end

  # percentual de votos entre legendas
  # percentual de votos do total por legenda
  def estatisticas_votos_legenda(ano)
    @estatisticas["votos_legendas"] = ["percentual_votos_entre_legendas"]
    @estatisticas["votos_legendas"] << "percentual_votos_do_total"
    @estatisticas["votos_legendas"] << "percentual_votos_do_total_valido"

    total_votos_legenda
    @votacao_legendas_hash[ano].each do |chave, votos_de_legenda|
    end

# suspenso ate o termino da implementacao de uma consulta
=begin
    total_votos_legenda = @resultado_anos[ano].qt_votos_legenda
    total_votos = @resultado_anos[ano].qtd_comparecimento
    total_votos_validos = @resultado_anos[ano].qt_votos_nominais + @resultado_anos[ano].qt_votos_legenda
    @votos_legenda_anos[ano].each do |legenda|
      legenda.percentual_votos_entre_legendas = legenda.
      legenda.percentual_votos_do_total =
      legenda.percentual_votos_do_total_valido =
    end
=end
  end

# Params:
# - escopo_localizacao: um escopo de localizacao
# - local: o identificador do local atual (de acordo com o escopo), mas pesquisa
#          deve ser feita pelo identificador um nivel acima hierarquicamente
  def self.distribuicao_votacao_candidato(ano, cargo, candidato, local, escopo_localizacao)
    Rails.logger.debug("[distribuicao_votacao_candidato]: " + local.to_s + ", " + escopo_localizacao.to_s)

    local_superior = nil
    locais_mesmo_nivel = nil

    ## correcao de issue 36: modificar o codigo abaixo que esta recuperando apenas
    ## os objetos dentro da mesma microrregiao. deve subir mais um nivel e depois
    ## pegar tudo nos niveis abaixo

    case escopo_localizacao.to_sym
    when :municipio
      local_superior = Municipio.municipios[local].estado
      locais_mesmo_nivel = []
      local_superior.mesorregioes.each do | meso_local_superior |
         meso_local_superior.microrregioes.each do | micro_local_superior |
            locais_mesmo_nivel.concat(micro_local_superior.municipios)
         end
      end

      local_superior.municipios
    when :micro
      local_superior = Microrregiao.microrregioes[local].estado
      locais_mesmo_nivel = []
      local_superior.mesorregioes.each do | meso_local_superior |
         locais_mesmo_nivel.concat(meso_local_superior.microrregioes)
      end
    when :meso
      local_superior = Mesorregiao.mesorregioes[local].estado
      locais_mesmo_nivel = local_superior.mesorregioes
    when :estado
      local_superior = Estado.estados[local].macroregiao
      locais_mesmo_nivel = local_superior.estados
    end

    distribuicao_votacao = DistribuicaoEspacialVotacao.new(ano, cargo, escopo_localizacao, local)

    votacoes_locais = []
    locais_mesmo_nivel.each do |local_vizinho|
      # pesquisa retorna uma hash indexada por numero_candidato com a votacao naquele local
      begin
         votacao = DadosCepesp.pesquisa_eleicao_votos_regiao(ano, cargo, escopo_localizacao, local_vizinho.id)[candidato]
         # so ha um local que atende a restricao pois escopo_localizacao, local_vizinho.id sao do mesmo nivel
         if votacao then
            votacoes_locais << votacao[0]
            distribuicao_votacao.add_local(local_vizinho.id, votacao[0])
            Rails.logger.debug("[votacoes_locais] = [" + local_vizinho.id + "] = " + votacao[0].qtde_votos + " votos de " + votacao.size.to_s)
         end
      rescue => e
         Rails.logger.error("Erro na pesquisa [pesquisa_eleicao_votos_regiao]" + e.to_s)
      end
    end

   return distribuicao_votacao

  end

  def resultado(ano)
    return @resultado_anos[ano]
  end

end

class DistribuicaoEspacialVotacao
  def initialize(ano, cargo, escopo, local_base)
     @locais = {}
     @ano = ano
     @cargo = cargo
     @escopo = escopo
     @local_base = local_base
     @total_votacao = 0
  end

  attr_reader :ano, :cargo, :escopo, :local_base, :locais

  def total_votacao
     @total_votacao
  end

  def add_local(id_local, votacao)
     @locais[id_local] = votacao.qtde_votos.to_i
     @total_votacao += @locais[id_local]
  end

  # Retorna dados das votacoes com acesso aos metodos de descriptive_statistics:
  # data:
  # data.sum, data.mean, data.median, data.variance, data.standard_deviation,
  # data.percentile(30), data.percentile(70), data.percentile_rank(8),
  # data.mode, data.range
  def data
     @locais.values
  end

  def data_percentile
     if (@locais.values.size > 0) then
     percentis = [
           @locais.values.percentile(20).round(0),
           @locais.values.percentile(40).round(0),
           @locais.values.percentile(80).round(0),
           @locais.values.percentile(60).round(0),
           @locais.values.percentile(100).round(0)
        ]
     else
        percentis = []
     end
  end

  def to_s
     @locais.to_s
  end




end
