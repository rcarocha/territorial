# Projeto para o Desafio CEPESP

## Desafio

Detalhes do desafio estão mantidos em: [desafio de implementação](http://www.inf.ufg.br/~ricardo/esaas/desafio/desafio-implementacao.html). 

+ Nome da Equipe: ufcat
+ Participantes: Ricardo (líder), Gabriel, Luis, Marco Túlio (graduado), Dimas
+ Perfil da Equipe: professor e alunos de disciplina de graduação em Ciência da Computação, complementado com um graduado.
+ Descrição do projeto a desenvolver

   * A aplicação proverá pesquisas em resultados eleitorais baseadas em localização semântica estática (divisões administrativas) e dinâmica (territórios baseados em critérios sociais de acordo com o IBGE), e oferecerá um frontend composto de uma aplicação baseada em mapas que permitirá simulações e um backend que oferecerá as pesquisas utilizando uma API RESTful. Aplicação frontend ofererá ainda interface específica para eleitores, ajudando na avaliação do efeito do voto na eleição de fato e promovendo simulações. A solução integrará dados do IBGE, TSE (não incluídos no CEPESPData), bases de mapas abertas, além do próprio CEPESPData.

## Implementação proposta

* Ver documentação das [interfaces da aplicação](INTERFACES.md), que indica tanto aspectos da interface gráfica como dos componentes internos.
* ver [documentação projeto implementação](docs/implementacao.md)

## Ferramentas

+ Ruby: utilizar versão **acima da versão 2.3**, preferencialmente. **Não** utilizar Ruby em versões menores que 2.0.

+ Slack: comunicação entre os participantes
+ Issue tracker: registro de problemas no próprio gitlab, ao menos por enquanto
+ Controle de versão: no gitlab (**não compartilhar em outro local**!)

## Tarefas

+ **Gabriel**: interface com a API IBGE em <https://servicodados.ibge.gov.br/api/docs>
+ **Luis**: interface com a API REST do CEPESP.io em <https://github.com/Cepesp-Fgv/cepesp-rest>
+ **Ricardo**: projeto da solução e a API de consultas.
+ **Marco**: a definir
+ **Dimas**: a definir

## Manuais que podem ajudar

* Escrita de documentos em markdown no Gitlab (como este documento): <https://gitlab.com/help/user/markdown.md>
* Uso do Git <https://gitlab.com/help#git-and-gitlab>
