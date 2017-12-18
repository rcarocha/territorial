# Projeto para o Desafio CEPESP

## Desafio

Detalhes do desafio est�o mantidos em: [desafio de implementa��o](http://www.inf.ufg.br/~ricardo/esaas/desafio/desafio-implementacao.html).

+ Nome da Equipe: ufcat
+ Participantes: Ricardo (líder), Gabriel, Luis, Marco Túlio (graduado), Dimas
+ Perfil da Equipe: professor e alunos de disciplina de graduação em Ciência da Computa��o, complementado com um graduado.
+ Descrição do projeto a desenvolver

   * A aplicação proverá pesquisas em resultados eleitorais baseadas em localização semântica estática (divisões administrativas) e dinâmica (territórios baseados em critérios sociais de acordo com o IBGE), e oferecerá um frontend composto de uma aplicação baseada em mapas que permitirá simulações e um backend que oferecerá as pesquisas utilizando uma API RESTful. Aplicação frontend ofererá ainda interface específica para eleitores, ajudando na avaliação do efeito do voto na eleição de fato e promovendo simulaçães. A solução integrará dados do IBGE, TSE (não incluídos no CEPESPData), bases de mapas abertas, além do pr�prio CEPESPData.

## Execução da Aplicação

### Requisitos

+ Ruby (acima de 2.2)
+ Rails (versão 5)
+ Executar o `bundle install` para instalar eventuais dependências.

### Cache de dados

A aplicação utiliza cache dinâmico em dois níveis. Para que não haja muitos problemas para testar a aplicação, sugere-se que se baixe um cache utilizado nos testes de desenvolvimento e disponível no arquivo http://goo.gl/ME8b5E (50Mb). O arquivo deve ser descompactado no diretório `rails/tmp` (é um arquivo tgz - TAR com GZIP).

A aplicação funciona mesmo sem esse cache.

### Execução

A aplicação encontra-se em modo de desenvolvimento. Para executá-la, deve-se digitar de dentro do diretório `rails`:

```
rails server
```

A aplicação ficará disponível em <http://localhost:3000/>, considerando que o acesso será feito na mesma máquina de execução da aplicação.

## Implementa��o proposta

* Ver documentação das [interfaces da aplicação](INTERFACES.md), que indica tanto aspectos da interface gr�fica como dos componentes internos.
* ver [documentação projeto implementação](docs/implementacao.md)

## Tarefas

+ **Gabriel**: interface com a API IBGE em <https://servicodados.ibge.gov.br/api/docs>
+ **Luis**: interface com a API REST do CEPESP.io em <https://github.com/Cepesp-Fgv/cepesp-rest>
+ **Ricardo**: projeto da solução e a API de consultas.
+ **Marco**: a definir
+ **Dimas**: a definir

