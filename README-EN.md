# 🛡️ AI Chat Vault 4.1

<div align="center">

**🌐 Languages / Idiomas:**  
[![Português Brasil](https://img.shields.io/badge/Idioma-Portugu%C3%AAs%20(Brasil)-green?style=for-the-badge)](README-PT-BR.md)
[![English](https://img.shields.io/badge/Language-English-blue?style=for-the-badge)](README-EN.md)

</div>

---

Portable backup and recovery for local AI coding conversations. Previously named **Cofre IA**. Includes 20 applications, 15 interface languages, and native AntiGravity repair.

[Complete file guide](App/Docs/FILES.md)

## Start here

Open **Start AI Chat Vault.cmd** under your normal Windows account. Choose Backup,
Restore, Repair / diagnose, Tools or Language. The colored catalog has **two pages
of ten applications**: press Right Arrow for the next page or Left Arrow for the
previous page, immediately without Enter. N/P remain available. Type the application
number (1–20) and press Enter to select; Backspace edits, Esc or empty Enter returns.
Redirected input/non-console hosts use N/P followed by Enter.
Company, description and local-data status remain visible.

Keep the following together when moving the vault to another drive:

```text
Start AI Chat Vault.cmd     Open the program
AI-Chat-Vault.ps1           Main script
Backups/                   All conversation backups and recovery copies
App/                       Program components; no manual setup required
README.md / README.pt-BR.md User guides
AGENTS.md / AGENTS.pt-BR.md Maintenance instructions
LICENSE.txt                License
```

App contains the modules, Locales, Catalog.json, developer Tests and Docs. App/Data
stores language preferences, optional profile paths and diagnostic logs. Backups is
always beside the main script, independent of the terminal working directory.
No historical code archives or duplicate release ZIPs are required to run the tool.

## What each folder means

Some folders appear only after the corresponding feature is used. Internal
technical names remain unchanged so older snapshots stay recognizable.

| Folder | Purpose |
|---|---|
| `App/` | Program components: PowerShell modules, catalog and supporting code. |
| `App/Locales/` | Interface text in all 15 languages. |
| `App/Docs/` | Research, changelog, validation and security guidance. |
| `App/Tests/` | Development tests using synthetic data and disposable processes, not your conversations. |
| `App/Data/` | This computer's preferences and custom paths. Private. |
| `App/Data/Logs/` | Execution logs, diagnostics and operation summaries; may contain personal paths. |
| `Backups/` | Conversation snapshots and the records needed for recovery. Private. |
| `Backups/<app>/` | Copies grouped by application, such as `cursor`, `opencode` and `xiaomi-mimo`. |
| `Backups/<app>/<timestamp-id>/` | One snapshot: either a manual backup or a safety copy made before restoration. The picker displays its kind and date. |
| `Backups/<app>/<timestamp-id>.incompleto/` | A copy being prepared or interrupted. It is not offered as a completed backup for restoration. |
| `Backups/<app>/<timestamp-id>/dados/` | The copied files. Subfolders represent mapped application sources; their internal contents depend on the app. |
| `Backups/_transactions/` | Restore journals: record steps and help detect or roll back interrupted operations. These are not conversation transcripts. |
| `Backups/_transactions/<id>/` | One restore operation, with numbered JSON files preserving the sequence of steps. |
| `Backups/Exports/` | Extracted copies for inspecting files without restoring them into the application. |
| `Backups/antigravity-reparos/` | Copies and reports from the special AntiGravity repair. These are not full snapshots offered by the normal restore picker. |

Each AntiGravity repair has its own subfolder. Within it, `indice-anterior/` holds
pre-repair index files; `conversas-originais/` holds copies of the affected databases;
`cofre-isolado/` is the isolated engine's working area for rebuilding information.

Outside the program folder, `.cofre-*` files or directories may exist **beside the
restored application data**. They support safe replacement by retaining originals
and staging/rollback locations. They are not extra snapshots to select by name.

### Understanding `_transactions`

Each long sequence of letters and digits is a unique operation identifier, not a
conversation name. Files such as `000001.json`, `000002.json` and subsequent entries
describe the app, paths, safety snapshot and replacement progress. The latest valid
record represents the latest state.

`Concluido` means restoration completed; `Revertido` means rollback completed;
`Cancelado` means a recorded cancellation. Other states may require recovery.
Journals remain after success: **their presence alone does not indicate a failure**.
If the program reports a pending operation, use **Tools → Recover interrupted operation**.

The journal does not replace the safety snapshot: the snapshot contains the previous
data, while the journal describes the changes. Do not rename, edit or delete journals
or `.cofre-*` originals as routine cleanup, especially during an operation or recovery.
The program does not yet provide automatic dependency-checked cleanup for these records.

### Files inside a snapshot

- `manifesto.json`: identifies the app, sources, snapshot kind and file inventory.
- `manifesto.sha256`: verifies the manifest's integrity.
- `CONCLUIDO`: completion marker; restoration also checks the manifest and data.
- `dados/`: snapshot content, grouped by mapped source.

For GitHub, publish source and documentation, including `App/Locales`, `App/Docs`
and `App/Tests`. **Do not publish `Backups` or `App/Data`**; `.gitignore` excludes
them already. You do not need to delete your local backups to publish source only.

## Back up and restore

1. Save your work, then launch Start AI Chat Vault.cmd in a separate Windows window.
   Backup and restore automatically close the selected app and associated processes.
   After a short normal-close attempt, remaining processes are forcibly terminated.
   Unsaved work and active tasks may be interrupted; save before choosing the action.
2. Choose an application or all applications with local data. A backup is completed
   only after SHA-256 checks and a second source read to detect changes.
3. For restore, choose the application and backup date, inspect the exact paths and
   choose 1 (Restore this backup). The tool creates a verified safety backup first.
4. Check the conversations in the app, then close and reopen it to confirm persistence.

Restoration replaces the backed-up data state; it does not merge conversation
databases. Newer data is preserved in a safety backup and `.cofre-*` originals next
to the affected paths. Tools can undo a restore, verify/extract a backup or recover
an interrupted operation. Never delete recovery journals or originals during recovery.
Journals live under `Backups/_transactions`; inspection copies under `Backups/Exports`.

Locked files (including SQLite WAL/SHM) stop backup with an actionable message.
Links inside backed-up conversation data are rejected rather than followed or silently
ignored. Shutdown applies to all 20 profiles and can also close VS Code/Cursor when
they host an affected extension. Processes in other Windows sessions/accounts and
the vault’s own parent application are not forcibly terminated. Permission failures
or persistent relaunches stop the operation; a reopened app during copying also
stops verification. Use the standalone launcher, not an integrated editor terminal.
Native AntiGravity repair remains a separate open-and-idle operation, and read-only
diagnostics never terminate processes. Tests do not alter live conversations. The
tool does not download cloud-only histories. Files outside mapped paths, including external projects, need
separate backup. Found local data is not proof of installation or complete coverage.

Backups are grouped by stable application names/IDs: `Backups/zcode/<timestamp-id>`
or `Backups/codex/<timestamp-id>`. Completed backups appear automatically in the
restore menu. The manifest identifies the app; destinations come from the current
computer’s profile, not the old source path. Copy the whole vault to a USB/external
drive: no working-directory change is needed. Custom absolute profile overrides
still need adjustment when moving to a different computer.

## Practical backup and restore tips

- **Destination:** backups always go into `Backups` beside the script, for example
  `Backups/cursor/<timestamp-id>`, `Backups/opencode/<timestamp-id>` and
  `Backups/xiaomi-mimo/<timestamp-id>`. App folders appear as you create their backups.
- **Multiple copies:** each run gets a unique identifier instead of silently replacing
  the previous snapshot. Folder names use UTC plus a unique suffix; the menu displays
  local time. Do not rename snapshot identifiers or edit manifests for organization;
  the program relies on those names to discover copies.
- **Discovery:** choose the app, then its snapshot. Only completed copies are offered;
  restoration verifies their contents again. `.incompleto` folders are not ready
  backups. “Not found” means current application data was not found, not that existing
  backups disappeared.
- **Portability:** move the whole vault, including App and Backups, to another drive,
  USB stick or external disk. No terminal-directory change is required. To transfer
  just a snapshot between compatible vaults, preserve its entire
  `Backups/<app>/<timestamp-id>` structure, including data and metadata. Absolute
  custom paths may need adjustment on another computer. Prefer the app version that
  originally produced the data.
- **Before copying:** save work and tasks. The vault closes associated processes and
  may close the host editor. Launch it outside the app being closed; keep that app
  closed throughout the operation.
- **Before restoring:** review the date and destination preview; 1 applies, 0 cancels.
  Restoration replaces mapped source state without merging conversations/databases.
  A safety snapshot preserves current data before replacement. It lives alongside
  the app's other backups and appears with its kind and date in the picker.
- **Undo:** use Tools > Return to the previous state and choose the intended safety
  snapshot. Do not confuse it with `_transactions`, which records the operation steps.
  Use recovery tools if an operation was interrupted.
- **Space and duration:** account for the chosen copy, safety snapshot, staging and
  preserved originals. Many small files, embedded projects, antivirus and slow USB
  devices can increase duration. Percentages refer to the current phase; wait for the
  final message with the destination. Hash verification is not skipped.
- **Limits:** coverage is local. Cloud-only history, projects outside mapped sources
  and app-version differences may require other measures. Native index repair is
  specific to AntiGravity; snapshot restoration is shared by the other apps.
- **Sharing:** snapshots can contain account data, tokens and filenames. Keep another
  copy of important backups on a separate disk. Publish source/docs only to GitHub;
  exclude Backups and App/Data from ZIPs and manual browser uploads too.

## Codex: conversation-focused scope

The earlier failure occurred because a full CODEX_HOME scan encountered a plugin-cache
junction. Codex now backs up selected data as separate file/directory units:

- sessions, archived_sessions, attachments, visualizations, dictation-history,
  sqlite, rollout-migrations, vendor_imports and agents when present;
- session_index.jsonl, history.jsonl, .codex-global-state.json and its .bak,
  config.toml, auth.json, and root SQLite databases except logs_*;
- SQLite WAL/SHM companions, including recording when they were absent.

Plugins, other caches, sandboxes and temporary runtime folders are not traversed.
The manifest records excluded top-level items. These out-of-scope paths are also
left untouched by restore. Root databases are copied as files, not replaced with
directories. Databases/sidecars created after the snapshot are safely returned to
their earlier absent state, with current contents preserved in the safety snapshot.
Use a compatible app version; the tool cannot validate every internal database schema.

This is a conversation/data backup, not a full Codex installation clone. Profiles
can contain credentials and tokens: keep Backups private. Hashes verify bytes, not
the trustworthiness of a backup's author or compatibility with every app release.
Existing schema-1 backups remain readable. New scoped Codex backups use schema 2
and require version 4 or later. Legacy full-folder restores retain their broader
scope and may stop on a live data/cache link; the tool does not rewrite old snapshots.

## Applications

The original ten tools remain, with ten additions, in alphabetical order. This is
a selection of familiar tools, not an absolute popularity ranking.

| Application | Company / project | Local backup scope |
|---|---|---|
| Antigravity | Google | Conversation databases, hub index and local profile; native 2.x repair. |
| Augment Code | Augment Code | Candidate .augment data and detected editor extension profile. |
| Claude Code | Anthropic | Local .claude engine and Claude Desktop profile. |
| Cline | Cline | Local .cline data and detected extension editor profile. |
| Codex | OpenAI | Selected conversations, attachments, root indexes/databases and desktop profile; plugin caches excluded. |
| Continue | Continue | Local sessions in .continue and detected editor profile. |
| Cursor | SpaceX | Editor User profile and .cursor/projects. |
| GitHub Copilot | GitHub / Microsoft | VS Code built-in chat and complete editor User profile. |
| Kilo Code | Kilo | Current kilo.db engine, agent manager and detected legacy editor profile. |
| Kimi Code / Desktop | Moonshot AI | Local Desktop Work tasks and Code integration engines. |
| Kiro | AWS | Candidate Kiro User profile and .kiro folder. |
| OpenCode Desktop | Anomaly | Local opencode.db engine and desktop profile. |
| Qwen Code | Alibaba | Editor integration engine; .qwen projects and chats. |
| Roo Code | Roo Code Inc. | Existing local Roo Code extension histories and editor index. |
| Tabnine | Tabnine | Candidate local folders and detected extension profile. |
| Trae | ByteDance | Candidate global and Chinese edition User profiles. |
| Windsurf | Cognition | Local Cascade engine and editor User profile. |
| Xiaomi MiMo | Xiaomi | mimocode.db, desktop indexes and attachments. |
| ZCode | Z.ai | Local .zcode databases, rollouts, tasks and desktop profile. |
| Zed | Zed Industries | Windows local databases and Zed profile. |


[OpenCode](https://opencode.ai/) · [Official repository](https://github.com/anomalyco/opencode).
Candidate paths (especially Augment, Kiro, Tabnine and Trae) need review in Diagnostics.
Editor User snapshots can include other extensions/settings; the menu discloses this.
Full adapter evidence and limitations: [research](App/Docs/RESEARCH.md).

## AntiGravity repair

For this repair only, keep AntiGravity open and idle. The native module preserves
the current index, reads isolated SQLite conversation copies using the installed
engine, adds only missing IDs and checks persisted results. It does not generate
replies, rename existing entries or change their pins/archive states. Recovered
titles can be older; child agents can have separate databases. Unknown protocols
stop the repair. Other apps use snapshot restoration, not generic index reconstruction.
Repair artifacts in Backups/antigravity-reparos are not full application snapshots.

## Languages

**0 = Automatic; 1–15 = languages; Enter = return without changing the preference.**
English ASCII names are alphabetical: Arabic, Chinese (Simplified), Chinese
(Traditional), Dutch, English, French, German, Hindi, Italian, Japanese, Korean,
Portuguese (Brazil), Portuguese (Portugal), Russian and Spanish.

Automatic uses Windows display language, including separate pt-PT and Traditional
Chinese variants; unsupported languages fall back to English. Menus and instructions
are translated, while technical details and engine messages may keep their original
language. Font/shaping support depends on the terminal. Locale does not change backup
IDs, hashes or paths. Preferences are kept in App/Data/preferences.json.

## Maintenance and GitHub

App/Data and Backups are private and excluded by .gitignore. Publish only source and
documentation, never the working folder with user data. No upload is automatic.
Optional paths: App/Data/profiles.local.json; legacy configurations can be migrated.
Both README and AGENTS language versions must be updated together.

```powershell
.\AI-Chat-Vault.ps1 -Acao Listar -Idioma en
.\AI-Chat-Vault.ps1 -Acao Diagnostico -Aplicativo codex
.\AI-Chat-Vault.ps1 -Acao AutoTeste
.\App\Tests\Integration.ps1
.\App\Tests\CodexScope.ps1
```

[Validation](App/Docs/VALIDATION.md) · [Changes](App/Docs/CHANGELOG.md) · [Security](App/Docs/SECURITY.md)

## Inline progress and large profiles

Operations show the application name, action (backing up, restoring, verifying,
repairing or diagnosing), a small inline bar, current path and elapsed time.
Percentages describe the current phase, not an estimate of total remaining time:
discovery first counts files and shows `--%`; hashing then measures file progress,
including progress within a large file. Copying includes destination hash checks.
The bar can restart for another folder/phase; 100% during hashing is not a completed
backup. Only the final completion message with the backup directory marks success.
Failure/cancellation is labeled separately. Output redirection gets periodic plain
lines instead of cursor updates. No PowerShell overlay is used.

ZCode's full mapped folder may contain projects and node_modules. A read-only local
check found 73,062 workspace files (1.65 GiB), including 35,637 dependency files.
They are retained: this release does not silently discard project data. On a synthetic
1,000-file nested tree, inventory time fell from 21.38 s to 2.72 s with identical
hashes/entries (PowerShell 5.1). This is a local benchmark, not a whole-backup speed
guarantee. Direct .NET enumeration and attribute checks preserve reparse rejection,
full hashes, source rereads and destination checks. Slow USB drives and many small
files still take time. Esc cancels before commit; incomplete copies are not offered
for restore. Reopen the launcher to load an updated script; an already open window
continues running the earlier code.

The backup picker shows the current action (Restore, Verify, Extract or Safety return)
and application name. Enter the backup list number, not the application number.
For example, after choosing app 12 (OpenCode), its only backup is number 1. Invalid
numbers prompt again; 0 or empty Enter returns without restoring anything.
The picker asks “Choose an option”, without repeating a numerical range. Invalid
choices refer back to the visible list; cancellation explicitly confirms that no
operation started. The numbered backups and 0 (Back) remain visible.

The catalog footer separates the page counter from a short keyboard hint: Right/N
advances and Left/P returns. The displayed hint omits the parenthetical “no Enter”;
arrow-key navigation remains immediate.

The restore preview remains visible before any replacement: selected backup, local
data scope, affected directories and version warning. Choose 1 (Restore this backup) and press Enter
to apply, or 0 (Cancel) to return. Empty Enter also cancels; invalid input retries. This is a pre-restore confirmation, not the completion
of a backup. A verified safety snapshot is created before replacing current data.

Cursor's displayed parent company is SpaceX, according to its
[official acquisition announcement, August 14, 2026](https://cursor.com/blog/joining-spacex),
checked September 23, 2026. Local storage paths and backup compatibility are unchanged.

The restore choices are stacked and colored: green 1 Restore this backup, gray
0 Cancel. A short localized hint explains the safety backup. That automatic copy
preserves data from immediately before restoration and appears, once completed,
in the backup list and Tools > Return to the previous state. Wait for an active
restore to finish before reopening the launcher to load an updated version.

---

## 👤 About the Author

Developed and maintained by **Emerson Teles** (known in the community as **Emertels**).

Passionate about technology, PC hardware, gaming, system maintenance, and open software/emulator localization into Brazilian Portuguese (PT-BR).

### 🛠️ Notable Projects & Contributions:
- **Software & Utilities:** 100% Brazilian localization for **DSX** (DualSense X - Trusted Translator), **ASUS GPU Tweak III**, **dnGrep**, **XWidget**, and web utilities (**DualSense Tester**, **DualShock Tools**).
- **Emulation & Systems:** Contributor and localizer for systems and emulators including **PSBBN** (PlayStation Broadband Navigator for PS2), **PCSX2**, **Dolphin**, **shadPS4**, **Azahar**, and **RetroArch**.
- **Games & Apps:** Localization of **Silent Hill 5: Homecoming**, ongoing translation for **Silent Hill 4: The Room**, and various Android & PC applications.

---

### 🌐 Connect with me:

<div align="left">

[![GitHub](https://img.shields.io/badge/GitHub-Emertels-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emertels)
[![Discord](https://img.shields.io/badge/Discord-Emertels%20Server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/eRGFqQkvj)
[![X / Twitter](https://img.shields.io/badge/X_Twitter-@emertels-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/emertels)
[![YouTube](https://img.shields.io/badge/YouTube-Emerson_Teles-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@emersonteles2379)
[![Telegram](https://img.shields.io/badge/Telegram-Aplicativos%20Mods-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/apksmodsandroid)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20Project-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/emertels)

</div>

