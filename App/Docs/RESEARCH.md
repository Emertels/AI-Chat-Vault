# Adapter research — 2026-09-21

The original ten profiles are retained. This is a curated catalog, not a quantified
top-20 ranking. Local storage support and name recognition are distinct questions.
Paths below are candidates unless backed by source inspection or local evidence;
even verified file paths do not establish successful UI restoration in every version.

| Application | Evidence / primary source | Scope and limitation |
|---|---|---|
| Antigravity | Installed 2.15.1 engine, previous local recovery, isolated repair/restart tests. [Legacy fix](https://github.com/FutureisinPast/antigravity-conversation-fix) | Hub summaries differ from legacy state.vscdb. Native repair is specific to observed 2.x protocol. |
| Augment Code | [Official docs](https://docs.augmentcode.com/using-augment/chat) | .augment and editor extension storage are candidate paths. No complete-history or native import validation. |
| Claude Code | [Desktop docs](https://code.claude.com/docs/en/desktop), local engine and Desktop directories | Local histories can differ across Desktop, editor and remote sessions. |
| Cline | [Task management](https://docs.cline.bot/core-workflows/task-management), local .cline folders | Tasks and detected legacy extension host profile; no cloud export. |
| Codex | Local sessions, archived_sessions, JSONL index and state SQLite inspection; [official troubleshooting](https://developers.openai.com/codex/app/troubleshooting) | Version 4 selects conversation directories and root databases/indexes; plugin caches excluded; auth/config may be included. |
| Continue | [Source: storage paths](https://github.com/continuedev/continue/blob/main/core/util/paths.ts) | CONTINUE_GLOBAL_DIR or .continue; sessions and sessions.json. Detected editor profile keeps host state. |
| Cursor | [Vendor support](https://forum.cursor.com/t/where-are-cursor-chats-stored/77295), installed User/.cursor/projects paths | Local workspace association may depend on original project paths. |
| GitHub Copilot | [Microsoft session store](https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/chat/common/model/chatSessionStore.ts) | Host chatSessions and global state. External agents can store data elsewhere. |
| Kilo Code | [Official troubleshooting](https://kilo.ai/docs/getting-started/troubleshooting/troubleshooting-extension), [session history](https://kilo.ai/docs/code-with-ai/agents/session-history) | .local/share/kilo/kilo.db and sidecars; local history differs from cloud. Legacy extension profile retained when detected. |
| Kimi Code / Desktop | [Official downloads](https://www.kimi.com/en/products/download), local Desktop Work SQLite inspection | Work data and engine directories; cloud Chat is not downloaded. |
| Kiro | [IDE chat docs](https://kiro.dev/docs/ide/chat/) | Kiro/User and .kiro are candidates. Official history UI does not prove these folders contain every conversation. |
| OpenCode Desktop | [Website](https://opencode.ai/), [repository](https://github.com/anomalyco/opencode), [troubleshooting](https://opencode.ai/v2/docs/troubleshooting) | Engine .local/share/opencode, OPENCODE_DB override and observed desktop profile. Override maps the parent data folder. |
| Qwen Code | [Storage source](https://github.com/QwenLM/qwen-code/blob/main/packages/core/src/config/storage.ts), [VS Code integration](https://github.com/QwenLM/qwen-code/blob/main/docs/users/integration-vscode.md) | Local engine projects/chats; QWEN_RUNTIME_DIR then QWEN_HOME. Not a backup of Qwen web chats. |
| Roo Code | [Project issue on task indexes](https://github.com/RooCodeInc/Roo-Code/issues/11994) | Preserve task files plus host index. Existing local extension profile only; current website redirects to Roomote, whose cloud data is outside scope. |
| Tabnine | [Official conversation docs](https://docs.tabnine.com/main/getting-started/tabnine-chat/conversations) | Local paths are candidates; documentation of history UI is not validation of local backup completeness. |
| Trae | [Official product](https://www.trae.ai/) | Candidate global/Chinese User paths; no validated native index repair. |
| Windsurf | [Official troubleshooting](https://docs.windsurf.com/troubleshooting/windsurf-common-issues) | .codeium/windsurf/cascade documented; redirects/rebranding may affect future versions. |
| Xiaomi MiMo | [Desktop announcement](https://mimo.mi.com/docs/en-US/news/latest/mimo-desktop), local mimocode.db tables | Engine messages plus desktop attachment/artifact data; account information may be included. |
| ZCode | [Official install](https://zcode.z.ai/en/docs/install), local .zcode database/rollout inspection | Include engine and desktop profile together. Different selected models do not imply separate history apps. |
| Zed | [Windows](https://zed.dev/windows), [troubleshooting paths](https://zed.dev/docs/troubleshooting), [agent panel](https://zed.dev/docs/ai/agent-panel) | LocalAppData/Zed databases and profile; external agent persistence depends on integration. |

Extension task history can be split between extension files and host global state.
Full User snapshots preserve both but also cover unrelated settings/extensions; the
UI discloses this. Gate markers are specific extension storage folders, so merely
installing the host does not flag every extension. Renamed/new publisher IDs require
review or a custom path. VS Code's built-in chat is intentionally host-owned.

The prior Revo removal affected a shared .gemini directory used by another app.
This establishes the observed file loss, not Revo's internal matching algorithm.
[Revo manual](https://www.revouninstaller.com/online-manual/uninstaller/).
The vault maps Antigravity subfolders explicitly rather than claiming all of .gemini.

The legacy third-party fix was consulted to understand failure modes. Its executable
is not redistributed or executed. Native reconstruction uses the installed engine;
there is no affiliation with the listed vendors. The bilingual user guides summarize the supported scope.


## Version 4 — Codex junction failure

Read-only local inspection confirmed plugins/cache/openai-bundled/chrome/latest is
a junction to a versioned plugin cache. It is outside conversation scope. The selected
directories and desktop profile were scanned by metadata only (3,327 entries): no
reparse points were found there at inspection time. Root state, thread_history,
memories, queue and goals SQLite families were observed; discovery includes their
WAL/SHM companions rather than hardcoding one state database version.

The fix snapshots selected root files and directories independently and records
excluded top-level items. Restore validates the mapping, preserves current data first,
and never replaces plugins/caches. Synthetic tests reproduce a cache junction and
verify mixed file/directory recovery, including subsequent database files.

## 4.1 shutdown implementation — local evidence, 2026-09-22

Read-only process inspection found five OpenCode.exe processes and an orphan
opencode-cli.exe under ai.opencode.desktop/cli/2.0.14 after the visible window was
closed. The old guard only reported them. Processes.ps1 now handles explicit app
names, runtime entry points and descendants, and includes this OpenCode sidecar
even when reading an older saved profile. No actual user app was terminated for
development tests. This is process/file protection, not proof that every app can
open every restored database version.

The ZCode delay screenshot was in SHA-256 inventory, not completed backup. A shallow
layout inspection followed by metadata-only workspace enumeration confirmed embedded
projects and dependencies. The solution retains that declared full-folder scope and
reduces PowerShell provider overhead instead of assuming those paths are disposable.
Per-phase progress exposes discovery, hashing, copy/verification and current paths.

## Cursor company label — verified September 23, 2026

Cursor's [official announcement](https://cursor.com/blog/joining-spacex), dated
August 14, 2026, confirms completion of its acquisition by SpaceX. The catalog now
shows SpaceX as parent company. The website still identifies Anysphere, Inc. in its
legal footer; this is a parent-company presentation change, not a change to app
identity, data location or backup schema.
