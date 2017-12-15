# Requisitos e Interfaces a Implementar

Este texto documento os requisitos da implementação em termos de interfaces de pesquisa internas a serem implementadas.

## Responsabilidades

* **Interfaces de Pesquisa CEPESPData**: Luis
* **Interfaces de Pesquisa IBGE**: Gabriel
* **Consolidação de Dados de Resultado Eleitorais**: Dimas
* **Localização**: Ricardo
* **Interface com usuário**: Marco e Ricardo

## Interface com usuário, Consultas e Saídas da Aplicação

A interface com o usuário deve possui uma área para **analistas** e outra para **eleitores**. **Importante** que todos vejam essas funcionalidades pois o seus componentes, classes, devem permitir tais funcionalidades.

* **Responsáveis diretos**: Dimas, Marco e Ricardo

### Para analistas

Para todas as consultas abaixo, considerá-las sempre para **deputado federal** e **estadual**, pois são o cenário mais interessante do problema.
Para uma certa eleição (considerar ano)

1. Selecionado um município
   1. Votação de todos os candidatos
   2. Percentual de votação dos candidatos eleitos
   3. Considerando os candidatos eleitos, qual contribuição percentual na votação de um candidato em uma dada localização (município, microrregião, mesorregião ou estado)
   4. Dado qualquer candidato, qual percentual de contribuição de uma localização na sua votação total.
2. Computar os resultados dos candidatos em termos de média, permitindo indicar se o resultado de um candidato está acima ou abaixo da média, e considerando um candidato em particular como referência
   1. Permitir a ordenação dos candidatos e entre os eleitos, considerando os parâmetros informados.
3. Oferecer soluções estatísticas para exibir os dados de maneira simplificada e fácil - minimizar os dados e com valores próximos.
   * iniciar  gerando os dados. Utilizar gem <https://github.com/thirtysixthspan/descriptive_statistics>.
4. Permitir escolher um candidato em particular
5. Computar considerando votos para partidos
5. Computar considerando votos para legenda
6. Oferecer simulações: efeito individual, efeito fora da legenda, sem voto no partido.
7. Situar candidato no domicilio eleitoral
   1. Recuperar o domicílio eleitoral do candidato
   2. Calcular a distância do candidato para localização dos votos, centralidade (?), coeficiente gini-like do cepesp (segundo artigo ["A Concentração eleitoral nas eleições paulistas: medidas e aplicações"](http://www.scielo.br/scielo.php?pid=S0011-52582011000200004&script=sci_arttext)).
   3. Mostrar graficamente ou numericamente.
8. Procurar candidatos próximos e candidatos distantes (definir margem de pesquisa): resultados e desempenho próximo (em termos de valor total, proporcional, distribuiçao de votos para os diferentes tipos de localização), indicando efeito isolado, efeito legenda, partidos diferentes.
9. Indicar concorrentes em potencial, de acordo com o tipo de localização (geral, local, partido). Onde é a base? Onde fica maior percentual?
10. Diagrama de fluxo de votos entre uma eleição e outra.
   * Mostrar relação com as localidades vizinhas de uma eleição para outra (migração de votos), indicando graficamente aumento ou diminuição dos votos, e da posição de votação no local.
11. Identificar perfil do candidato em renda, situando na pirâmide.
   * Indicar como os votos se comportam em lugares com pessoas com perfil mais próximo e em cidades com perfil mais próximo do domicílio do candidato.

### Para eleitores

1. Recuperar a localização do eleitor ou permitir que ele indique a sua localização no mapa ou por pesquisa textual.
2. Recuperar para a localização indicada (maior - estado -ou menor amplitude - município), quem ele ajudou a eleger:
   * dado o voto no candidato `x`, quem ele ajudou a eleger, considerando candidatos em coligação.
   * quem a localização (municipio, micro, meso) ajudou a eleger.
3. Prover simulações:
   * Se eu tivesse votado em `y`, quem eu elegeria?

9. Gráfico com distribuição dos votos (percentual e total) por local, por população, de um ou mais candidatos.



## Consolidação de Dados de Resultados Eleitorais

Essas interfaces são responsabilidades do Dimas.

O resultado eleitoral de candidatos a deputado federal no estado de Goiás em 2014. Os resultados estão agregados por estado, quer dizer, é a votação total no estado.

Consulta:

		curl -i -g -X GET "http://cepesp.io/api/consulta/votos?ano=2014&cargo=6&agregacao_regional=2&selected_columns[]="DESCRICAO_CARGO"&selected_columns[]="NUMERO_CANDIDATO"&selected_columns[]="SIGLA_UE"&selected_columns[]="QTDE_VOTOS"&columns[0][name]="SIGLA_UE"&columns[0][search][value]="GO""

Você precisa:
1. Determinar como pode ser feito cálculo dos eleitos dados todos os candidatos, como no resultado da pesquisa. Procurar no TSE ou mesmo do CEPESPData se você consegue descobrir os candidatos eleitos, mas uma coisa não elimina a outra. Talvez você precise da mentoria do CEPESPData. Criar um código para fazer esse cálculo.
2. Determinar quais são votos brancos e nulos. Aparentemente são aqueles com número candidato 95 e 96.
3. Necessário saber quantos deputados são elegíveis por estado. Onde recuperar essa informação? Ver TSE.


## Interface de Pesquisa IBGE

Essas interfaces são responsabilidades do Gabriel. Iniciar com:

1. **habitantes**
2. **PIB per capita**
3. **IDH**.

### Consultas

1. Recuperar a lista dos indicadores, com seu identificador, os anos em que foram computados e suas unidades. Cada indicador deve estar armazenado em um objeto com (minimamente):
   + identificador
   + descrição do indicador (geralmente armazenado em nome e não em descricao).
   + unidade do indicador
2. Dado um `indicador`, `ano` e `cidade`, recuperar o valor do indicador.

Todas as informações devem ser armazenas em objetos para serem utilizados na solução. Crie uma classe genérica de indicador. Caso você tenha um exemplo, teste com um indicador com várias informações (tentei procurar/testar mas não consegui).

A idéia é que o código não fique engessado a um indicador em particular. Procure também parametrizar a URL de consultado dado.

*Investigação futura:
1. Como obter IDH por bairro? Eu vi que existe IDH por bairro, mas talvez seja apenas para bairros de regiões metropolitanas. Eu achei diversas menções na impressa e no IBGE mas não consegui obter na API. Você pode testar com o código 3304557081 que é do bairro Jararépaguá (Rio de Janeiro). Possíveis fontes: [atlas](http://www.atlasbrasil.org.br) e [ipea](http://www.ipeadata.gov.br/).

## Interfaces de Pesquisa CEPESPData

Essas interfaces são responsabilidades do Luis.

### Classes


```ruby
# Armazena dos dados de um candidato, indicando ano e local à que a candidatura
# se aplica. Não esquecer de indicar se a candidatura está válida, que deve ser
# facilmente utilizável para filtrar pesquisas e interações (exemplo: loop apenas
# por candidatos válidos)
class Candidado
end
```

```ruby
# Armazena os dados de uma legenda, indicando o contexto eleitoral em que ela se
# aplica. (talvez seja necessário criar uma classe ContextoEleitoral pois esse
# tipo de informação será útil em diversos cenários)
# Deve ser capaz de retornar os partidos que fazem parte da legenda.
class Legenda
end
```

```ruby
# Armazena um partido (nome, sigla, número)
class Partido
end
```

```ruby
# Classe `Votacao` armazena o conjunto de votos associado a um certo contexto
# (por exemplo, localização e ano), permitindo recuperar a votação por partido
# e os votos nulos e brancos quando se tratar de um conjunto de votos (e não
# um voto unitário de um candidato).
class Votacao
end
```

### Consultas

```ruby
# Pesquisa candidatos por `localização`, `ano`, `cargo`, `partido` e `número`,
# retornando o(s) candidato(s) que se adequem aos critérios pesquisados.
# Considere que os candidatos retornados devem indicar se a candidatura é válida
# ou não (atributo no próprio objeto).
#
# Cargo pode ser `:presidente`,  `:senador`,  `:deputado_federal` e assim por diante.
#
def pesquisa_candidatos(localizacao, ano, cargo, partido=nil, numero=nil)
end
```

```ruby
# Pesquisa votação por `localização`, `cargo`, `ano`, `numero` (do candidato),
# retornando um objeto `Votacao`, com os respectivos dados recuperados.  
def pesquisa_votacao(localizacao, cargo, ano, numero=nil)
end
```

```ruby
# Pesquisa legenda por localização, cargo e ano, retornado uma estrutura de dados
# que permita recuperar:
#
# - partidos por legenda
# - legenda por partido (método estático)
def pesquisa_legenda(localizacao, ano, cargo)
end
```
