# 🛡️ AI Chat Vault 4.1

<div align="center">

**🌐 Idiomas / Languages:**  
[![Português Brasil](https://img.shields.io/badge/Idioma-Portugu%C3%AAs%20(Brasil)-green?style=for-the-badge)](README-PT-BR.md)
[![English](https://img.shields.io/badge/Language-English-blue?style=for-the-badge)](README-EN.md)

</div>

---

Backup portátil e recuperação de conversas locais de ferramentas e IAs de programação. Antes chamado **Cofre IA**. Inclui 20 aplicativos, 15 idiomas de interface e reparo nativo do AntiGravity.

[Guia de todos os arquivos](App/Docs/FILES.pt-BR.md)

## Comece aqui

Abra **Start AI Chat Vault.cmd** com seu usuário normal. Escolha Backup, Restaurar,
Reparar / diagnosticar, Ferramentas ou Idioma. O catálogo tem **duas páginas de dez
aplicativos**: seta direita avança e seta esquerda volta imediatamente, sem Enter.
N/P continuam disponíveis. Digite o número de 1 a 20 e pressione Enter para escolher;
Backspace corrige, Esc ou Enter vazio retorna. Em entrada redirecionada ou fora de
um console, use N/P seguido de Enter. As cores,
empresas, descrições e indicações de dados encontrados foram mantidas.

```text
Start AI Chat Vault.cmd     Abre o programa
AI-Chat-Vault.ps1           Script principal
Backups/                   Backups de conversas e cópias para recuperação
App/                       Componentes do programa; não precisa mexer
README.md / README.pt-BR.md Guias de uso
AGENTS.md / AGENTS.pt-BR.md Instruções para manutenção
LICENSE.txt                Licença
```

Dentro de App ficam módulos, Locales, Catalog.json, testes de desenvolvimento e
documentação técnica. App/Data guarda idioma, caminhos personalizados e logs.
Backups fica **sempre ao lado do script**, não na pasta atual do terminal. Copie a
pasta completa ao mudar de disco. Arquivos de versões antigas e ZIPs duplicados
não são necessários para usar o programa.

## O que significa cada pasta

Algumas pastas só aparecem depois que você usa a função correspondente. Os nomes
técnicos internos são mantidos para o programa reconhecer cópias antigas.

| Pasta | Para que serve |
|---|---|
| `App/` | Componentes que fazem o programa funcionar: módulos PowerShell, catálogo e código auxiliar. |
| `App/Locales/` | Textos da interface nos 15 idiomas. |
| `App/Docs/` | Pesquisa, histórico de melhorias, validação e orientações de segurança. |
| `App/Tests/` | Testes de desenvolvimento com dados e processos artificiais. Não são suas conversas. |
| `App/Data/` | Preferências e caminhos personalizados deste computador. É privada. |
| `App/Data/Logs/` | Registros de execução, diagnósticos e resumos de operações. Podem incluir caminhos pessoais. |
| `Backups/` | Todas as cópias de conversas e os registros necessários para recuperá-las. É privada. |
| `Backups/<IA>/` | Cópias separadas por aplicativo, como `cursor`, `opencode` e `xiaomi-mimo`. |
| `Backups/<IA>/<data-identificador>/` | Uma cópia individual. Pode ser backup manual ou cópia de retorno criada antes de restaurar. A lista do programa informa o tipo e a data. |
| `Backups/<IA>/<data-identificador>.incompleto/` | Cópia em preparação ou interrompida. O programa não a oferece como backup concluído para restaurar. |
| `Backups/<IA>/<data-identificador>/dados/` | Arquivos efetivamente copiados. As subpastas representam as origens mapeadas do aplicativo; o conteúdo interno varia conforme a IA. |
| `Backups/_transactions/` | Diários das restaurações: registram etapas e permitem reconhecer ou reverter uma operação interrompida. Não são transcrições. |
| `Backups/_transactions/<identificador>/` | Registro de uma única operação de restauração, com arquivos JSON numerados que preservam a sequência das etapas. |
| `Backups/Exports/` | Cópias extraídas para inspecionar os arquivos sem restaurá-los no aplicativo. |
| `Backups/antigravity-reparos/` | Cópias e relatórios do reparo especial do AntiGravity. Não são backups completos oferecidos na lista normal de restauração. |

No reparo do AntiGravity, cada execução tem sua pasta. Dentro dela,
`indice-anterior/` guarda os arquivos do índice antes da correção;
`conversas-originais/` guarda cópias dos bancos envolvidos;
`cofre-isolado/` é a área usada pelo motor isolado para reconstruir as informações.

Fora da pasta do programa, podem existir arquivos ou pastas `.cofre-*` **ao lado dos
dados restaurados**. Eles fazem parte da troca segura: preservam originais e áreas
de preparação/retorno. Não são cópias extras para escolher pelo nome no menu.

### Entendendo `_transactions`

Cada nome longo, como uma sequência de letras e números, é o identificador único
da operação. Não é o nome de uma conversa. Os arquivos `000001.json`, `000002.json`
e seguintes descrevem o aplicativo, os caminhos, a cópia de retorno e o andamento
das trocas. O último registro válido informa o estado mais recente.

`Concluido` indica restauração concluída; `Revertido`, uma reversão concluída;
`Cancelado`, cancelamento registrado. Outros estados podem indicar uma operação
que precisa de recuperação. Os diários continuam guardados após o sucesso — a
presença dessas pastas, sozinha, **não indica erro**. Se o programa identificar uma
pendência, use **Ferramentas → Recuperar operação interrompida**.

O diário não substitui o backup de retorno: a cópia de retorno contém os dados
anteriores; o diário descreve o que foi feito. Não renomeie, edite ou apague os
diários nem os arquivos `.cofre-*` como uma limpeza comum, especialmente durante
uma operação ou recuperação. O programa ainda não oferece limpeza automática
desses registros com validação de dependências.

### Arquivos dentro de uma cópia

- `manifesto.json`: identifica a IA, as origens, o tipo da cópia e o inventário de arquivos.
- `manifesto.sha256`: permite verificar a integridade desse manifesto.
- `CONCLUIDO`: marcador de conclusão; a restauração também verifica manifesto e dados.
- `dados/`: conteúdo da cópia, organizado pelas origens mapeadas.

Para publicar no GitHub, mantenha o código e a documentação, incluindo
`App/Locales`, `App/Docs` e `App/Tests`. **Não publique `Backups` nem `App/Data`**;
o `.gitignore` já os exclui. Não é necessário apagar suas cópias locais para publicar
somente o código.

## Backup e restauração

1. Salve o trabalho e abra Start AI Chat Vault.cmd numa janela separada do Windows.
   Backup e restauração fecham automaticamente a IA e seus processos associados.
   Após uma breve tentativa de fechamento normal, os restantes são encerrados à força.
   Trabalhos não salvos e tarefas em andamento podem ser interrompidos.
2. Escolha uma IA ou todas com dados locais. A cópia só é concluída depois de
   verificar SHA-256 e reler a origem para detectar alterações durante a operação.
3. Para restaurar, escolha a IA e a data, confira os caminhos e escolha 1 (Restaurar este backup).
   Antes da troca, o programa cria um backup de retorno verificado.
4. Confira as conversas na IA e novamente depois de fechá-la e reabri-la.

A restauração volta os dados à data escolhida; **não mescla bancos**. Dados mais
novos ficam no backup de retorno e nas cópias `.cofre-*` ao lado dos caminhos
afetados. Ferramentas permite desfazer a restauração, verificar/extrair uma cópia
e recuperar operações interrompidas. Não apague diários nem originais durante uma
recuperação. Os diários ficam em `Backups/_transactions`; extrações em `Backups/Exports`.

Arquivo em uso, inclusive SQLite WAL/SHM, interrompe o backup com orientação para
tentar novamente. Links dentro dos dados incluídos são recusados; não são seguidos
nem omitidos silenciosamente. O fechamento automático vale para os 20 perfis e pode
fechar VS Code/Cursor quando hospedam uma extensão afetada. Processos de outras
sessões/contas do Windows e o aplicativo que está hospedando o próprio cofre não
são encerrados à força. Falta de permissão ou reinício persistente interrompem a
operação; reabrir a IA durante a cópia também impede sua conclusão. Use o lançador
separado, não o terminal integrado do editor. O reparo nativo do AntiGravity mantém
o fluxo aberto e ocioso; diagnósticos somente de leitura não encerram aplicativos.
O programa não baixa conversas da nuvem. Projetos externos precisam de backup
separado. Encontrar dados locais não comprova instalação ativa nem histórico completo.

Os backups ficam separados pelo nome/ID estável da IA: `Backups/zcode/<data-id>`
ou `Backups/codex/<data-id>`. Backups concluídos aparecem automaticamente no menu
de restauração. O registro identifica a IA e os destinos são resolvidos pelo perfil
do computador atual, não pelo caminho antigo da origem. Copie a pasta completa
para pendrive ou HD externo: não precisa mudar o diretório do terminal. Caminhos
absolutos personalizados ainda precisam ser ajustados ao mudar de computador.

## Dicas práticas de backup e restauração

- **Onde a cópia fica:** o destino é sempre `Backups` ao lado do script. Por exemplo,
  `Backups/cursor/<data-id>`, `Backups/opencode/<data-id>` e
  `Backups/xiaomi-mimo/<data-id>`. As pastas das IAs surgem conforme você faz backups.
- **Mais de uma cópia:** cada execução cria seu próprio identificador; não substitui
  silenciosamente a cópia anterior. O nome da pasta usa UTC e um sufixo único; o menu
  mostra a data no horário local. Não renomeie as pastas identificadoras nem edite os
  manifestos para “organizar”, pois o programa usa esses nomes para reconhecer cópias.
- **Reconhecimento:** escolha a IA e depois a cópia da lista. Só cópias concluídas são
  oferecidas; a restauração verifica seu conteúdo novamente. Pastas `.incompleto` não
  são backups prontos. “Não localizado” significa que o perfil de dados atual não foi
  encontrado; não significa que seus backups desapareceram.
- **Portabilidade:** mova a pasta inteira do cofre, com App e Backups, para outra unidade,
  pendrive ou HD externo. Não precisa trocar o diretório do terminal. Para transferir
  somente uma cópia entre cofres compatíveis, preserve `Backups/<IA>/<data-id>` inteiro,
  com dados e metadados. Caminhos personalizados absolutos podem precisar de ajuste
  em outro computador. Prefira a mesma versão do aplicativo que produziu os dados.
- **Antes de copiar:** salve trabalhos e tarefas. O cofre fecha os processos associados
  ao perfil escolhido, podendo fechar o editor hospedeiro. Abra o lançador fora da IA
  que será encerrada. Não reabra essa IA durante a operação.
- **Antes de restaurar:** confira a data e os caminhos da prévia; 1 aplica, 0 cancela.
  A operação substitui o estado das origens mapeadas, sem mesclar conversas ou bancos.
  O programa cria uma cópia de retorno dos dados atuais antes da troca. Ela fica junto
  dos outros backups da IA e aparece na lista, identificada pelo tipo e pela data.
- **Para desfazer:** use Ferramentas > Voltar ao estado anterior e escolha a cópia de
  retorno desejada. Não confunda essa cópia com `_transactions`, que guarda apenas o
  registro técnico das etapas. Se houver interrupção, use a função de recuperação.
- **Espaço e demora:** considere a cópia escolhida, o backup de retorno e as áreas de
  preparação/originais preservados. Muitos arquivos pequenos, projetos incorporados,
  antivírus e pendrives lentos podem aumentar o tempo. A porcentagem é por etapa;
  aguarde a mensagem final com o diretório. A verificação de hashes não é dispensada.
- **Limites:** são dados locais. Históricos apenas na nuvem, projetos fora das origens
  e diferenças entre versões podem exigir outras medidas. O reparo nativo de índice
  é específico do AntiGravity; restaurar um snapshot é a opção comum às demais IAs.
- **Compartilhamento:** backups podem incluir contas, tokens e nomes de arquivos.
  Guarde uma segunda cópia dos backups importantes em outro disco. Para GitHub, envie
  somente código/documentação; exclua Backups e App/Data também de ZIPs e uploads manuais.

## Codex: foco nas conversas

O erro anterior aconteceu porque a varredura de todo o CODEX_HOME encontrou uma
junção no cache de plugins. Agora o Codex usa unidades separadas de dados:

- sessions, archived_sessions, attachments, visualizations, dictation-history,
  sqlite, rollout-migrations, vendor_imports e agents, quando presentes;
- session_index.jsonl, history.jsonl, .codex-global-state.json e seu .bak,
  config.toml, auth.json e bancos SQLite da raiz, exceto logs_*;
- arquivos SQLite WAL/SHM associados, registrando também quando não existiam.

Plugins, outros caches, sandboxes e temporários não são percorridos. O manifesto
registra o que ficou fora da cópia. Na restauração, esses caminhos excluídos também
permanecem intactos. Bancos da raiz são restaurados como arquivos, não como pastas.
Bancos e arquivos auxiliares criados após o snapshot voltam à ausência original,
com os dados atuais preservados no retorno. Prefira uma versão compatível da IA;
o programa não valida todos os esquemas internos dos bancos.

É backup de conversas/dados, não uma cópia completa da instalação do Codex. Pode
incluir credenciais e tokens: guarde Backups em local privado. SHA-256 verifica
bytes, não a confiança no autor do backup nem compatibilidade com toda versão da IA.
Backups antigos do formato 1 continuam legíveis. Os novos backups seletivos do Codex
usam formato 2 e exigem versão 4 ou posterior. Restaurações antigas de pasta completa
mantêm o alcance original e podem parar em links; os snapshots antigos não são alterados.

## Aplicativos

Os dez anteriores foram mantidos, com dez acréscimos, em ordem alfabética. É uma
seleção de ferramentas conhecidas, não um ranking absoluto.

| Aplicativo | Empresa / projeto | Escopo local |
|---|---|---|
| Antigravity | Google | Bancos de conversa, índice do hub e perfil local; reparo nativo 2.x. |
| Augment Code | Augment Code | Dados candidatos .augment e perfil da extensão detectada no editor. |
| Claude Code | Anthropic | Motor local .claude e perfil Claude Desktop. |
| Cline | Cline | Dados .cline e perfil do editor com a extensão detectada. |
| Codex | OpenAI | Conversas, anexos, índices/bancos da raiz e perfil desktop; cache de plugins fora da cópia. |
| Continue | Continue | Sessões locais .continue e perfil do editor detectado. |
| Cursor | SpaceX | Perfil User do editor e .cursor/projects. |
| GitHub Copilot | GitHub / Microsoft | Chat integrado do VS Code e perfil User completo do editor. |
| Kilo Code | Kilo | Motor atual kilo.db, gerenciador de agentes e perfil legado detectado. |
| Kimi Code / Desktop | Moonshot AI | Tarefas Work locais do Desktop e motores de integração Code. |
| Kiro | AWS | Candidatos: perfil Kiro User e pasta .kiro. |
| OpenCode Desktop | Anomaly | Motor local opencode.db e perfil desktop. |
| Qwen Code | Alibaba | Motor da integração com editor; projetos e chats .qwen. |
| Roo Code | Roo Code Inc. | Históricos locais da extensão Roo Code existente e índice do editor. |
| Tabnine | Tabnine | Pastas locais candidatas e perfil da extensão detectada. |
| Trae | ByteDance | Perfis User candidatos das edições global e chinesa. |
| Windsurf | Cognition | Motor Cascade local e perfil User do editor. |
| Xiaomi MiMo | Xiaomi | mimocode.db, índices desktop e anexos. |
| ZCode | Z.ai | Bancos .zcode, registros, tarefas e perfil desktop. |
| Zed | Zed Industries | Bancos locais do Windows e perfil Zed. |


[OpenCode](https://opencode.ai/) · [Repositório oficial](https://github.com/anomalyco/opencode).
Caminhos candidatos, especialmente Augment, Kiro, Tabnine e Trae, devem ser conferidos
no Diagnóstico. Perfis User do editor podem incluir outras extensões/configurações;
o menu informa esse alcance. Fontes e limites: [pesquisa](App/Docs/RESEARCH.md).

## Reparo do AntiGravity

Somente para esse reparo, mantenha o AntiGravity aberto e o agente parado. O módulo
preserva o índice atual, lê cópias SQLite isoladas pelo motor instalado, acrescenta
apenas IDs ausentes e confere a persistência. Não gera respostas nem altera títulos,
favoritos ou arquivamentos existentes. Títulos recuperados podem ser antigos e
subagentes podem ter bancos próprios. Protocolo desconhecido interrompe a correção.
Nas outras IAs, a recuperação é por snapshot, sem reconstrução genérica de índices.
Os registros em Backups/antigravity-reparos não são snapshots completos do aplicativo.

## Idiomas

**0 = Automático; 1 a 15 = idiomas; Enter = voltar sem alterar a preferência.**
Os nomes ingleses ASCII ficam nesta ordem: Arabic, Chinese (Simplified), Chinese
(Traditional), Dutch, English, French, German, Hindi, Italian, Japanese, Korean,
Portuguese (Brazil), Portuguese (Portugal), Russian e Spanish.

O automático usa o idioma de exibição do Windows, separando pt-PT e chinês tradicional;
idiomas não suportados usam inglês. Menus e instruções são traduzidos; detalhes
técnicos e mensagens do motor podem manter o idioma original. Fontes e renderização
dependem do terminal. O idioma não muda IDs, hashes nem caminhos dos backups.
A preferência fica em App/Data/preferences.json.

## Manutenção e GitHub

App/Data e Backups são privados e excluídos pelo .gitignore. Publique apenas código
e documentação, nunca a pasta de trabalho com dados pessoais. Não há upload automático.
Caminhos opcionais ficam em App/Data/profiles.local.json; configurações antigas podem
ser migradas. README e AGENTS nos dois idiomas devem ser atualizados juntos.

```powershell
.\AI-Chat-Vault.ps1 -Acao Listar -Idioma pt-BR
.\AI-Chat-Vault.ps1 -Acao Diagnostico -Aplicativo codex
.\AI-Chat-Vault.ps1 -Acao AutoTeste
.\App\Tests\Integration.ps1
.\App\Tests\CodexScope.ps1
```

[Validação](App/Docs/VALIDATION.md) · [Alterações](App/Docs/CHANGELOG.md) · [Segurança](App/Docs/SECURITY.md)

## Progresso e perfis grandes

Cada operação mostra o nome da IA, a ação (fazendo backup, restaurando, verificando,
reparando ou diagnosticando), uma barra pequena, caminho atual e tempo decorrido.
A porcentagem corresponde à etapa atual, não ao tempo total restante: primeiro
conta os arquivos e mostra `--%`; depois mede a verificação, com atualização durante
arquivos grandes. A cópia também inclui verificar o hash do destino. A barra pode
reiniciar ao mudar de pasta/etapa. Chegar a 100% na verificação não significa que o
backup terminou: aguarde a mensagem final com o diretório da cópia concluída.
Cancelamento e falha aparecem separadamente. Saída redirecionada recebe linhas
periódicas, sem reposicionar o cursor. A barra sobreposta do PowerShell foi removida.

A pasta completa do ZCode pode incluir projetos e node_modules. A inspeção local
somente de leitura encontrou 73.062 arquivos (1,65 GiB) no workspace, sendo 35.637
dependências. Eles continuam incluídos; esta versão não elimina dados de projeto
silenciosamente. Num teste artificial com 1.000 arquivos em pastas aninhadas, o
inventário caiu de 21,38 s para 2,72 s, com hashes e entradas idênticos (PowerShell
5.1). Não é promessa de velocidade para o backup completo. Acesso direto do .NET
reduz consultas repetidas, preservando recusa de links, hashes, releitura da origem
e verificação do destino. Muitos arquivos pequenos e pendrives lentos ainda levam
tempo. Esc cancela antes da aplicação; cópias incompletas não são oferecidas para
restaurar. Reabra o lançador após atualizar: uma janela já aberta continua com o
código anterior.

A seleção da cópia mostra a ação atual (Restaurar, Verificar, Extrair ou Retornar)
e o nome da IA. Digite o número do backup da lista, não o número do aplicativo.
Exemplo: depois de escolher a IA 12 (OpenCode), se houver só um backup, escolha 1.
Um número inválido pede nova escolha; 0 ou Enter vazio volta sem restaurar nada.
A pergunta é “Escolha a opção desejada”, sem repetir uma faixa numérica. Escolhas
inválidas orientam a consultar a lista; ao cancelar, a tela confirma que nenhuma
operação foi iniciada. As cópias numeradas e o 0 (Voltar) continuam visíveis.

O rodapé separa o número da página da dica: “Use as setas do teclado. Direita/N
avança; esquerda/P volta.” O texto “sem Enter” foi retirado do rodapé; as setas
continuam funcionando imediatamente.

A prévia de restauração continua mostrando o backup escolhido, o escopo local,
os diretórios afetados e o aviso de versão. Escolha 1 (Restaurar este backup) e pressione Enter
para aplicar, ou 0 (Cancelar) para voltar. Enter vazio também cancela; uma opção
inválida permite tentar novamente. Essa tela é uma confirmação antes de restaurar,
não a conclusão de um backup. Antes de substituir os dados atuais, o programa
cria uma cópia de retorno verificada.

A empresa exibida para o Cursor é SpaceX, conforme o
[anúncio oficial da aquisição em 14 de agosto de 2026](https://cursor.com/blog/joining-spacex),
consultado em 23 de setembro de 2026. Caminhos e compatibilidade dos backups permanecem iguais.

As opções ficam uma abaixo da outra: 1 Restaurar este backup em verde e 0 Cancelar
em cinza. Uma dica explica a cópia de retorno: ela guarda os dados imediatamente
anteriores à restauração e, ao terminar, aparece na lista e em Ferramentas > Voltar
ao estado anterior. Aguarde uma restauração em andamento terminar antes de reabrir
o lançador para carregar uma atualização.

---

## 👤 Sobre o Autor

Desenvolvido e mantido por **Emerson Teles** (conhecido na comunidade como **Emertels**).

Apaixonado por tecnologia, informática, jogos, manutenção de sistemas e tradução/localização de softwares e emuladores para o Português do Brasil (PT-BR).

### 🛠️ Projetos & Contribuições Notáveis:
- **Softwares & Utilitários:** Tradução 100% de **DSX** (DualSense X - Trusted Translator), **ASUS GPU Tweak III**, **dnGrep**, **XWidget** e ferramentas web (**DualSense Tester**, **DualShock Tools**).
- **Emulação & Consoles:** Localização de sistemas e emuladores como **PSBBN** (PlayStation Broadband Navigator do PS2), **PCSX2**, **Dolphin**, **shadPS4**, **Azahar** e **RetroArch**.
- **Jogos:** Tradução de **Silent Hill 5: Homecoming**, projetos em andamento em **Silent Hill 4: The Room** e diversos outros aplicativos.

---

### 🌐 Conecte-se comigo:

<div align="left">

[![GitHub](https://img.shields.io/badge/GitHub-Emertels-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emertels)
[![Discord](https://img.shields.io/badge/Discord-Emertels%20Server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/eRGFqQkvj)
[![X / Twitter](https://img.shields.io/badge/X_Twitter-@emertels-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/emertels)
[![YouTube](https://img.shields.io/badge/YouTube-Emerson_Teles-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@emersonteles2379)
[![Telegram](https://img.shields.io/badge/Telegram-Aplicativos%20Mods-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/apksmodsandroid)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Apoiar%20Projeto-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/emertels)

</div>

