class Macroregiao
   def initialize(id, nome, estados=[])
      @id = id
      @nome = nome
      @estados = estados
      @@macroregioes[id] = self
   end

   @@macroregioes = {}

   def self.macroregioes
      @@macroregioes
   end

   def <<(estado)
      @estados << estado
   end

   def municipios
      cidades = []
      @estados.each { |e| cidades += e.municipios}
      return cidades
   end

   attr_accessor :id, :nome

   def estados
      @estados
   end

   def dentro_brasil?
      @nome != "Exterior"
   end

   def exterior?; @nome == "Exterior"; end

   def to_sym
     :macro
   end

   def to_s
      @nome
  	end
end

class Estado
   def initialize(id, nome, macroregiao, mesorregioes=[])
      @id = id
      @nome = nome
      @macroregiao = macroregiao
      @macroregiao << self
      @mesorregioes = mesorregioes
      @@estados[id] = self
      @@estados_id_by_sigla[nome] = id
   end

   @@estados = {}
   @@estados_id_by_sigla = {}

   def <<(mesorregiao)
      @mesorregioes << mesorregiao
	end

   def municipios
      cidades = []
      @mesorregioes.each { |m| cidades += m.municipios}
      return cidades
   end

	attr_accessor :id, :nome

   def mesorregioes
      @mesorregioes
   end

	def macroregiao
   	@macroregiao
	end

   def self.estados
      @@estados
   end

   def self.estados_id_by_sigla
      @@estados_id_by_sigla
   end

   # issue: corrigir, pois nao esta recebendo sigla
	def sigla; @nome; end

  # Metodo para manter transparente o acesso aos campos ao estado em diversos
  # tipos de localizacao (demais classes também possuem).
  def estado
    return self
  end

  def to_sym
    :estado
  end

   def to_s
      @nome
	end
end

class Mesorregiao
   #
   # - id_rel : id relativo da mesorregiao (dentro do estado)
	def initialize(id_rel, nome, estado, microrregioes=[])
      # id unico e composicao de id do estado (que eh unico com id relativo com 2 digitos)
		@id = "%s%02d" % [estado.id, id_rel.to_i]
      @id_rel = id_rel
      @nome = nome
		@estado = estado
		@estado << self
		@microrregioes = microrregioes
		@@mesorregioes[@id] = self
   end

	@@mesorregioes = {}

	def <<(microrregiao)
		@microrregioes << microrregiao
	end

   def municipios
      cidades = []
      @microrregioes.each { |m| cidades += m.municipios }
      return cidades
   end

    attr_accessor :id, :id_rel
    def nome; @nome; end
    def microrregioes; @microrregioes; end
    def estado; @estado; end

   def self.mesorregioes
      @@mesorregioes
   end

   def to_sym
     :meso
   end

   def to_s
      @nome
	end
end

class Microrregiao
	def initialize(id_rel, nome, mesorregiao, municipios=[])
      # id unico e composicao de id do estado (que eh unico com id relativo com 3 digitos)
      @id = "%s%03d" % [mesorregiao.estado.id, id_rel.to_i]
      @id_rel = id_rel
      @nome = nome
      @mesorregiao = mesorregiao
      @mesorregiao << self
      @municipios = municipios
      @@microrregioes[@id] = self
   end

	def <<(municipio)
		@municipios << municipio
	end

   @@microrregioes = {}

	attr_accessor :id, :id_rel
	def nome; @nome; end
	def municipios; @municipios; end
	def mesorregiao; @mesorregiao; end

   def self.microrregioes
      @@microrregioes
   end

   def estado
     @mesorregiao.estado
   end

   def to_sym
     :micro
   end

   def to_s
      @nome
	end
end

class Municipio

   def initialize(cod_ibge, cod_tse, nome, microrregiao)
      @nome = nome
		@estado = microrregiao.mesorregiao.estado
		@microrregiao = microrregiao
		@cod_tse = cod_tse
		@cod_ibge = cod_ibge
		@microrregiao << self
		@@municipios[cod_ibge] = self
	end

	@@municipios = {}

	def id; @cod_ibge; end
	def nome; @nome; end
	def estado; @estado; end

   def id
      @cod_ibge
   end

	def nome_unico
		to_nome_unico(@nome.upcase, @estado.sigla)
   end

   def Municipio.to_nome_unico(nome, sigla_estado)
      return nome.upcase + "/" + sigla_estado
   end

	def microrregiao; @microrregiao; end
	def cod_tse; @cod_tse; end
	def cod_ibge; @cod_ibge; end
	def self.municipios; @@municipios; end

   def to_s
      @nome + " / " + @estado.sigla
	end

  def to_sym
    :municipio
  end

end
