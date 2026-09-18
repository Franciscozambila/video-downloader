# Fases do Projeto Video Downloader

## Objetivo do documento

Este documento define a sequência de evolução do projeto, preservando o motor
Python existente e evitando iniciar a aplicação mobile antes de a aplicação
web estar compreendida, testada e estabilizada.

O produto final pretendido é um aplicativo mobile, inicialmente para Android.
O projeto não deverá ser transformado numa aplicação web como objetivo final;
a web é a primeira fase de validação e estabilização do comportamento atual.

## Princípios para todas as fases

- Ler [`contextualizacao.md`](./contextualizacao.md) antes de qualquer
  alteração.
- Preservar funcionalidades existentes e fazer alterações incrementais.
- Não inventar plataformas, APIs ou comportamentos não confirmados.
- Não substituir o motor Python sem necessidade técnica comprovada.
- Separar responsabilidades entre interface, comunicação e motor de
  download.
- Verificar dependências antes de adicionar novas.
- Testar cada alteração no menor âmbito possível antes de avançar.
- Documentar o impacto de cada decisão arquitetural.
- Respeitar requisitos legais, políticas das plataformas e licenças das
  dependências.

---

# FASE 1 — WEB

## Objetivo

Garantir que a aplicação web atual funciona de forma previsível, corrigir
bugs diretamente relacionados ao funcionamento existente e estabelecer uma
base de testes para o motor Python e para as rotas FastAPI.

Esta fase não cria funcionalidades mobile nem altera a arquitetura existente.

## 1.1 Levantamento e preparação

- Confirmar o entrypoint `main:app`.
- Confirmar execução com o ambiente virtual do projeto.
- Confirmar configuração de host, porta e diretórios.
- Identificar dependências externas necessárias, incluindo eventual FFmpeg.
- Separar claramente problemas confirmados de melhorias futuras.
- Registar o comportamento atual antes de corrigir bugs.

## 1.2 Correções de bugs

Investigar e corrigir somente problemas reproduzíveis ou diretamente
relacionados às funcionalidades existentes, incluindo:

- erros de inicialização;
- erros de validação de URLs;
- falhas de extração de metadados;
- inconsistências entre formatos permitidos e formatos realmente baixáveis;
- erros na produção ou entrega dos ficheiros;
- problemas de streaming no player;
- falhas de pesquisa;
- problemas de CSRF, rate limit ou entrega segura de ficheiros;
- bloqueios indevidos do servidor durante operações longas;
- mensagens de erro incorretas ou pouco claras.

Não fazer refatorações amplas apenas por preferência de estilo.

## 1.3 Testes de downloads

Validar, com fontes e conteúdos permitidos:

- download de vídeo em MP4;
- download de áudio em MP3;
- seleção de qualidade;
- geração de nome de ficheiro;
- criação e utilização do diretório `downloads/`;
- thumbnail incorporada ou separada, quando aplicável;
- comportamento perante URL inválido;
- comportamento perante plataforma não suportada;
- comportamento quando a conversão ou o extractor falha;
- proteção contra traversal ao servir ficheiros.

Não assumir que a existência de uma entrada no detector garante que todos os
conteúdos dessa plataforma funcionam.

## 1.4 Testes de pesquisa e player

Validar:

- pesquisa no YouTube;
- paginação dos resultados;
- exibição de título, duração, thumbnail e autor;
- navegação para a página de download;
- obtenção de URL de streaming;
- reprodução de áudio no navegador;
- comportamento quando o stream expira ou não está disponível;
- retorno seguro ao utilizador em caso de erro.

## 1.5 Testes de API

Validar os endpoints existentes:

- `/api/multi/detect`;
- `/api/multi/metadata`;
- `/api/multi/download`;
- `/api/xvideos/metadata`;
- `/formats/{url}`;
- `/files/{filename}`.

Verificar contratos de entrada e saída, códigos HTTP, mensagens de erro,
limites de tamanho, rate limit e execução correta das operações bloqueantes.

Não criar uma API mobile dedicada nesta fase.

## 1.6 Testes de segurança

Verificar:

- allowlist de domínios;
- rejeição de esquemas inseguros;
- rejeição de credenciais e portas não permitidas;
- proteção contra path traversal;
- tokens CSRF nas rotas HTML;
- cabeçalhos HTTP de segurança;
- limites de requisições;
- tratamento de nomes de ficheiros controlados por conteúdo remoto;
- exposição acidental de ficheiros temporários.

Qualquer alteração de segurança deve preservar o fluxo legítimo da aplicação.

## 1.7 Critérios de conclusão da Fase 1

A Fase 1 estará concluída quando:

- a aplicação iniciar de forma reproduzível com o `venv` existente;
- a rota inicial e os recursos estáticos funcionarem;
- pesquisa, player, metadados e downloads forem testados;
- os endpoints existentes tiverem comportamento documentado;
- bugs reproduzíveis críticos estiverem corrigidos;
- falhas conhecidas estiverem registadas;
- não existirem alterações mobile misturadas nesta fase;
- houver uma forma repetível de executar os testes definidos.

## Fora do escopo da Fase 1

- Flutter ou Dart;
- telas mobile;
- banco de dados de biblioteca;
- playlists, favoritos e histórico;
- fila persistente;
- notificações Android;
- substituição do motor Python;
- mudança definitiva da arquitetura de execução.

---

# FASE 2 — ARQUITETURA MOBILE

## Objetivo

Definir, antes da implementação visual, como o futuro aplicativo Flutter/Dart
irá comunicar com o motor Python e como serão tratados tarefas, ficheiros,
metadados, progresso e ciclo de vida Android.

Esta fase produz decisões e contratos técnicos; não implementa a interface
final do aplicativo.

## 2.1 Decisões a analisar

Comparar explicitamente:

### Python local no dispositivo

**Vantagens:**

- potencial funcionamento sem servidor;
- menor dependência de rede;
- maior controlo sobre ficheiros locais.

**Impactos:**

- empacotamento de Python e dependências nativas;
- compatibilidade Android/arquiteturas;
- FFmpeg, permissões, bateria e armazenamento;
- execução em background;
- distribuição e manutenção mais complexas.

### Serviço Python separado com API

**Vantagens:**

- ambiente Python controlado;
- possibilidade de workers e filas;
- atualizações do motor independentes do aplicativo.

**Impactos:**

- dependência de internet;
- autenticação, privacidade e gestão de ficheiros;
- infraestrutura e custos;
- necessidade de proteger a API contra abuso.

### Arquitetura híbrida

**Vantagens:**

- combina processamento local e remoto;
- pode adaptar-se à capacidade do dispositivo e à conectividade.

**Impactos:**

- sincronização de estados;
- duplicação de responsabilidades;
- maior complexidade de testes e suporte.

Nenhuma opção deve ser escolhida definitivamente sem validar os requisitos
da Fase 1, licenciamento, distribuição e limitações técnicas do Android.

## 2.2 Contratos Flutter ↔ Python

Definir contratos estáveis para:

- deteção de plataforma;
- obtenção de metadados;
- listagem de formatos;
- criação de tarefa de download;
- consulta de estado;
- eventos de progresso;
- pausa;
- retomada;
- cancelamento;
- erro e retry;
- localização do ficheiro concluído;
- consulta de metadados da biblioteca.

Os contratos devem ser independentes dos widgets Flutter e não devem obrigar
o Flutter a importar módulos internos Python diretamente.

## 2.3 Modelo de tarefas

Definir estados e transições, por exemplo:

```text
queued → running → completed
             ├── paused → running
             ├── cancelled
             └── failed → queued
```

Definir também:

- identificador persistente;
- URL e fonte;
- formato e qualidade;
- progresso e velocidade;
- caminho temporário e caminho final;
- timestamps;
- erro estruturado;
- política de retomada.

## 2.4 Armazenamento mobile

Definir onde ficarão:

- ficheiros de vídeo;
- ficheiros de áudio;
- thumbnails;
- metadados;
- histórico;
- favoritos;
- playlists;
- ficheiros temporários.

Também devem ser definidas quotas, limpeza, migração, permissões e
comportamento quando o espaço for insuficiente.

## 2.5 Critérios de conclusão da Fase 2

A Fase 2 estará concluída quando:

- a opção de execução Python estiver justificada;
- os limites entre Flutter, comunicação e motor estiverem documentados;
- os contratos de integração estiverem definidos;
- o modelo de tarefas e erros estiver definido;
- a estratégia de armazenamento estiver definida;
- requisitos de background, notificações e permissões Android estiverem
  identificados;
- riscos, custos e dependências estiverem registados;
- existir um plano de protótipo antes da implementação completa.

## Fora do escopo da Fase 2

- construção de telas completas;
- redesign da aplicação web;
- substituição imediata do motor;
- implementação de todas as funcionalidades mobile;
- publicação na Play Store.

---

# FASE 3 — APP MOBILE

## Objetivo

Construir a interface Flutter/Dart, integrar o motor Python conforme a decisão
da Fase 2 e validar o aplicativo em Android sem remover o comportamento web
estabilizado.

## 3.1 Fundação do aplicativo

- criar a estrutura Flutter somente após aprovação da arquitetura;
- configurar navegação e gestão de estado;
- definir temas claro/escuro, se aprovado;
- suportar diferentes tamanhos de ecrã;
- criar modelos para conteúdos, tarefas e estados;
- implementar a camada de comunicação isolada;
- configurar tratamento consistente de erros e loading.

## 3.2 Downloads

Implementar progressivamente:

- introdução de URL;
- deteção de plataforma;
- consulta de metadados;
- escolha de formato e qualidade;
- criação de download;
- fila;
- progresso;
- pausa;
- retomada;
- cancelamento;
- retry;
- notificações;
- recuperação após reinício do aplicativo.

Cada funcionalidade deve ser integrada ao contrato definido na Fase 2.

## 3.3 Player

Implementar:

- player de vídeo;
- player de áudio;
- controlos de reprodução;
- avanço e retrocesso;
- velocidade;
- volume;
- reprodução em segundo plano quando suportada;
- retoma da posição;
- tratamento de ficheiro ausente ou corrompido.

O player deve utilizar ficheiros ou streams conforme a arquitetura aprovada,
sem depender de URLs temporárias de forma indevida.

## 3.4 Biblioteca

Implementar progressivamente:

```text
Biblioteca
├── Músicas
├── Vídeos
├── Downloads
├── Favoritos
├── Histórico
└── Playlists
```

Adicionar pesquisa, filtros, ordenação, edição de playlists e eliminação
segura apenas quando o modelo de armazenamento estiver preparado.

## 3.5 Testes Android

Testar:

- instalação e atualização;
- diferentes versões e tamanhos de ecrã;
- permissões;
- rede instável;
- execução em background;
- notificações;
- interrupção e retomada;
- pouco espaço;
- rotação e ciclo de vida;
- ficheiros grandes;
- reprodução offline;
- falhas do motor e da comunicação.

## 3.6 Critérios de conclusão da Fase 3

A Fase 3 estará concluída quando:

- o aplicativo Android executar o fluxo principal ponta a ponta;
- downloads, progresso e estados forem recuperáveis;
- áudio e vídeo puderem ser reproduzidos;
- a biblioteca offline estiver consistente;
- erros de comunicação forem apresentados de forma compreensível;
- testes em dispositivos/emuladores alvo forem concluídos;
- o motor Python existente continuar preservado;
- documentação de instalação, execução e suporte estiver atualizada.

---

# Ordem de execução resumida

```text
FASE 1 — WEB
    ↓
Estabilizar e testar o comportamento atual
    ↓
FASE 2 — ARQUITETURA MOBILE
    ↓
Definir fronteiras, contratos e execução Python
    ↓
FASE 3 — APP MOBILE
    ↓
Construir Flutter, integrar e testar Android
```

## Estado inicial deste roadmap

| Fase | Estado | Observação |
|---|---|---|
| Fase 1 — Web | Em preparação | A aplicação já executa; ainda é necessário validar sistematicamente todas as áreas. |
| Fase 2 — Arquitetura mobile | Não iniciada | Depende dos resultados da Fase 1. |
| Fase 3 — App mobile | Não iniciada | Depende das decisões e contratos da Fase 2. |
