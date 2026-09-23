# AI Chat Vault — manutenção

Atualizado em 23/09/2026, versão 4.1.4. [English](AGENTS.md).

- Manter README.md, README.pt-BR.md, AGENTS.md e AGENTS.pt-BR.md sincronizados.
- Preservar os 20 perfis de IA. Catálogo alfabético com empresa, descrição, cores e
  estado dos dados; duas páginas de dez; setas direita/esquerda instantâneas, sem Enter.
  Manter N/P, seleção numérica global com Enter, Backspace, Esc e leitura de linha
  alternativa para entrada redirecionada ou ambientes fora do console.
- Preservar os 15 idiomas. Nomes em inglês ASCII e ordem alfabética; 0 é Automático,
  1–15 escolhem idiomas e Enter volta. Traduzir as demais instruções.
- Respeitar CODEX_HOME e caminhos personalizados. Dados não comprovam instalação.
- Start AI Chat Vault.cmd e AI-Chat-Vault.ps1 são as entradas públicas. Arquivos
  técnicos ficam em App; configurações/logs privados em App/Data; backups em Backups.
- Não acumular Archive nem ZIPs na instalação. Preparar alterações e guardar cópia
  anterior temporária fora deste projeto. O proprietário autorizou remover arquivos
  de versões antigas, ZIPs duplicados e logs obsoletos dos testes.
- Nunca excluir backups de conversas, cópias de retorno ou diários como limpeza.
- O escopo do Codex deve incluir explicitamente conversas e índices/bancos da raiz.
  Exclusões de plugins/cache devem aparecer no manifesto e na interface, permanecendo
  intactas ao restaurar. Não omitir links arbitrários nem arquivos SQLite WAL/SHM.
- Unidades do formato 2 exigem validar a raiz, nome relativo, chave estável e tipo
  arquivo/pasta antes de gravar. Recusar travessias e links nos dados incluídos.
- Manter backup de retorno e reversão transacional para arquivos e pastas, inclusive
  auxiliares originalmente ausentes e bancos criados depois do snapshot.
- Continuar lendo snapshots/diários do formato 1, sem reduzir seu escopo silenciosamente.
- O reparo AntiGravity preserva títulos, favoritos e arquivamentos, acrescenta só IDs
  ausentes, mantém cópias e verifica persistência. Não é reparo genérico para outras
  IAs. Dados exclusivamente na nuvem não fazem parte deste programa.
- Não restaurar dados reais para testes. Usar dados artificiais/cópias isoladas;
  inspeção real somente leitura. Manter bloqueios de aplicativo aberto e instância única.
- Testar PowerShell 5.1 e 7, App/Tests/Integration.ps1, CodexScope.ps1 e autotestes.
  PS1 em UTF-8 com BOM. Conferir chaves e placeholders das traduções.
- Mudanças no reparo nativo exigem motor isolado e teste após reinício. Registrar
  evidências e limites em App/Docs/VALIDATION.md e RESEARCH.md.
- Publicar só código/documentos permitidos. Excluir Backups e App/Data; nunca publicar
  cópias privadas de recuperação, arquivos de contas ou conteúdo das conversas.

- Antes de backup/restauração/recuperação, encerrar automaticamente a árvore do app
  escolhido e forçar processos restantes. As verificações durante a cópia continuam
  somente de leitura. Preservar o reparo nativo aberto/ocioso e diagnósticos sem fechar.
- Proteger ancestrais do cofre, outras sessões/contas e PIDs reutilizados. Identificar
  o ponto de entrada dos runtimes; não procurar nomes de IA nos textos dos prompts.
- Executar também App/Tests/Processes.ps1 em PowerShell 5.1 e 7. Testes de encerramento
  devem usar somente processos artificiais próprios, nunca os aplicativos do usuário.
- Manter Backups/<id-estável-da-IA>/<id-do-backup> portátil, descoberta automática
  de cópias concluídas e destinos de restauração resolvidos pelo perfil atual.

- Progresso dentro do fluxo via App/Progress.ps1, sem sobreposição Write-Progress.
  Porcentagens medidas por etapa; totais desconhecidos devem ficar indeterminados.
  Preservar largura do terminal, tempo, caminhos, retornos das funções, fallback
  para saída redirecionada e estados distintos de cancelamento, falha e conclusão.
- Manter enumeração/atributos dos ancestrais pelo .NET recusando links. Não remover
  hashes nem excluir projetos silenciosamente para melhorar a velocidade.
  Testar também App/Tests/Progress.ps1 nos dois PowerShells.

- A seleção de backups deve mostrar a ação atual e a IA, nunca pedir Fazer backup.
  Distinguir o número da cópia do número da IA; repetir escolhas inválidas e manter
  0/Enter vazio para voltar. Atualizar os textos dos 15 idiomas.
- Pergunta da seleção: “Escolha a opção desejada”, sem faixas numéricas. Escolhas
  inválidas remetem à lista; cancelamentos informam que nenhuma operação foi iniciada.

- Rodapé do catálogo: separar page/page_hint traduzidos. Explicar as setas do
  teclado e os atalhos N/P; não exibir “sem Enter” na dica.

- Preservar a prévia completa com duas opções traduzidas: 1 Restaurar este backup;
  0 Cancelar. Enter vazio cancela; escolhas inválidas permitem tentar novamente.
  Não exigir digitar RESTAURAR. Aplicar o fluxo aos 20 perfis e 15 idiomas.
- Empresa exibida do Cursor: SpaceX, conforme anúncio oficial de 14/08/2026
  (https://cursor.com/blog/joining-spacex), conferido em 23/09/2026. Não alterar
  IDs dos aplicativos, caminhos ou pastas de backup por causa dessa apresentação.

- Confirmação: opção 1 verde e opção 0 cinza em linhas separadas, com dica traduzida
  em ciano sobre a cópia de retorno. Manter caminhos/escopo completos na prévia;
  não substituir automaticamente a cópia escolhida por outra mais recente.

- Manter o guia de pastas do README alinhado à estrutura real, incluindo diários
  numerados em `_transactions`, cópias por IA, `.incompleto`, `dados`, Exports,
  subpastas do reparo AntiGravity, App/Data/Logs e arquivos `.cofre-*` adjacentes.
  Explicar que diários não são transcrições nem backups completos de retorno e
  permanecem após conclusão. Não excluir como limpeza genérica nem publicar.
  Não prometer limpeza automática que ainda não foi implementada.

- Atualizar App/Docs/FILES.md e FILES.pt-BR.md ao adicionar, mover ou remover arquivos.
  Listar individualmente código, documentos, testes e idiomas; descrever saídas
  privadas por padrão de nome, sem expor nomes de arquivos reais do usuário.
- Um pedido explícito do proprietário para zerar a pasta para publicação pode remover
  cópias locais e logs após verificar ausência de operação ativa ou recuperação
  pendente. Preservar configurações e código. Não autoriza exclusão rotineira de
  backups nem limpeza nos dados dos aplicativos fora desta pasta.
