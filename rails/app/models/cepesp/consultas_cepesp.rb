#TODO -> Dada uma eleicao, retone uma lista de candidatos por votos por região
#	-> Dado o numero e estado do candidato, retorne-o
# 	-> CODIGO_LEGENDA
# 	-> isEleito
#
require 'net/http'
require 'uri'
require 'ostruct'
require 'set'

require 'cepesp/eleicao'
require 'cepesp/add_filter'
require 'tse/consultas_tse'
require 'places/brasil_symb_location'

require 'cache/service_request_cache.rb'

$cache_objetos_memoria = CacheObjetosRequisicao.new

def get_mem_cache(contexto, url, metodo_processa=nil, tipo_chave=nil)
	memhash = gen_keyhash("http://cepesp.io/api/consulta/"+contexto.to_s+"?"+url)
	Rails.logger.debug("\n\n[get_mem_cache] : (" + contexto.to_s  + ",\t\n" +  url.to_s + ", \t\n" +  (metodo_processa==nil ? "nil" : metodo_processa.to_s) + ",\t\n" + (tipo_chave==nil ? "nil" : tipo_chave.to_s) + ")\n\n")

	if $cache_objetos_memoria.cached?(memhash) then
		Rails.logger.debug("[pesquisa_candidatos] Em cache de MEMORIA :" + url + ":  [" + memhash + "]\n")
		return $cache_objetos_memoria.get(memhash)
	else
		if metodo_processa then
			res = self.send(metodo_processa, contexto, url, tipo_chave)
		else
			res = self.processa(contexto,url)
		end

		$cache_objetos_memoria.store(memhash, res)
		return res
	end
end

class DadosCepesp
	#Entrada:Os parametros de busca para pesquisa na CEPESP:
	#Saida: O status code da http request e, se possível, os resultados da busca.
	def self.recuperaFonte(contexto,params)
		uri = URI.parse("http://cepesp.io/api/consulta/"+contexto+"?"+params)
		Rails.logger.debug("Backend Request => " + uri.to_s)

		# requisicao antiga nao cacheada
		# s = response = Net::HTTP.get_response(uri)

		s = response = get_remote_resource(uri.to_s, request_parameters={}, logger=Rails.logger)

		return s
	end

	# Entrada: string onde a primeira linha é o cabeçalho csv e as demais as tuplas
	# Saida: lista de objetos dinamicos
	def self.processa (contexto,s)
		s = s[1 .. -2]

		raw = recuperaFonte(contexto.to_s,s)[:body].split("\n")

	  separador = tipo_separador_itens(raw[0])
		chaves = separa_itens(raw[0].downcase, separador)
    Rails.logger.debug("*** [self.processa] *** chaves = " + chaves.to_s + "\n")

		conjunto = raw[1 .. -1]
		vetor_ostruct = []
		i = 1
		conjunto.each do | linha |
				dados_linha = separa_itens(linha, separador)
				vetor_ostruct << OpenStruct.new(Hash[chaves.zip(dados_linha)])
		end
		Rails.logger.debug("[self.processa] new_element[0] = " + vetor_ostruct[0].to_s)

		return vetor_ostruct

	end

	# Transforma uma chave relativa, comum em respostas CEPESP.io, e que não
	# oferece unicidade de indicadores, em uma chave absoluta.
	# Essecialmente necessário em duas situações: para identificar unicamente
	# mesorregioes e microrregioes, cujo id deve ser uma composição com o id de
	# estado (ver respectivas classes em location_model.rb).
	def self.keybuilder(key_name, key_val, estado_id)
		if key_name.upcase == "CODIGO_MESO" then
			return "%s%02d" % [estado_id, key_val]
		elsif key_name.upcase == "CODIGO_MICRO" then
			return "%s%03d" % [estado_id, key_val]
		end
		return key_val
	end


  def self.separador_linha_aspas(s)
		lista = []
		itens = s.split(/","/)
		# remove aspas no incio do primeiro item
		lista << itens[0][1..-1]
		for i in 1..(itens.size - 2)
			 lista << itens[i][0..-1]
		end
		# remove aspas no final do ultimo item
		lista << itens[itens.size-1][0..-2]
		return lista
	end

	def self.separador_linha_virgula(s)
		return s.split(/,/)
	end

	def self.separa_itens(string, separador)
		if separador == :virgulas then
			return self.separador_linha_virgula(string)
		else
			return self.separador_linha_aspas(string)
		end
	end

	def self.tipo_separador_itens(s)
		numero_aspas = s.count("\"")
		if numero_aspas > 0 then
			separador = :aspas
			if numero_aspas.odd? then
				Rails.logger.debug("[self.novo_processa] Numero de separadores encontrado INCONSISTENTE!")
			end
		else
			# nao usa aspas
			separador = :virgulas
		end
		return separador
	end

	def self.novo_processa(contexto,s,key)
		s = s[1 .. -2]
		key = key.downcase
		raw = recuperaFonte(contexto.to_s,s)[:body].split("\n") # nao eh eficiente para dados grandes

		#testa se saida usa aspas como separador
    separador = tipo_separador_itens(raw[0])

		chaves = separa_itens(raw[0].downcase, separador)
		elems = {}

		for i in 1..raw.length-1
			elem_raw = {}
			line = separa_itens(raw[i], separador)
			chaves.each_index {|j| elem_raw.store(chaves[j], line[j])}

			elem = OpenStruct.new elem_raw

			key_value = keybuilder(key, elem.send(key), Estado.estados_id_by_sigla[elem_raw["uf"]])

			# deixar o acesso as chaves de elems otimizado e mais legivel
			if (elems[key_value] == nil)
				elems.store(key_value, [elem])
			else
				elems.store(key_value, elems[key_value] << elem)
			end
		end

		Rails.logger.debug("[self.novo_processa] new_elem[" + elems.keys[0].to_s  + "] = [" +
			(elems[elems.keys[0]]!=nil ? elems[elems.keys[0]][0].to_s : "nil") + ", ...]\n")

		return elems
	end

	def self.adicionar_coluna(colunas)
		s = ""
		colunas.each {|col|
			s+="&selected_columns%5B%5D="+col.to_s
		}
		return s
	end

	# Pesquisa candidatos por `localização`, `ano`, `cargo`, `partido` e `número`,
	# retornando o(s) candidato(s) que se adequem aos critérios pesquisados.
	# Os candidatos retornados indicam se a candidatura dos mesmos é válida.
	def self.pesquisa_candidatos(ano=nil, cargo=nil, partido=nil, numero=nil)
		s =
			(ano==nil ? "" : "&ano="+ano.to_s)+
			(cargo==nil ? "" : "&cargo="+cargo.to_s)+
			(partido==nil ? "" : "&partido="+partido.to_s)+
			(numero==nil ? "" : "&numero="+numero.to_s)+
			("&selected_columns%5B%5D=NOME_CANDIDATO" +
			"&selected_columns%5B%5D=NUMERO_CANDIDATO" +
			"&selected_columns%5B%5D=CPF_CANDIDATO" +
			"&selected_columns%5B%5D=NOME_URNA_CANDIDATO" +
			"&selected_columns%5B%5D=DES_SITUACAO_CANDIDATURA" +
			"&selected_columns%5B%5D=COD_SIT_TOT_TURNO" +
			"&selected_columns%5B%5D=DESC_SIT_TOT_TURNO" +
			"&selected_columns%5B%5D=NUM_TITULO_ELEITORAL_CANDIDATO" +
			"&selected_columns%5B%5D=CODIGO_LEGENDA")+
			"&"#formatando os parametros da request na url da cepesp

	  res = get_mem_cache(:candidatos, s)

		return res
	end

   def self.pesquisa_dados_candidato(ano, cargo, numero_titulo=nil)
		s =
			(ano==nil ? "" : "&ano="+ano.to_s) +
			(cargo==nil ? "" : "&cargo="+cargo.to_s)+
			("&selected_columns%5B%5D=NOME_CANDIDATO" +
			"&selected_columns%5B%5D=NUMERO_CANDIDATO" +
			"&selected_columns%5B%5D=NOME_URNA_CANDIDATO" +
			"&selected_columns%5B%5D=CPF_CANDIDATO" +
			"&selected_columns%5B%5D=DES_SITUACAO_CANDIDATURA" +
		   "&selected_columns%5B%5D=COD_SIT_TOT_TURNO" +
		   "&selected_columns%5B%5D=DESC_SIT_TOT_TURNO" +
			"&selected_columns%5B%5D=NUM_TITULO_ELEITORAL_CANDIDATO" +
			"&selected_columns%5B%5D=CODIGO_LEGENDA")+
			(numero_titulo==nil ? "" : adiciona_filtro(numero_titulo.to_s)) +
			"&"#formatando os parametros da request na url da cepesp

		res = get_mem_cache(:candidatos, s, :novo_processa, "NUM_TITULO_ELEITORAL_CANDIDATO")

	end


	def self.pesquisa_votacao(localizacao=nil, cargo=nil, ano=nil, numero=nil)
	#formatando os parametros da request na url da cepesp
	s = ("&agregacao_regional=" + $AGREGACAO[:secaovotacao].to_s) +
		(localizacao==nil ? "" : "&uf_filter="+localizacao.to_s)+
		(cargo==nil ? "" : "&cargo="+cargo.to_s)+
		(ano==nil ? "" : "&ano="+ano.to_s)+
		(numero==nil ? "" : "&numero="+numero.to_s)+
		"&"

		res = get_mem_cache(:votos, s)
		return res

	end

  # Params:
	# - localizacao: identificador do estado ao qual a legenda se aplica
	def self.pesquisa_legenda(localizacao=nil, ano=nil, cargo=nil)
		s = (localizacao==nil ? "" : "&uf_filter="+localizacao.to_s)+
			(ano==nil ? "" : "&ano="+ano.to_s)+
			(cargo==nil ? "" : "&cargo="+cargo.to_s)+
			"&"#formatando os parametros da request na url da cepesp

		res = get_mem_cache(:legendas, s)
		return res

	end

	def self.pesquisa_eleicao_votos_regiao(ano, cargo)
		Rails.logger.debug("\n[pesquisa_eleicao_votos_regiao]: " + ano.to_s + " - " + cargo.to_s + "\n")
		s = "&agregacao_regional=" + $AGREGACAO[:municipio].to_s +
		"&agregacao_politica="+ $AGREGACAO_POLITICA[:candidato].to_s +
		(ano==nil ? "" : "&anos="+ano.to_s)+
		(cargo==nil ? "" : "&cargo="+cargo.to_s)+
		"&"#formatando os parametros da request na url da cepesp

		res = get_mem_cache(:tse, s)
		return res

	end

	def self.pesquisa_eleicao_votos_regiao(ano, cargo, tipo_regiao, regiao_id=nil)
		Rails.logger.debug("[pesquisa_eleicao_votos_regiao(4p)]: " + ano.to_s + " - " + cargo.to_s + " - " + tipo_regiao.to_s + " - " + regiao_id.to_s + "\n")
		if !(tipo_regiao.is_a? Symbol) then
			tipo_regiao = tipo_regiao.to_sym
		end

		s = "&agregacao_politica="+ $AGREGACAO_POLITICA[:candidato].to_s +
		(tipo_regiao==nil ? "" : "&agregacao_regional="+ $AGREGACAO[tipo_regiao].to_s) +
		(ano==nil ? "" : "&anos="+ano.to_s)+
		(cargo==nil ? "" : "&cargo="+cargo.to_s)+
		adicionar_coluna(["CODIGO_CARGO","NUM_TURNO", "SIGLA_PARTIDO", "DESCRICAO_CARGO", "ANO_ELEICAO", "NUMERO_PARTIDO", "UF","NOME_UF","NUMERO_CANDIDATO", "QTDE_VOTOS", "NUM_TITULO_ELEITORAL_CANDIDATO"])

	    coluna_regiao_id = nil

		if (tipo_regiao==:municipio)
			s += "&agregacao_regional=6"
			s += adicionar_coluna ["COD_MUN_IBGE", "COD_MUN_TSE", "NOME_MUNICIPIO"]
			coluna_regiao_id = "COD_MUN_IBGE"
		elsif tipo_regiao==:macro
			s += "&agregacao_regional=1"
			s += adicionar_coluna ["CODIGO_MACRO", "NOME_MACRO"]
			coluna_regiao_id = "CODIGO_MACRO"
		elsif tipo_regiao==:meso
			s += "&agregacao_regional=4"
			s += adicionar_coluna ["CODIGO_MESO", "NOME_MESO"]
			coluna_regiao_id = "CODIGO_MESO"
		elsif tipo_regiao==:micro
			s += "&agregacao_regional=5"
			s += adicionar_coluna ["CODIGO_MICRO", "NOME_MICRO"]
			coluna_regiao_id = "CODIGO_MICRO"
		elsif tipo_regiao==:estado
			s += "&agregacao_regional=2"
			s += adicionar_coluna ["UF", "NOME_UF"]
			coluna_regiao_id = "UF"
		end

		if regiao_id then
			if (tipo_regiao != :meso) && (tipo_regiao != :micro) then
				# MESO e MICRO regiao no CEPESP.io possuem identificador relativo
				# ao estado (e nao unico), por isso o id_meso ou id_micro deve ser
				# ignorado na filtragem da pesquisa.
				# O resultado restrito (da meso ou micro) e recuperado por quem
				# executou a requisicao.
				if (tipo_regiao == :estado) then
					s += adiciona_filtro_livre([coluna_regiao_id], [regiao_id.to_s])
				elsif (tipo_regiao == :municipio) then
					s += adiciona_filtro_livre(
						[coluna_regiao_id, "UF"], [regiao_id.to_s, Municipio.municipios[regiao_id.to_s].estado.sigla])
				end
			else
				# usa identificador relativo das regioes + sigla_estado
				if tipo_regiao == :meso then
					s += adiciona_filtro_livre(
						["UF", coluna_regiao_id],
						[Mesorregiao.mesorregioes[regiao_id].estado.sigla,
						 Mesorregiao.mesorregioes[regiao_id].id_rel.to_s])
				else # tipo_regiao eh microrregiao
					s += adiciona_filtro_livre(
						["UF", coluna_regiao_id],
						[Microrregiao.microrregioes[regiao_id].estado.sigla,
						 Microrregiao.microrregioes[regiao_id].id_rel.to_s])
				end

			end
		end

		s+="&"#formatando os parametros da request na url da cepesp

		res = get_mem_cache(:tse, s, :novo_processa, "NUM_TITULO_ELEITORAL_CANDIDATO")

		return res

	end



# Consulta
# curl -i -g -X GET "http://cepesp.io/api/consulta/tse?cargo=6&agregacao_regional=2&agregacao_politica=4&ano=2014"
# retornando as colunas:
# "CODIGO_CARGO","UF","NUM_TURNO","DESCRICAO_CARGO","ANO_ELEICAO","QTD_APTOS","QTD_COMPARECIMENTO","QTD_ABSTENCOES","QT_VOTOS_NOMINAIS","QT_VOTOS_LEGENDA"
# "

	def self.get_eleicao (cargo=nil,ano=nil)
		s = "&agregacao_regional=" + $AGREGACAO[:estado].to_s +
		(ano==nil ? "" : "&anos[]="+ano.to_s)+
		(cargo==nil ? "" : "&cargo="+cargo.to_s)+
		("&agregacao_politica=" + $AGREGACAO_POLITICA[:consolidado_eleicao].to_s)+
		adicionar_coluna(["CODIGO_CARGO","UF","NUM_TURNO","DESCRICAO_CARGO","ANO_ELEICAO","QTD_APTOS","QTD_COMPARECIMENTO","QTD_ABSTENCOES","QT_VOTOS_NOMINAIS","QT_VOTOS_LEGENDA", "QT_VOTOS_BRANCOS", "QT_VOTOS_NULOS"])+
		"&"#formatando os parametros da request na url da cepesp

		res = get_mem_cache(:tse, s)
		return res
	end

	def self.get_eleicao_coligacao(cargo=nil,ano=nil,agregacao_regional=:estado,regiao_id=nil)
		Rails.logger.debug("\n[get_eleicao_coligacao]: " + cargo.to_s + " - " + ano.to_s + " - " + agregacao_regional.to_s + " - " + (regiao_id==nil ? "nil": regiao_id.to_s) + "\n")
		s = "&agregacao_regional=" + $AGREGACAO[agregacao_regional].to_s +
		(ano==nil ? "" : "&anos[]="+ano.to_s)+
		(cargo==nil ? "" : "&cargo="+cargo.to_s)+
		("&agregacao_politica=" + $AGREGACAO_POLITICA[:coligacao].to_s)+
		adicionar_coluna(["ANO_ELEICAO", "NUM_TURNO", "UF", "CODIGO_CARGO", "DESCRICAO_CARGO", "SIGLA_COLIGACAO", "NOME_COLIGACAO", "COMPOSICAO_COLIGACAO", "QTDE_VOTOS"])+
		"&"#formatando os parametros da request na url da cepesp

		coluna_regiao_id = nil
		tipo_regiao = agregacao_regional
		if (tipo_regiao==:municipio)
			s += "&agregacao_regional=6"
			s += adicionar_coluna ["COD_MUN_IBGE", "COD_MUN_TSE", "NOME_MUNICIPIO"]
			coluna_regiao_id = "COD_MUN_IBGE"
		elsif tipo_regiao==:macro
			s += "&agregacao_regional=1"
			s += adicionar_coluna ["CODIGO_MACRO", "NOME_MACRO"]
			coluna_regiao_id = "CODIGO_MACRO"
		elsif tipo_regiao==:meso
			s += "&agregacao_regional=4"
			s += adicionar_coluna ["CODIGO_MESO", "NOME_MESO"]
			coluna_regiao_id = "CODIGO_MESO"
		elsif tipo_regiao==:micro
			s += "&agregacao_regional=5"
			s += adicionar_coluna ["CODIGO_MICRO", "NOME_MICRO"]
			coluna_regiao_id = "CODIGO_MICRO"
		elsif tipo_regiao==:estado
			s += "&agregacao_regional=2"
			s += adicionar_coluna ["UF", "NOME_UF"]
			coluna_regiao_id = "UF"
		end

		if agregacao_regional == :municipio then
			# Restricao do CEPESP.io para fins de escalabilidade:
			# Todas as consultas por municipios devem ser filtradas por estado
			# do contrário a consulta é inválida
			s += adiciona_filtro_livre(
				[coluna_regiao_id, "UF"], [regiao_id.to_s, Municipio.municipios[regiao_id.to_s].estado.sigla])
		elsif regiao_id then
			s += adiciona_filtro_livre([coluna_regiao_id], [regiao_id.to_s])
		end

		s += "&"

		res = get_mem_cache(:tse, s,:novo_processa, coluna_regiao_id)
		return res
	end

	def self.total_votos_partido (tabelaEleicao,partido=nil)
		totalVotos = 0
		tabelaEleicao.each{ |a| totalVotos += a.sigla_partido==partido ? a.qtde_votos.to_i : 0}
		return totalVotos
	end

	def self.total_votos_eleicao (tabelaEleicao)
		totalVotos = 0
		tabelaEleicao.each{ |a| totalVotos += a.qtde_votos.to_i}
		return totalVotos
	end

	def self.get_partidos (tabelaEleicao)
		s1 = Set.new
		tabelaEleicao.each{ |a| s1.add(a)}
		return s1
	end

	#Dada uma eleicao, retorne as coligacoes e os dados referentes a mesma
	#Exemplo de uso:
	#eleicao = InterfaceDados.get_eleicao(cargo=:deputado_federal ou "6" ou enumeracao equivalente,ano="2014")
	#s = InterfaceDados.get_coligacoes_eleicao(eleicao)
	def self.get_coligacoes_eleicao (tabelaEleicao)
	Rails.logger.debug("\nExtraindo dados da eleicao dada pela tabela abaixo:\n " + tabelaEleicao.to_s)
	coligacoes = Set.new
	tabelaEleicao.each {|a| coligacoes.add(a.composicao_coligacao)}
	coligacoes = coligacoes.to_a

	votos = Set.new
	tabelaEleicao.each {|a| votos.add(a.qtde_votos)}
	votos = votos.to_a

	locais = Set.new
	tabelaEleicao.each {|a| locais.add(a.uf)}
	locais = locais.to_a

	s1 = coligacoes.zip(votos).zip(locais).map{ |a,b,c| OpenStruct.new(:composicao_coligacao => a[0 .. -2], :votos => a[a.length-1], :local => b)}
	return s1
	end


end


=begin
#TODO -> implementar algoritmo para calculo de sobras eleitorais
'''
para i de 1 ate qtdeSobras=SomatorioSobrasPartidos
 para todo partido na eleicao
  calcule o indicador de sobras
  acresca de uma vaga o partido com o maior indice
 fimpara
fimpara
'''
#res = InterfaceDados.pesquisa_eleicao_votos_regiao("6", "2014")
#binding.pry
=end
