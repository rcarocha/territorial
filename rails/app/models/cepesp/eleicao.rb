require 'tse/consultas_tse'

$CARGOS = {
   :presidente => 1,
   :governador => 3,
   :senador => 5,
   :deputado_federal => 6,
   :deputado_estadual => 7,
   :deputado_distrital => 8,
   :prefeito => 11,
   :vereador => 13}

$AGREGACAO = {
   :brasil => 0,
   :macro => 1,
   :estado => 2,
   :meso => 4,
   :micro => 5,
   :municipio => 6,
   :municipiozona => 7,
   :zona => 8,
   :secaovotacao => 9,
}

$ESCOPO_CARGO = {
  :presidente => 0,
  :governador => 2,
  :senador => 2,
  :deputado_federal => 2,
  :deputado_estadual => 2,
  :deputado_distrital => 2,
  :prefeito => 6,
  :vereador => 6
}

$AGREGACAO_REGIONAL = $AGREGACAO

$AGREGACAO_POLITICA = {
   :legenda => 1,
   :candidato => 2,
   :coligacao => 3,
   :consolidado_eleicao => 4
}

$DES_SITUACAO_CANDIDATURA = {
   :na => "-", # usado em votos para legendas
   :deferido => "DEFERIDO",
   :indeferido => "INDEFERIDO",
   :renuncia => "RENÚNCIA",
   :nao_conhecimento_do_pedido => "NÃO CONHECIMENTO DO PEDIDO",
   :falecido => "FALECIDO",
   :cancelado => "CANCELADO"
}

$COD_SIT_TOT_TURNO = {
   :nulo  => -1,
   :indefinido  => 1,
   :eleito_por_qp  => 2,
   :eleito_por_media => 3,
   :nao_eleito => 4,
   :suplente => 5
}

$STRINGS_CEPESP = {
  :titulo_votos_legenda => "#NULO#" #titulo de eleitor que indica votos em legenda
}

$ESCOPO_CANDIDATURA = { # escopo de localizacao em que uma candidatura se aplica
  :presidente => :brasil,
  :governador => :estado,
  :senador => :estado,
  :deputado_federal => :estado,
  :deputado_estadual => :estado,
  :deputado_distrital => :estado,
  :prefeito => :municipio,
  :vereador => :municipio
}

$RESULTADO_ELEICAO = $COD_SIT_TOT_TURNO.invert

# Armazena os dados de um candidato, indicando ano e local à que a candidatura
# se aplica, assim como a validade da candidatura.

class Candidato
  attr_accessor :ano, :local, :nome, :id, :partido, :isCandidaturaValida

  def initialize params = {}
    params.each { |key, value| send "#{key}=", value }
	@initialized = true
  end

  def initialized?
    @initialized || false
  end

  def to_s ()
	self.inspect
  end
end


class Eleicao
  attr_accessor :ano, :candidatos, :turno, :id, :uf, :votos_validos, :qtde_vagas

  def initialize params = {}
    params.each { |key, value| send "#{key}=", value }
	quociente_eleitoral = votos_validos/numero_cadeiras
	@initialized = true
  end

  def initialized?
    @initialized || false
  end

  def to_s ()
	self.inspect
  end
end

# Classe "Votacao" armazena o conjunto de votos associado a um certo contexto
# (por exemplo, localização e ano), permitindo recuperar a votação por partido
# e os votos nulos e brancos quando se tratar de um conjunto de votos (e não
# um voto unitário de um candidato).

class Votacao

attr_accessor :ano_eleicao ,:sigla_ue ,:num_turno ,:descricao_eleicao ,:cargo, :descricao_cargo, :numero_candidato, :qtde_votos

  def initialize params = {}
    params.each { |key, value| send "#{key}=", value }
	@initialized = true
  end

  def initialized?
    @initialized || false
  end

  def to_s ()
	self.inspect
  end

end

# Armazena um partido (nome, sigla, número)



class Partido

attr_accessor :nome, :sigla, :numero, :quociente_eleitoral, :quociente_partidario ,:qtde_votos, :sobras

# armazena contextos eleitorais em função da tripla (ano, cargo, localizacao),
# permitindo guardar o seu desempenho nessa situação, coligações, votos por
# partido recebidos, seus candidatos
@@contextos = {}

  def initialize params = {}
    params.each { |key, value| send "#{key}=", value }
	quocientePartido = (qtde_votos/quociente_eleitoral).floor
	sobras = qtde_votos/(quociente_partidario)
	@initialized = true
  end

  def initialized?
    @initialized || false
  end

  def self.get_contexto
  end

  def desempenho(ano, cargo, localizacao)
  end

  def coligacao(ano, cargo, localizacao)
  end

  def to_s ()
	self.inspect
  end
end

# Armazena os dados de uma legenda, indicando o contexto eleitoral em que ela se
# aplica.

class Legenda

   attr_accessor :ano_eleicao, :num_turno, :descricao_eleicao, :sigla_uf, :sigla_ue, :descricao_ue, :cargo, :tipo_legenda,:sigla_coligacao, :nome_coligacao,:composicao_coligacao

   @@legendas_eleicoes = {}

   def initialize params = {}
      params.each { |key, value| send "#{key}=", value }
      @initialized = true
   end

  def initialized?
    @initialized || false
  end

  # Params:
	# - localizacao: identificador do estado ao qual a legenda se aplica
  def self.get(ano=nil, cargo=nil, localizacao=nil)
     if @@legendas_eleicoes[ano] && @@legendas_eleicoes[ano][localizacao] &&
        @@legendas_eleicoes[ano][localizacao][cargo] then
        return @@legendas_eleicoes[ano][localizacao][cargo]
     else
        legendas = DadosCepesp.pesquisa_legenda(localizacao, ano, cargo)
        novo_grupo_legendas = Legenda.init_hashkey(init_hashkey(init_hashkey(@@legendas_eleicoes, ano),localizacao),cargo)
        legendas.each do |legenda|
           novo_grupo_legendas[legenda.numero_partido] = legenda
        end
        return @@legendas_eleicoes[ano][localizacao][cargo]
     end
  end



  def to_s ()
	self.inspect
  end

private
   def self.init_hashkey(hash, key)
      if !hash[key] then
         hash[key] = {}
      end
      return hash[key]
   end

end

class Vagas

   @@vagas_tse = $vagas # mantem referencia para objeto vagas de tse/consulta_vagas

   # Retorna o numero de vagas para um certo cargo na eleicao de um local.
   #
   # Exemplo de uso:
   # require './brasil_symb_location.rb' #=> necessario para carregar localizacoes
   #
   # sp = Estado.estados[20]
   # vagas = get_vagas_eleicao("2014", :deputado_federal, sp) #=> deve retornar 70
   #
   def self.total_vagas(ano, cargo, localizacao)
      get_vagas_eleicao(ano, cargo, localizacao)
   end
end
