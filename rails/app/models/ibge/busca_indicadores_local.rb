require 'json'
require 'open-uri'
require 'ibge/indicador'



class DadosIndicador

	attr_accessor :indicador, :cidade, :dados

	#Dados é um hash contendo o ano daquele dado como chave
	def initialize(indicador, cidade, dados={})
		@indicador = indicador
		@dados = dados
		@cidade = cidade
	end

	def add_ano(ano, dado)
		@dados.store(ano, dado)
	end

	def to_s
		s = "#{@cidade} - #{@indicador.to_s}"
		dados.each_key {|key| s+= "\nAno #{key} o dado foi #{dados[key]} #{@indicador.unidade}"}
		s
	end

	class << self

		def gerar_codigo_7_digitos(num)
			num_ant = String(num)
			peso = "121212"
			soma = 0
			for i in 0..5
				valor = Integer(num_ant[i]) * Integer(peso[i])
				if valor > 9
					valor = String(valor)
					soma += Integer(valor[0]) + Integer(valor[1])
				else
					soma += valor
				end
			end
			dv = 10 - (soma % 10)
			if ((soma % 10) == 0)
				dv = 0
			end
			return Integer(num_ant+String(dv))
		end


		def buscar(localidade, e_indicadores)
			dados = {}

			if (localidade.class == Array)
				cidades = localidade.clone
			elsif localidade.class == Municipio
				cidade = [localidade]
			else
				cidades = localidade.municipios
			end

			separador = "%7C"

			indicadores = e_indicadores.clone
			url = Indicador.URL_INDICADORES
			if indicadores.class == Integer
				indicadores = {indicadores => Indicador.new(indicadores)}
			elsif indicadores.class == Indicador
				indicadores = {indicadores.id => indicadores}
			elsif indicadores.class == Array
				ind = {}
				indicadores.each do |i|
					if i.class == Integer
						ind.store(i,Indicador.new(i))
					elsif i.class == Indicador
						ind.store(i.id, i)
					else
						Rails.logger.error("Indicadores em formato desconhecido "+ DadosIndicador.class.to_s)
					end
				end
			else
				Rails.logger.error("indicadores em formato desconhecido "+DadosIndicador.class.to_s)
			end

			indicadores.each_key {|i| url += indicadores[i].id.to_s+separador}

			url = url.slice(0, url.length-3)
			url += "/resultados/"

			#O limite da API do IBGE é de 26 cidades
			if (cidades.length > 26)
				segunda_consulta = cidades.slice(26, cidades.length)
				cidades = cidades.slice(0, 26)
				dados.merge! buscar(segunda_consulta, indicadores)
			end
			cidades.each do |cidade|
				id = nil
				if cidade.class == Integer or cidade.class == String
					id = cidade
				else
					id = cidade.cod_ibge
				end
				url += (id.to_s+"%7C")
				#dados.store(Integer(id.to_s.slice(0,6)), {})
				dados.store(Integer(id), {})
			end

			url = url.slice(0, url.length-3)

			Rails.logger.debug("Busca por indicador e localidades: GET " + url)
			begin
				content = get_remote_resource(url, logger=Rails.logger)[:body]
			rescue => e
				Rails.logger.error(e.message.to_s + " - " + e.backtrace.to_s)
				raise e
			end

			json = JSON.parse(content)
			json.each do |ind|
				ind["res"].each do |cid|
					cod = cid["localidade"]
					if cod.length < 7
						cod = gerar_codigo_7_digitos(cod)
					end
					dado = DadosIndicador.new(indicadores[ind["id"]], Integer(cod))
					dado.dados = cid["res"]
					dados[dado.cidade].store(dado.indicador.id, dado)
				end
			end
			return dados
		end

=begin
Retorna um hash contendo o ano como chave e em cada ano contém outro hash contendo os ids das cidades
como chave e o dados referentes àquele indicador. Os descriptivos estatísticos podem ser acessados como 
retorno[ano].descriptive_statistics.
Quando for passado algum ano como argumento será retornado apenas uma hash contendo os ids das cidades
como chave e os dados referentes àquele indicador. Para acessar os descriptivos estatísticos precisamos 
apenas retorno.descriptive_statistics.
LEMBRANDO DE INSERIR O require 'descriptive_statistics' no codigo.

hash_cidades_indicadores é a hash retornada no formato do DadosIndicador.buscar
id_indicadores é o id puro do indicador à ser agrupado, como Indicador.Indicadores_disponiveis
ano é um argumento opcional, se passado algum ano, os dados daquele indicador naquele ano serão 
agrupados, senão será gerada uma hash com os dados de cada ano.
=end
		def get_estatistics(hash_cidades_indicadores, id_indicadores, ano=nil)
			if (ano != nil)
				dados = {}
				hash_cidades_indicadores.each {|id_cidade, hash_indicadores| dados.store(id_cidade, hash_indicadores[id_indicadores].dados[ano.to_s].to_f)}
				return dados
			else
				dados_por_ano = {}
				pool_anos = []
				hash_cidades_indicadores.each do |id_cidade, hash_indicadores|
					hash_indicadores[id_indicadores].dados.each do |key_ano, dado_ano| 
						if not dados_por_ano.include?(key_ano.to_i)
							dados_por_ano.store(key_ano.to_i, {})
						end
						dados_por_ano[key_ano.to_i].store(id_cidade, dado_ano.to_f)
					end
				end
				return dados_por_ano
			end
		end
	end
end


=begin
teste = ["2806404", "2800100", "2800704", "2801108", "2801603", "2802700", "2804409", "2804706", "2805703", "2807303", "2800308", "2800605", "2804805", "2806701", "2800407", "2800670", "2801702", "2803005", "2805109", "2806206", "2807501", "2807600", "2801306", "2802007", "2806503", "2807204", "2801504", "2802502", "2803609", "2804003", "2805901", "2806107", "2806602", "2802106", "2802809", "2803203", "2806305", "2803302", "2803401", "2804904"]
res = DadosIndicador.buscar(teste, Indicador.IDH)
=end

=begin
Exemplo de uso
inds = Indicador.get_indicadores(Indicador.PIB_PER_CAPTA, Indicador.HABITANTES, Indicador.IDH)
dados = DadosIndicador.buscar(420540, inds)
dados.each_key {|key| puts dados[key].to_s}
ou
inds = Indicador.get_indicadores(Indicador.PIB_PER_CAPTA, Indicador.HABITANTES, Indicador.IDH)
dados = DadosIndicador.buscar([420540,310620] , inds)
dados.each_value {|cidade| cidade.each_key {|key| puts cidade[key].to_s}}
=end



=begin
#Para pegar as informações sobre um, ou vários indicadores
#https://servicodados.ibge.gov.br/api/v1/pesquisas/indicadores/$id_indicador
# 60047 PIB per capta
PIB_PER_CAPTA = 60047

content = open("https://servicodados.ibge.gov.br/api/v1/pesquisas/indicadores/60047").read()
indicadores = JSON.parse(content)

#Para os resultados daquele indicador chamamos
#https://servicodados.ibge.gov.br/api/v1/pesquisas/indicadores/$id_identificador/resultados/$id_cidade
BELO_HORIZONTE = 310620

content = open("https://servicodados.ibge.gov.br/api/v1/pesquisas/indicadores/60047/resultados/310620").read()
resultado = JSON.parse(content)
pib = resultado[0]["res"][0]["res"]

puts ("Sobre Belo Horizonte")
pib.each_key do |ano|
	print("No ano #{ano} o PIB per Capta foi de #{pib[ano]}\n")
end
=end
