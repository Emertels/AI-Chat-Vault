# Guia dos arquivos — AI Chat Vault

[English](FILES.md) · [Guia do usuário](../../README.pt-BR.md)

Os arquivos de programa abaixo devem permanecer juntos. Tests e Locales são partes
necessárias para manutenção e idiomas; não são caches. As saídas privadas são
listadas por padrão de nome, pois cada execução cria nomes e identificadores novos.

## Raiz do projeto

| Arquivo ou padrão | Descrição |
|---|---|
| `Start AI Chat Vault.cmd` | Abre o programa no Windows PowerShell. Use este lançador numa janela independente. |
| `AI-Chat-Vault.ps1` | Entrada principal: parâmetros, inicialização, idioma, caminhos portáteis e bloqueio de instância única. |
| `README.md` | Guia do usuário em inglês. |
| `README.pt-BR.md` | Guia do usuário em português do Brasil. |
| `AGENTS.md` | Instruções de manutenção para agentes e desenvolvedores, em inglês. |
| `AGENTS.pt-BR.md` | Versão em português das instruções de manutenção. |
| `LICENSE.txt` | Licença de uso e distribuição do código. |
| `.gitignore` | Define os arquivos publicáveis e exclui Backups e App/Data do Git. |
| `.gitattributes` | Padroniza o tratamento de texto e finais de linha no Git. |

## App — módulos

| Arquivo ou padrão | Descrição |
|---|---|
| `Antigravity.ps1` | Diagnóstico e reparo nativo específico do AntiGravity, usando cópias isoladas e preservação do índice existente. |
| `Catalog.json` | Empresa, cor, descrição e indicação de cobertura de cada IA. |
| `Core.ps1` | Inventário, SHA-256, cópia verificada, backup, restauração transacional, diários e reversão. |
| `DataScope.ps1` | Escopo seletivo do Codex; unidades de arquivo/pasta e mapeamento seguro de destinos. |
| `Diagnostics.ps1` | Localiza evidências de histórico e gera relatórios; oferece verificação SQLite. |
| `Interface.ps1` | Menus, páginas, leitura das setas, seleção de cópias e confirmação numérica de restauração. |
| `Localization.ps1` | Carrega os 15 idiomas, resolve o idioma do Windows e salva a preferência. |
| `Native.cs` | Código C# auxiliar para SQLite, comunicação local com o AntiGravity e leitura de IDs do índice. |
| `Native.ps1` | Carrega os auxiliares C# e expõe cópia e verificação de bancos SQLite. |
| `Processes.ps1` | Detecta e encerra processos associados ao aplicativo; protege o próprio cofre e confere se o app continua fechado. |
| `Profiles.ps1` | Define as 20 IAs, processos, candidatos de pastas e critérios de detecção de extensões. |
| `Progress.ps1` | Barra compacta, caminho atual, tempo, porcentagem por etapa e estados de conclusão/cancelamento/erro. |
| `Tests.ps1` | Funções do autoteste interno acessível pelo menu. Não é a pasta Tests. |

## App/Tests — testes de desenvolvimento

| Arquivo ou padrão | Descrição |
|---|---|
| `Integration.ps1` | Idiomas, configurações, portabilidade, restauração entre idiomas e bloqueio de arquivos em uso. |
| `CodexScope.ps1` | Escopo do Codex, links de cache excluídos, índices, WAL/SHM e reversão de arquivos/pastas. |
| `Processes.ps1` | Árvores de processos e encerramento usando executáveis artificiais; backup/restauração das amostras. |
| `Progress.ps1` | Porcentagens, largura de texto, estados da operação e preservação dos retornos. |

## App/Docs — documentação

| Arquivo ou padrão | Descrição |
|---|---|
| `CHANGELOG.md` | Histórico das versões e melhorias. |
| `RESEARCH.md` | Fontes, formatos investigados e limites conhecidos de cada aplicativo. |
| `SECURITY.md` | Cuidados com dados privados, credenciais e backups compartilhados. |
| `VALIDATION.md` | Testes executados, evidências e limites do que foi validado. |
| `FILES.md` | Este catálogo dos arquivos em inglês. |
| `FILES.pt-BR.md` | Este catálogo dos arquivos em português. |

## App/Locales — 15 idiomas

| Arquivo ou padrão | Descrição |
|---|---|
| `ar.json` | Árabe |
| `zh-CN.json` | Chinês simplificado |
| `zh-TW.json` | Chinês tradicional |
| `nl.json` | Holandês |
| `en.json` | Inglês e base de fallback |
| `fr.json` | Francês |
| `de.json` | Alemão |
| `hi.json` | Hindi |
| `it.json` | Italiano |
| `ja.json` | Japonês |
| `ko.json` | Coreano |
| `pt-BR.json` | Português do Brasil |
| `pt-PT.json` | Português de Portugal |
| `ru.json` | Russo |
| `es.json` | Espanhol |

## Arquivos privados gerados durante o uso

| Arquivo ou padrão | Descrição |
|---|---|
| `App/Data/preferences.json` | Preferência de idioma atual; preservar na instalação pessoal. |
| `App/Data/preferences.json.previous` | Versão anterior da preferência, mantida pela gravação segura. |
| `App/Data/profiles.local.json` | Caminhos de dados personalizados, se configurados. Pode conter caminhos pessoais. |
| `App/Data/*.novo / *.anterior` | Arquivos temporários ou anteriores de configuração; variam conforme a operação. |
| `App/Data/Logs/session-*.log` | Registro de uma execução: etapas, resultados e erros. |
| `App/Data/Logs/diagnostic-*.json` | Relatório de diagnóstico de uma IA. |
| `App/Data/Logs/backup-summary-*.json` | Resumo de um comando de backup de várias IAs. |
| `Backups/<IA>/<id>/manifesto.json` | Metadados e inventário do backup: app, tipo, arquivos, hashes e origens. |
| `Backups/<IA>/<id>/manifesto.sha256` | Hash do manifesto para detectar alterações. |
| `Backups/<IA>/<id>/CONCLUIDO` | Marcador de conclusão. A validação dos dados continua obrigatória. |
| `Backups/<IA>/<id>/dados/<origem>/…` | Conteúdo copiado. Nomes e formatos internos pertencem ao aplicativo. |
| `Backups/_transactions/<id>/000001.json, 000002.json, …` | Sequência de estados de uma restauração. Não são transcrições. |
| `Backups/Exports/<app>-<id>/…` | Arquivos extraídos de uma cópia para inspeção. |
| `Backups/antigravity-reparos/<id>/antes-summaries.json` | Índice lido antes do reparo. |
| `Backups/antigravity-reparos/<id>/summaries-reconstruidos.json` | Informações reconstruídas pelo motor isolado. |
| `Backups/antigravity-reparos/<id>/preparado.json` | Plano e cópias preparados antes de aplicar a correção. |
| `Backups/antigravity-reparos/<id>/gravado-*.json` | Registro das entradas acrescentadas ao índice. |
| `Backups/antigravity-reparos/<id>/resultado.json / falha-*.json` | Resultado final ou diagnóstico de interrupção. |
| `Backups/antigravity-reparos/<id>/motor-*.out.log / *.err.log` | Saída técnica do motor isolado. |
| `Backups/antigravity-reparos/<id>/stdin-*.txt` | Entrada auxiliar usada para iniciar o motor isolado. |
| `Backups/antigravity-reparos/<id>/indice-anterior/, conversas-originais/, cofre-isolado/` | Cópias do índice, bancos envolvidos e área isolada de trabalho. |
| `.cofre-* ao lado dos dados do aplicativo` | Originais e áreas de preparação/retorno da restauração, fora da pasta do projeto. |

Os testes podem deixar amostras artificiais na pasta temporária do Windows. Elas
não fazem parte do pacote para GitHub. O programa recria Backups e os logs quando
necessário. Configurações locais preservadas em App/Data ficam fora do Git; ao
enviar arquivos manualmente pelo navegador ou em ZIP, exclua essa pasta também.
