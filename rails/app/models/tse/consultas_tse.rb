require 'open-uri'
require 'logger'
require 'json'

# Repositorio original: http://www.tse.jus.br/eleitor-e-eleicoes/estatisticas/repositorio-de-dados-eleitorais-1/repositorio-de-dados-eleitorais
# Repositorio alternativo: http://dados.gov.br/dataset?tags=TSE
# Exemplo: http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_vagas/consulta_vagas_2014.zip
REPOSITORIO = {
   "tse/vagas" =>
   ["TSE", "Vagas em Eleicao", "http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_vagas/consulta_vagas_2014.zip"]
}

file = File.read("#{Rails.root}/app/assets/data/vagas.json")
$vagas = JSON.parse(file)

# Retorna o numero de vagas para um certo cargo na eleicao de um local.
#
# Exemplo de uso:
# require './brasil_symb_location.rb' #=> necessario para carregar localizacoes
#
# sp = Estado.estados[20]
# vagas = get_vagas_eleicao("2014", :deputado_federal, sp) #=> deve retornar 70
#
def get_vagas_eleicao(ano, cargo, localizacao)
   return $vagas[ano.to_s][localizacao.nome][cargo.to_s].to_i
end


# issue: codigo realiza efetivamente um HTTP obtendo a resposta. Trocar para metodo head, usando net/http
def status_open_url(url)
   open(url) do |f|
      return f.status
   end
end

# Parameters
# - nome: um identificador para o repositorio. Exemplo: IBGE
# - descricao_dados: uma descricao dos dados que serao recuperados no repositorio, para dar uma ideia do efeito da indisponibilidade
# - url_teste: url de acesso aos dados para testar.
def testa_repositorio(nome, descricao_dados, url_teste)
   id_repositorio = nome + "(" + descricao_dados + ")"
   status = nil
   begin
      status = status_open_url(url_teste)
   rescue
      logger.error("Falha no acesso a repositorio " + id_repositorio + ":" + url_teste)
      return nil
   end
   status_ori = status
   if !(status[0] == "200") then
      logger.error("Falha no acesso a repositorio " + id_repositorio + ":" + status[0] + ":" + url_teste)
      http_method = /^http:\/\/(.)+$/
      https_method = /^http:\/\/(.)+$/
      if url_teste =~ http_method then
         status = status_open_url("https" + url_teste[4..-1])
         if !status[0] == "200" then
            logger.error("Falha no acesso HTTPS a repositorio " + id_repositorio + ":"  + status[0] + ":" + url_teste)
         else
            logger.error("OK no acesso HTTPS a repositorio " + id_repositorio + ":" + url_teste)
         end
      else
         if url_test =~ https_method then
            status = status_open_url("http" + url_teste[5..-1])
            if !status[0] = "200" then
               logger.error("Falha no acesso HTTP a repositorio " + id_repositorio + ":"  + status[0] + ":" + url_teste)
            else
               logger.error("OK no acesso HTTP a repositorio " + id_repositorio + ":" + url_teste)
            end
         else
            logger.error("Erro no protocolo (nao HTTP ou HTTPS) de acesso repositorio " + id_repositorio + ":" + url_teste)
         end
      end

   end
   return status_ori
end

# jlkjkj
#u = "http:/\/agencia.tse.jus.br\/"
#puts testa_repositorio("TSE", "consulta vagas", "http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_vagas/consulta_vagas_2014.zip").to_s
