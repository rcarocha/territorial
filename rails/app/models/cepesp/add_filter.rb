=begin
 Adiciona um filtro a uma requisição, permitindo obter apenas os dados que
  interessam a uma dada consulta.
 Não havia documentação a esse respeito na API CEPESP. A função
`adiciona_filtro` retorna uma string a ser acrescida à URI da consulta para
 filtrar os campos desejados.

 Exemplo de consulta de votação por REST usando filtro para recuperar apenas
 os votos pelo estado do ES

curl -i -g -X GET "http://cepesp.io/api/consulta/votos?ano=2014&cargo=1&agregacao_regional=2&selected_columns[]="NUM_TURNO"&selected_columns[]="NOME_MACRO"&selected_columns[]="DESCRICAO_CARGO"&selected_columns[]="QTDE_VOTOS"&selected_columns[]="UF"&columns[0][name]="UF"&columns[0][search][value]="ES""

 Exemplo de uso:

 puts adiciona_filtro("ES")
 puts adiciona_filtro("ES", "13222")
 puts adiciona_filtro("ES", "13222", "13")
 puts adiciona_filtro("ES", "13222", "13", "112144456778899")
=end

def adiciona_filtro(titulo=nil,
               estado=nil,
               numero_candidato=nil,
               numero_partido=nil,
               codigo_municipio=nil
               )
   prefixo_requisicao = ""
	index = 0
   if estado then
      # prefixo_requisicao << "&columns[" + index.to_s + "][name]=\"" + "UF\"&columns[" + index.to_s + "][search][value]=\"" + estado + "\""
      prefixo_requisicao << novo_filtro(index, "UF", estado)
      index = index + 1
   end
   if numero_candidato then
      # prefixo_requisicao << "&columns[" + index.to_s + "][name]=\"" + "UF\"&columns[" + index.to_s + "][search][value]=\"" + estado + "\""
      prefixo_requisicao << novo_filtro(index, "NUMERO_CANDIDATO", numero_candidato)
      index = index + 1
   end
   if numero_partido then
      # prefixo_requisicao << "&columns[" + index.to_s + "][name]=\"" + "UF\"&columns[" + index.to_s + "][search][value]=\"" + estado + "\""
      prefixo_requisicao << novo_filtro(index, "NUMERO_PARTIDO", numero_partido)
      index = index + 1
   end
   if codigo_municipio then
      # prefixo_requisicao << "&columns[" + index.to_s + "][name]=\"" + "UF\"&columns[" + index.to_s + "][search][value]=\"" + estado + "\""
      prefixo_requisicao << novo_filtro(index, "CODIGO_MUNICIPIO", codigo_municipio)
      index = index + 1
   end
   if titulo then
      # prefixo_requisicao << "&columns[" + index.to_s + "][name]=\"" + "UF\"&columns[" + index.to_s + "][search][value]=\"" + estado + "\""
      prefixo_requisicao << novo_filtro(index, "NUM_TITULO_ELEITORAL_CANDIDATO", titulo)
      index = index + 1
   end
   return prefixo_requisicao
end

def adiciona_filtro_livre(filtros, valores)
   f = ""
   ind = 0
   if filtros then
      filtros.each do |id_filtro|
         f += novo_filtro(ind, id_filtro, valores[ind])
         ind = ind + 1
      end
   end
   return f
end

def novo_filtro(indice, nome_coluna, valor)
   return "&columns[" + indice.to_s + "][name]=" + nome_coluna + "&columns[" + indice.to_s + "][search][value]=" + valor + ""
end
