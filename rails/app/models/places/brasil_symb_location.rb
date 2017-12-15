require 'json'
require 'places/location_model.rb'
require 'cache/service_request_cache.rb'

file = File.read("#{Rails.root}/app/assets/data/brasil.json")

Rails.logger.debug("Carregando brasil.json")
brasil_local = JSON.parse(file)
if brasil_local == nil then
	Rails.logger.error("brasil.json nao pode ser carregado em " + "#{Rails.root}/app/assets/data/brasil.json")
end

ja_existentes = []

# issue: ZZ code considerado?

brasil_local["dados"].each do |id_macroregiao, macroregiao|
	novo_macro = Macroregiao.new(id_macroregiao, macroregiao["nome"])
   estados = macroregiao["dados"]
   estados.each do |id_estado, dados_estado|
		novo_estado = Estado.new(id_estado, dados_estado["nome"], novo_macro)
		mesoregioes = dados_estado["dados"]
		mesoregioes.each do |id_mesoregiao, dados_mesoregiao|
			novo_meso = Mesorregiao.new(id_mesoregiao, dados_mesoregiao["nome"], novo_estado)
			microrregioes = dados_mesoregiao["dados"]
			microrregioes.each do |id_microrregiao, dados_microrregiao|
				novo_micro = Microrregiao.new(id_microrregiao, dados_microrregiao["nome"], novo_meso)
				municipios = dados_microrregiao["dados"]
				municipios.each do |id_municipio, municipios_dados|
					novo_municipio = Municipio.new(municipios_dados["cod_mun_ibge"],
					                               municipios_dados["cod_mun_tse"],
					                               municipios_dados["nome"],
					                               novo_micro)
				end
			end
		end
	end
end
Rails.logger.debug("[brasil_symb_location]: Localizacoes administrativas do Brasil carregadas: " +
		Macroregiao.macroregioes.size.to_s  + " macroregiões, " +
		Estado.estados.size.to_s  + " estados, " +
		Mesorregiao.mesorregioes.size.to_s  + " mesorregiões, " +
		Microrregiao.microrregioes.size.to_s  + " microrregiões, " +
		Municipio.municipios.size.to_s + " municípios.")

HOST_IBGE_API_LOC = "servicodados.ibge.gov.br"
PATH_IBGE_API_LOC = "/api/v2/malhas/"
RES_NUM_DEFAULT = 3
TABELA_RESOLUCAO = {
      :brasil => 0,
      :macroregiao => 1,
      :estado => 2,
      :mesorregiao => 3,
      :microrregiao => 4,
      :municipio => 5
   }
QUALIDADE = "&qualidade=2" # qualidade da resolucao das imagens geojson

# Constroi os parametros de requisicao para recuperar geojson de localizacoes.
# Exemplo:
#    - build_parametros_ibge_api_loc(es)
#    - build_parametros_ibge_api_loc(es,:absoluta, :municipio)
# Parameters:
# - tipo_res: :relativa ou :absoluta
def build_parametros_ibge_api_loc(localizacao, tipo_res=:absoluta, resolucao=:mesorregiao)
   res_num = RES_NUM_DEFAULT
   if resolucao.is_a? Symbol then
      res_num = TABELA_RESOLUCAO[resolucao]
      if res_num == nil then
         res_num = RES_NUM_DEFAULT
      end
   else
      res_num = RES_NUM_DEFAULT
   end

   if tipo_res == :relativa then
      if !resolucao.is_a? Numeric
         resolucao = 1
      end
      case localizacao.class
      when Municipio
         res_num = TABELA_RESOLUCAO[:municipio] + resolucao
      when Microrregiao
         res_num = TABELA_RESOLUCAO[:microrregiao] + resolucao
      when Mesorregiao
         res_num = TABELA_RESOLUCAO[:mesorregiao] + resolucao
      when Estado
         res_num = TABELA_RESOLUCAO[:estado] + resolucao
      when Macroregiao
         res_num = TABELA_RESOLUCAO[:macroregiao] + resolucao
      else
         res_num = TABELA_RESOLUCAO[:mesorregiao]
      end
   end

   return localizacao.id.to_s + "?resolucao=" + res_num.to_s + QUALIDADE

end



# Recupera o geojson da api do IBGE para uma localizacao, incluindo sublocalizacoes
# dependendo da resolucao pretendida.
# Exemplo: puts get_geojson(es,:absoluta, :municipio)
def get_geojson(localizacao, tipo_res=:absoluta, resolucao=:mesorregiao)

  uri = URI('http://' + HOST_IBGE_API_LOC + PATH_IBGE_API_LOC + build_parametros_ibge_api_loc(localizacao, tipo_res, resolucao))

  logger.info("get_geojson: " + uri.to_s)
	logger.info(get_cached_file(uri.to_s))

	req = Net::HTTP::Get.new(uri)
	req['Accept'] = "application/vnd.geo+json"

	logger.info(get_cached_file(uri.to_s))

	res = get_remote_resource(uri.to_s, request_parameters={"Accept" => "application/vnd.geo+json"}, logger=Rails.logger)

	if res[:http_response] == Net::HTTPOK then
	   return res[:body]
	else
		# deve retornar uma excecao!
		logger.error(res.class.to_s + " na carga de " + uri.to_s)
		return ""
	end
end
