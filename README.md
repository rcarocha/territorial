# Projeto para o Desafio CEPESP

## Desafio

Detalhes do desafio est�o mantidos em: [desafio de implementa��o](http://www.inf.ufg.br/~ricardo/esaas/desafio/desafio-implementacao.html). 

+ Nome da Equipe: ufcat
+ Participantes: Ricardo (l�der), Gabriel, Luis, Marco T�lio (graduado), Dimas
+ Perfil da Equipe: professor e alunos de disciplina de gradua��o em Ci�ncia da Computa��o, complementado com um graduado.
+ Descri��o do projeto a desenvolver

   * A aplica��o prover� pesquisas em resultados eleitorais baseadas em localiza��o sem�ntica est�tica (divis�es administrativas) e din�mica (territ�rios baseados em crit�rios sociais de acordo com o IBGE), e oferecer� um frontend composto de uma aplica��o baseada em mapas que permitir� simula��es e um backend que oferecer� as pesquisas utilizando uma API RESTful. Aplica��o frontend oferer� ainda interface espec�fica para eleitores, ajudando na avalia��o do efeito do voto na elei��o de fato e promovendo simula��es. A solu��o integrar� dados do IBGE, TSE (n�o inclu�dos no CEPESPData), bases de mapas abertas, al�m do pr�prio CEPESPData.

## Implementa��o proposta

* Ver documenta��o das [interfaces da aplica��o](INTERFACES.md), que indica tanto aspectos da interface gr�fica como dos componentes internos.
* ver [documenta��o projeto implementa��o](docs/implementacao.md)

## Ferramentas

+ Ruby: utilizar vers�o **acima da vers�o 2.3**, preferencialmente. **N�o** utilizar Ruby em vers�es menores que 2.0.

+ Slack: comunica��o entre os participantes
+ Issue tracker: registro de problemas no pr�prio gitlab, ao menos por enquanto
+ Controle de vers�o: no gitlab (**n�o compartilhar em outro local**!)

## Tarefas

+ **Gabriel**: interface com a API IBGE em <https://servicodados.ibge.gov.br/api/docs>
+ **Luis**: interface com a API REST do CEPESP.io em <https://github.com/Cepesp-Fgv/cepesp-rest>
+ **Ricardo**: projeto da solu��o e a API de consultas.
+ **Marco**: a definir
+ **Dimas**: a definir

## Manuais que podem ajudar

* Escrita de documentos em markdown no Gitlab (como este documento): <https://gitlab.com/help/user/markdown.md>
* Uso do Git <https://gitlab.com/help#git-and-gitlab>
