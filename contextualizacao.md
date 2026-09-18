# Contextualização do Projeto Video Downloader

> Documento elaborado a partir da inspeção dos ficheiros existentes em 17/09/2026.
> As afirmações abaixo distinguem o que foi confirmado no código, o que está
> apenas mencionado em documentação e o que é recomendação futura.

## 1. Visão geral

O projeto é uma aplicação Python chamada `Video Downloader`, exposta
principalmente como uma aplicação web FastAPI. A interface renderiza páginas
HTML com Jinja2 e permite pesquisar conteúdos no YouTube, obter metadados,
reproduzir um stream de áudio e descarregar vídeo ou áudio através do
`yt-dlp`.

Existe também uma camada multi-plataforma recente, com detecção de domínios,
extração de metadados e download via API JSON. Essa camada é separada do
downloader original para preservar o comportamento das rotas existentes.

O código encontrado não é ainda uma aplicação mobile nativa, não contém
Flutter/Dart e não implementa uma biblioteca offline, playlists, favoritos,
histórico ou fila persistente.

## 2. Objetivo atual

O objetivo confirmado no código é disponibilizar uma aplicação chamada
StreamDown/Video Downloader para:

- pesquisar vídeos no YouTube;
- obter informações e formatos de um URL;
- descarregar vídeo em MP4;
- extrair áudio em MP3;
- obter URLs de streaming para reprodução no navegador;
- consultar metadados de vídeos do XVideos;
- descarregar conteúdos de uma lista de plataformas através da camada
  multi-plataforma.

O `main.py` declara explicitamente uma aplicação web para baixar vídeos e
áudio usando `yt-dlp`. O conteúdo de `README.md` e `xvideos_info.md` não
descreve fielmente esta aplicação: ambos contêm uma cópia/renderização do
README do pacote externo `unofficial-api-for-xvideos`. Portanto, as
funcionalidades desses documentos não foram consideradas implementadas neste
projeto sem confirmação no código.

## 3. Objetivo futuro

O projeto deverá evoluir para um **aplicativo mobile**, inicialmente com foco
em Android, mantendo o motor Python reutilizável quando isso for tecnicamente
viável.

O objetivo futuro **não é transformar o projeto num sistema web**. A
interface final deverá ser mobile-first; a aplicação web atual é apenas o
estado presente e uma possível superfície temporária de integração.

## 4. Estrutura atual

Árvore relevante observada:

```text
video-downloader/
├── app/
│   ├── api/
│   │   ├── routes.py
│   │   └── multi_routes.py
│   ├── core/
│   │   ├── downloader.py
│   │   ├── multi_downloader.py
│   │   └── platform_detector.py
│   ├── security/
│   │   ├── csrf.py
│   │   ├── headers.py
│   │   ├── rate_limit.py
│   │   └── validators.py
│   ├── static/
│   │   ├── icons/
│   │   ├── manifest.webmanifest
│   │   └── sw.js
│   └── templates/
│       ├── about.html
│       ├── base.html
│       ├── download_page.html
│       ├── download_result.html
│       ├── index.html
│       ├── player.html
│       └── search.html
├── downloads/
├── main.py
├── README.md
├── requirements.txt
├── venv/
└── xvideos_info.md
```

Também existem `__pycache__`, um `.env` sem chaves legíveis identificadas,
um ZIP do projeto e ficheiros de estado gerados pelo `yt-dlp` no diretório
`downloads/`. A `venv` é ambiente local e não faz parte da lógica da aplicação.

- `main.py`: cria a instância FastAPI, configura middleware, ficheiros
  estáticos e inclui as duas coleções de rotas.
- `app/api/routes.py`: rotas HTML, pesquisa YouTube, metadados XVideos,
  streaming, download legado e entrega de ficheiros.
- `app/api/multi_routes.py`: endpoints JSON para detectar plataforma,
  obter metadados e descarregar conteúdo.
- `app/core/downloader.py`: downloader original baseado em `yt-dlp`,
  pesquisa, metadados, streaming e thumbnails.
- `app/core/platform_detector.py`: allowlist de domínios, plataformas e
  formatos permitidos.
- `app/core/multi_downloader.py`: operações multi-plataforma usando
  `yt-dlp`, incluindo seleção de qualidade e conversão para MP3.
- `app/security/`: validação de URL, CSRF, cabeçalhos de segurança e
  rate limit em memória.
- `app/templates` e `app/static`: interface web/PWA e seus recursos.
- `downloads/`: armazenamento local dos resultados e ficheiros temporários.

## 5. Stack atual

Confirmado em `requirements.txt`:

- Python (o ambiente local foi criado com Python 3.14.6);
- FastAPI `>=0.110.0`;
- Uvicorn `[standard] >=0.29.0`;
- yt-dlp `>=2024.3.10`;
- Jinja2 `>=3.1.3`;
- Typer `>=0.12.3`;
- python-dotenv `>=1.0.1`;
- python-multipart `>=0.0.9`;
- unofficial-api-for-xvideos `>=2.5`.

Versões observadas no ambiente local, sem alterar ou instalar dependências:
FastAPI 0.141.1, Uvicorn 0.52.4, yt-dlp 2026.8.19, Jinja2 3.1.6,
Typer 0.27.2, python-dotenv 1.2.3, python-multipart 0.0.32 e
unofficial-api-for-xvideos 2.5. Estas versões não estão fixadas no
`requirements.txt`.

Frameworks e ferramentas identificados:

- FastAPI/Starlette para HTTP;
- Uvicorn para execução ASGI;
- Jinja2 para templates;
- `yt-dlp` para extração e download;
- Pydantic (usado indiretamente e nos modelos das rotas);
- `typer` está listado, mas não há CLI funcional identificada no `app/cli.py`,
  que está vazio;
- não há dependência de Flutter, Dart, banco de dados ou ORM.

O `ffmpeg` não aparece em `requirements.txt`. A conversão/merge de áudio e
vídeo depende do pós-processamento do `yt-dlp` e, portanto, pode exigir
binários externos, mas a presença deles não foi confirmada no projeto.

## 6. Arquitetura atual

A arquitetura confirmada é monolítica e web:

1. `main.py` cria a aplicação FastAPI.
2. `routes.py` fornece páginas HTML e endpoints de compatibilidade.
3. `multi_routes.py` fornece endpoints JSON multi-plataforma.
4. As rotas chamam funções síncronas em `app/core`.
5. `yt-dlp` extrai informação ou executa o download.
6. O resultado é gravado em `downloads/`.
7. A aplicação devolve HTML, JSON, um stream URL ou `FileResponse`.

Não existe uma camada de serviço persistente, gestor de tarefas, base de
dados, modelo de domínio ou fila de downloads. Os downloads são operações
bloqueantes; as rotas multi-plataforma usam `asyncio.to_thread`, enquanto
várias rotas legadas chamam funções síncronas diretamente dentro de handlers
assíncronos.

## 7. Fluxo atual

Fluxo web confirmado:

```text
Utilizador
    ↓
Página FastAPI/Jinja2 ou endpoint JSON
    ↓
Validação de URL, CSRF e rate limit (quando aplicável)
    ↓
Extractor yt-dlp ou cliente específico do XVideos
    ↓
Seleção de formato/qualidade
    ↓
Download e pós-processamento yt-dlp
    ↓
Ficheiro em downloads/
    ↓
FileResponse, resposta HTML ou download JSON
```

Na pesquisa, `search_youtube` usa `ytsearchN:<consulta>`; os resultados
levam ao player ou à página de download. No player, `get_stream_url`
seleciona uma URL remota direta, sem criar necessariamente um ficheiro local.

## 8. Sistema de download

### URLs e validação

O fluxo legado aceita explicitamente hosts do YouTube e URLs de vídeos do
XVideos. O fluxo multi-plataforma usa uma allowlist independente e rejeita
esquemas que não sejam HTTP/HTTPS, credenciais embutidas e portas explícitas.

### Extração de informações

`get_video_info` chama `yt_dlp.YoutubeDL(...).extract_info(...,
download=False)` e devolve ID, título, duração, thumbnail, autor,
visualizações e uma lista de formatos com codecs, extensão, resolução e
tamanho.

Para XVideos, `routes.py` usa `unofficial-api-for-xvideos.Client` de forma
assíncrona para devolver metadados adicionais. O mesmo URL pode também ser
processado pelo `yt-dlp` no download.

### Seleção e produção

O downloader original:

- usa nomes `%(title).150s [%(id)s].%(ext)s`;
- limita a um item (`noplaylist=True`);
- escolhe `bestvideo+bestaudio/best` ou limites de altura de 1080p, 720p,
  480p e 360p;
- extrai áudio com `FFmpegExtractAudio`, preferindo MP3;
- pode escrever e tentar incorporar thumbnail no MP3;
- pode guardar uma thumbnail separadamente.

O downloader multi-plataforma:

- permite `mp4` ou `mp3` conforme a política da plataforma;
- limita vídeos por altura máxima;
- prefere MP4 com vídeo e M4A com áudio, com fallback para `best`;
- converte áudio para MP3 com qualidade 128, 192, 320 ou a predefinida de
  192 para `best`;
- confirma que o ficheiro final existe dentro do diretório permitido antes
  de o devolver pela API.

Não há implementação própria de pausa, retoma, progresso, fila, cancelamento
ou persistência de estados de download.

## 9. Plataformas/fontes suportadas

### Confirmado no código de deteção multi-plataforma

`platform_detector.py` lista os seguintes hosts e políticas:

- YouTube (`youtube.com`, `youtu.be` e variantes);
- Facebook (`facebook.com`, `fb.watch`);
- Instagram;
- TikTok;
- Twitter/X;
- Vimeo;
- SoundCloud;
- Dailymotion;
- Twitch;
- Reddit;
- Pinterest;
- XVideos.

Essa lista confirma que os URLs são reconhecidos e encaminhados para
`yt-dlp`; não constitui garantia de que cada extractor funcione para todos
os conteúdos, regiões, contas ou formatos.

### Confirmado nos fluxos web específicos

- pesquisa: YouTube;
- metadados específicos: XVideos;
- download legado com validação: YouTube e XVideos;
- endpoint multi-plataforma: as doze plataformas acima, sujeito ao suporte
  efetivo do `yt-dlp`.

Não foi encontrado código de testes de integração que confirme cada fonte.

## 10. Formatos

Confirmado pelas validações e opções:

- vídeo: MP4;
- áudio: MP3;
- streams: a extensão original devolvida pelo extractor pode ser M4A,
  WEBM ou outra, embora o download final normalizado seja MP4/MP3 quando
  aplicável;
- thumbnails observadas: JPG e WEBP;
- ficheiros temporários observados: `.part`, `.ytdl` e fragmentos `.part-FragN`.

O sistema não define formatos móveis específicos, codecs garantidos para
Android ou uma política de compatibilidade de reprodução.

## 11. Armazenamento

`DEFAULT_DOWNLOAD_DIR` é a pasta `downloads/` na raiz do projeto. Ela é
criada automaticamente quando necessário. Os nomes usam título truncado e
ID da fonte. As rotas `/files/{filename}` e a API multi-plataforma servem
ficheiros dessa pasta após verificação de que o caminho resolvido permanece
dentro dela.

Não existe catálogo de ficheiros, banco de dados, identificador de tarefa,
metadados persistentes, diretórios por utilizador ou política de limpeza.
Os ficheiros existentes indicam que downloads concluídos, thumbnails e
temporários coexistem na mesma pasta.

## 12. Dependências

`fastapi`, `uvicorn` e `starlette` formam a camada HTTP/ASGI; `jinja2`
renderiza a interface; `python-multipart` permite receber formulários;
`yt-dlp` faz a pesquisa, extração, streaming e download; `unofficial-api-
for-xvideos` fornece o cliente específico do XVideos; `typer` está listado
mas não está ligado a uma CLI identificada; `python-dotenv` está listado,
mas não foi encontrada leitura de variáveis através dele no código
analisado.

Não foi confirmada dependência direta de FFmpeg, SQLite, Redis, Celery,
Docker ou qualquer SDK mobile.

## 13. Pontos reutilizáveis

As partes com maior potencial de reutilização futura são:

- `app/core/downloader.py`: extração, consulta de formatos, download de
  vídeo/áudio e obtenção de stream;
- `app/core/multi_downloader.py`: contrato de metadados, políticas de
  formato/qualidade e allowlist de downloads;
- `app/core/platform_detector.py`: normalização, deteção e validação de
  fontes;
- `download_thumbnail` e as regras de nome de ficheiro;
- tratamento de erros específico de XVideos em `routes.py`;
- a separação já existente entre o downloader legado e o multi-plataforma.

Para uso mobile, essas funções devem futuramente ser envolvidas por uma
camada de serviço com tarefas, progresso, cancelamento e armazenamento
controlado, sem acoplar o núcleo a widgets ou a Flutter.

## 14. Limitações

- operações potencialmente longas ainda são síncronas em parte das rotas;
- não existe progresso real exposto ao cliente;
- não existem pausa, retomada, cancelamento ou fila;
- URLs de stream podem expirar e dependem da disponibilidade da fonte;
- conversão/merge pode exigir FFmpeg externo não declarado;
- não há persistência, contas, biblioteca, histórico ou favoritos;
- rate limit é local ao processo e perde o estado ao reiniciar;
- não há autenticação/autorização de utilizadores;
- não há testes automatizados identificados;
- versões de dependências não estão fixadas;
- `README.md` e `xvideos_info.md` são documentação externa/incongruente;
- suporte multi-plataforma é uma política de encaminhamento, não uma prova de
  compatibilidade de todos os conteúdos;
- execução Android local, permissões e ciclo de vida em background não foram
  implementados.

## 15. Dívida técnica

### Arquitetura e manutenção

Há duas implementações parcialmente sobrepostas (`downloader.py` e
`multi_downloader.py`) e duas estratégias de validação de URLs. Qualidade,
formato e política de plataforma são duplicados entre backend e JavaScript.
As rotas HTML e JSON usam contratos diferentes. O módulo `cli.py` existe mas
está vazio.

### Segurança

Existem allowlists, proteção contra traversal nos ficheiros, CSRF para
formulários, cabeçalhos de segurança e rate limit. Contudo, o rate limit é
em memória, a configuração de `TrustedHostMiddleware` usa `*` por omissão,
não há autenticação e o processamento de URLs remotos continua dependente de
extractors de terceiros. A CSP permite scripts inline e a política completa
de produção não foi estabelecida.

### Desempenho e escalabilidade

Não há fila ou worker dedicado. `yt-dlp`, conversão, pesquisa e algumas
extrações podem bloquear o event loop. Não há cache própria, limites de
armazenamento, quotas, limpeza, métricas ou coordenação entre processos.

### Documentação e dependências

As duas documentações Markdown locais parecem pertencer ao projeto externo
`unofficial-api-for-xvideos`. O manifesto PWA e a interface responsiva não
equivalem a um aplicativo Android. Dependências e versão de Python variam
entre o manifesto e o ambiente local.

## 16. Código crítico

Não deve ser removido ou substituído sem necessidade:

- `app/core/downloader.py`, especialmente `get_video_info`,
  `download_video`, `get_stream_url` e `download_thumbnail`;
- `app/core/multi_downloader.py`, especialmente a validação de formatos e o
  pós-processamento;
- `app/core/platform_detector.py`, incluindo a allowlist;
- contratos de resposta das rotas já consumidas pela interface;
- validações em `app/security/validators.py`;
- proteção de caminhos em `/files/{filename}` e em
  `app/api/multi_routes.py`;
- middleware de cabeçalhos, CSRF e rate limit, salvo substituição
  equivalente justificada.

## 17. Evolução para mobile

### Arquitetura atual versus proposta

**Atual:** navegador → FastAPI/Jinja2 → funções Python → `yt-dlp` →
`downloads/`.

**Proposta de referência, ainda não implementada:**

```text
Android/Flutter
    │
    ▼
Camada de comunicação e contratos
    │
    ▼
Motor Python isolado
    ├── Extractor
    ├── Downloader
    ├── Audio Processor
    ├── Video Processor
    └── Metadata
    │
    ▼
Gestor de tarefas + armazenamento mobile + eventos de progresso
```

Essa arquitetura é apenas uma direção técnica. Não deve ser tratada como
existente nem implementada nesta etapa.

### Possibilidades para executar Python

1. **Local no dispositivo:** reduz dependência de servidor e favorece uso
   offline, mas exige empacotar Python, `yt-dlp`, possíveis binários nativos,
   permissões, consumo de bateria, armazenamento e integração Android.
2. **Serviço separado/API:** mantém o motor num ambiente Python controlado e
   facilita workers, filas e atualizações, mas exige conectividade, gestão de
   ficheiros, autenticação, privacidade e infraestrutura.
3. **Arquitetura híbrida:** tarefas simples e catálogo podem ser locais,
   enquanto downloads difíceis ou conversões ficam num serviço; oferece
   flexibilidade, mas aumenta a complexidade de sincronização.

Ainda não deve ser escolhida uma opção definitiva. A decisão deve considerar
licenciamento, distribuição Android, requisitos de FFmpeg, privacidade,
custos, conectividade e regras das fontes.

## 18. Futuro aplicativo mobile

O produto futuro poderá incluir os seguintes módulos, que **não estão
implementados atualmente**:

### Downloads

Download de vídeo/áudio, qualidade e formato, fila, progresso, pausa,
retomada, cancelamento e notificações. Será necessário um identificador
persistente por tarefa, estados (`queued`, `running`, `paused`, `failed`,
`completed`), eventos de progresso e recuperação após reinício.

### Player

Player de vídeo e música, reprodução em segundo plano, volume,
avanço/retrocesso, velocidade e retoma da posição. O player deve consumir
ficheiros locais estáveis, não depender diretamente de URLs temporárias.

### Biblioteca

```text
Biblioteca
├── Músicas
├── Vídeos
├── Downloads
├── Favoritos
├── Histórico
└── Playlists
```

Será necessária uma camada de metadados persistente que relacione conteúdo,
ficheiro, thumbnail, origem, duração, formato, estado e preferências.

### Interface

A futura interface deve ser mobile-first, moderna, simples, rápida,
responsiva, adequada para Android e preparada para vários tamanhos de
ecrã. Tema claro/escuro pode ser adicionado se for viável. A interface web
atual não deve ser confundida com a implementação dessa interface.

## 19. Tecnologia mobile

Flutter/Dart é uma opção considerada para a interface futura, mas nenhum
código Flutter está presente. A integração deve usar contratos estáveis,
por exemplo:

- pedido de deteção/metadados;
- criação de tarefa de download;
- consulta/stream de eventos de progresso;
- pausa, retoma e cancelamento;
- acesso a metadados da biblioteca;
- localização segura do ficheiro final.

Esses contratos são propostas e não APIs existentes. A camada Flutter não
deve importar diretamente módulos Python; deve comunicar por uma fronteira
explícita, seja bridge local, subprocesso controlado ou API, conforme a
decisão arquitetural futura.

## 20. Regras para futuras IAs

- Ler `contextualizacao.md` antes de modificar o projeto.
- Não assumir funcionalidades que não existem.
- Não inventar plataformas suportadas.
- Não inventar APIs.
- Não apagar funcionalidades existentes sem autorização.
- Não substituir o motor Python sem necessidade.
- Preservar código funcional.
- Fazer alterações incrementais.
- Verificar dependências antes de adicionar novas.
- Explicar o impacto das alterações.
- Não criar arquitetura completamente diferente sem justificativa.
- Priorizar reutilização do código existente.
- Não transformar o projeto numa aplicação web.
- O produto final é um aplicativo mobile.
- A interface mobile e o motor de download devem possuir responsabilidades
  bem separadas.
- Evitar acoplamento desnecessário entre Flutter e Python.
- O código existente deve ser tratado como património do projeto.
- Nenhuma funcionalidade existente deve ser removida simplesmente para
  facilitar uma implementação nova.

## 21. Estado atual

| Componente | Estado | Observação |
|---|---|---|
| Download de vídeo | Implementado/Parcial | Implementado via `yt-dlp`, com MP4 e qualidades limitadas; depende da fonte e do pós-processamento. |
| Download de áudio | Implementado/Parcial | MP3 via `FFmpegExtractAudio`; FFmpeg não foi confirmado no projeto. |
| Extração de informações | Implementado | Metadados e formatos via `yt-dlp`; XVideos também possui cliente específico. |
| Conversão | Implementado/Parcial | Configurada conversão para MP3 e merge para MP4; ferramenta externa não confirmada. |
| Armazenamento | Implementado | Diretório local `downloads/`, sem catálogo ou gestão de biblioteca. |
| Pesquisa | Implementado | Pesquisa YouTube via `ytsearch` do `yt-dlp`. |
| Streaming | Implementado/Parcial | URL direta para player web; não é player mobile nem armazenamento offline. |
| Deteção de plataformas | Implementado | Allowlist de doze plataformas no módulo multi-plataforma. |
| API JSON multi-plataforma | Implementado/Parcial | Deteção, metadados e download; não há tarefas assíncronas persistentes. |
| Player de vídeo | Não identificado no código analisado | Existe player HTML para áudio; não foi confirmado player de vídeo dedicado. |
| Player de música | Parcial | Página HTML usa elemento `<audio>` e stream remoto. |
| Biblioteca offline | Não implementado | Não há catálogo, filtros ou organização persistente. |
| Playlists | Não implementado | Não há modelo ou rotas de playlists. |
| Favoritos | Não implementado | Não há armazenamento de favoritos. |
| Histórico | Não implementado | Não há registo de histórico. |
| Fila de downloads | Não implementado | Cada pedido executa uma operação isolada. |
| Progresso | Não implementado | Não há callback/evento exposto ao cliente. |
| Pausa e retomada | Não implementado | Existem ficheiros temporários do `yt-dlp`, mas não há controlo de aplicação confirmado. |
| Cancelamento | Não implementado | Não há endpoint nem gestor de tarefas. |
| Notificações | Não implementado | Não há integração Android ou notificações web de download. |
| Aplicativo mobile | Não implementado | Nenhum código mobile encontrado. |
| Flutter/Dart | Não implementado | Nenhum ficheiro Flutter/Dart encontrado. |
| API para Flutter | Não implementado | Há endpoints FastAPI, mas não um contrato mobile dedicado. |
| Execução local Android | Não identificado no código analisado | O ambiente local é Linux; não há empacotamento Android. |

## 22. Precisão e informações não confirmadas

Foram considerados confirmados apenas comportamentos presentes nos módulos
Python, templates ou configurações locais. Não foi possível confirmar:

- funcionamento real de cada uma das plataformas em produção;
- disponibilidade de FFmpeg no sistema de execução;
- compatibilidade de codecs com Android;
- existência de utilizadores, autenticação ou dados persistentes;
- existência de testes automatizados;
- uma CLI funcional, apesar de `typer` estar listado;
- uma API móvel formal;
- suporte a downloads retomáveis;
- licenciamento global do projeto atual, pois os ficheiros Markdown locais
  aparentam ser documentação do pacote externo.

Sempre que uma funcionalidade futura for discutida, ela deve ser tratada
como proposta até existir implementação verificável no código.
