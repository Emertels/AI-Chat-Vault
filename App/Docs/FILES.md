# File guide — AI Chat Vault

[Português](FILES.pt-BR.md) · [User guide](../../README.md)

Keep the program files below together. Tests and Locales provide maintenance and
language support; they are not caches. Private generated output is listed by name
pattern because each run creates new names and identifiers.

## Project root

| File or pattern | Description |
|---|---|
| `Start AI Chat Vault.cmd` | Launches the program in Windows PowerShell. Use it in a standalone window. |
| `AI-Chat-Vault.ps1` | Main entry point: parameters, initialization, language, portable paths and single-instance lock. |
| `README.md` | English user guide. |
| `README.pt-BR.md` | Brazilian Portuguese user guide. |
| `AGENTS.md` | English maintenance instructions for agents and developers. |
| `AGENTS.pt-BR.md` | Portuguese maintenance instructions. |
| `LICENSE.txt` | Source usage and distribution license. |
| `.gitignore` | Allows public source while excluding Backups and App/Data from Git. |
| `.gitattributes` | Standardizes Git text and line-ending handling. |

## App — modules

| File or pattern | Description |
|---|---|
| `Antigravity.ps1` | AntiGravity-specific native repair using isolated copies and preserving existing index entries. |
| `Catalog.json` | Company, color, description and coverage classification for each app. |
| `Core.ps1` | Inventory, SHA-256, verified copies, snapshots, transactional restore, journals and rollback. |
| `DataScope.ps1` | Selective Codex scope; file/folder units and validated destination mappings. |
| `Diagnostics.ps1` | Finds history evidence and produces diagnostics; offers SQLite checks. |
| `Interface.ps1` | Menus, paging, arrow-key input, snapshot selection and numbered restore confirmation. |
| `Localization.ps1` | Loads 15 languages, resolves the Windows display language and saves preferences. |
| `Native.cs` | C# helpers for SQLite, local AntiGravity communication and index ID reading. |
| `Native.ps1` | Loads C# helpers and exposes SQLite backup and integrity checks. |
| `Processes.ps1` | Detects and closes associated processes; protects the vault and checks that the app stays closed. |
| `Profiles.ps1` | Defines 20 apps, processes, candidate roots and extension detection gates. |
| `Progress.ps1` | Compact progress, current path, elapsed time, per-phase percentage and completion/cancellation/error states. |
| `Tests.ps1` | Built-in self-test functions available in the menu; distinct from the Tests directory. |

## App/Tests — development tests

| File or pattern | Description |
|---|---|
| `Integration.ps1` | Locales, settings, portability, cross-language restore and locked-file refusal. |
| `CodexScope.ps1` | Codex scope, excluded cache links, indexes, WAL/SHM and mixed file/folder rollback. |
| `Processes.ps1` | Process trees and shutdown using disposable executables; fixture backup/restore. |
| `Progress.ps1` | Percentages, text width, operation states and preservation of function output. |

## App/Docs — documentation

| File or pattern | Description |
|---|---|
| `CHANGELOG.md` | Version history and improvements. |
| `RESEARCH.md` | Sources, investigated formats and known per-app limits. |
| `SECURITY.md` | Private data, credentials and shared-backup handling. |
| `VALIDATION.md` | Tests performed, evidence and validation limitations. |
| `FILES.md` | This English file catalog. |
| `FILES.pt-BR.md` | Portuguese file catalog. |

## App/Locales — 15 languages

| File or pattern | Description |
|---|---|
| `ar.json` | Arabic |
| `zh-CN.json` | Simplified Chinese |
| `zh-TW.json` | Traditional Chinese |
| `nl.json` | Dutch |
| `en.json` | English and fallback baseline |
| `fr.json` | French |
| `de.json` | German |
| `hi.json` | Hindi |
| `it.json` | Italian |
| `ja.json` | Japanese |
| `ko.json` | Korean |
| `pt-BR.json` | Brazilian Portuguese |
| `pt-PT.json` | European Portuguese |
| `ru.json` | Russian |
| `es.json` | Spanish |

## Private files generated during use

| File or pattern | Description |
|---|---|
| `App/Data/preferences.json` | Current language preference; preserve in the personal installation. |
| `App/Data/preferences.json.previous` | Previous preference version retained by safe settings writes. |
| `App/Data/profiles.local.json` | Custom data mappings, when configured; may contain personal paths. |
| `App/Data/*.novo / *.anterior` | Temporary or earlier configuration files, depending on the operation. |
| `App/Data/Logs/session-*.log` | One run’s stages, results and errors. |
| `App/Data/Logs/diagnostic-*.json` | Application diagnostic report. |
| `App/Data/Logs/backup-summary-*.json` | Summary of a multi-app backup operation. |
| `Backups/<IA>/<id>/manifesto.json` | Snapshot metadata and inventory: app, kind, files, hashes and sources. |
| `Backups/<IA>/<id>/manifesto.sha256` | Manifest hash for detecting changes. |
| `Backups/<IA>/<id>/CONCLUIDO` | Completion marker; data verification is still required. |
| `Backups/<IA>/<id>/dados/<origem>/…` | Copied content; inner names and formats belong to the application. |
| `Backups/_transactions/<id>/000001.json, 000002.json, …` | Restore state sequence, not conversation transcripts. |
| `Backups/Exports/<app>-<id>/…` | Snapshot files extracted for inspection. |
| `Backups/antigravity-reparos/<id>/antes-summaries.json` | Index read before repair. |
| `Backups/antigravity-reparos/<id>/summaries-reconstruidos.json` | Information rebuilt by the isolated engine. |
| `Backups/antigravity-reparos/<id>/preparado.json` | Plan and copies prepared before applying the repair. |
| `Backups/antigravity-reparos/<id>/gravado-*.json` | Record of entries added to the index. |
| `Backups/antigravity-reparos/<id>/resultado.json / falha-*.json` | Final result or interruption diagnostics. |
| `Backups/antigravity-reparos/<id>/motor-*.out.log / *.err.log` | Isolated engine’s technical output. |
| `Backups/antigravity-reparos/<id>/stdin-*.txt` | Supporting input used to start the isolated engine. |
| `Backups/antigravity-reparos/<id>/indice-anterior/, conversas-originais/, cofre-isolado/` | Index copies, affected databases and isolated working area. |
| `.cofre-* beside app data` | Originals and staging/rollback locations outside the project folder. |

Tests may leave synthetic fixtures in the Windows temporary directory; those are
not part of the GitHub package. Backups and logs are recreated as needed. Preserved
local settings in App/Data stay outside Git; also exclude that folder when uploading
files manually in a browser or ZIP.
