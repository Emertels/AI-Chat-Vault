# AI Chat Vault — maintenance

Updated 2026-09-23, version 4.1.4. [Português](AGENTS.pt-BR.md).

- Keep README.md, README.pt-BR.md, AGENTS.md and AGENTS.pt-BR.md synchronized.
- Preserve the 20 existing app profiles. Alphabetical catalog, company, description,
  colors and data status; two pages of ten; immediate Right/Left arrow navigation without Enter; N/P
  compatibility and global numeric selection confirmed with Enter. Preserve Backspace,
  Esc and line-input fallback for redirected input/non-console hosts.
- Preserve all 15 locales. Names are ASCII English, alphabetical; 0 is Automatic,
  1–15 select languages and Enter returns. Other instructions stay localized.
- Respect CODEX_HOME and configured paths. Data presence is not proof of installation.
- Start AI Chat Vault.cmd and AI-Chat-Vault.ps1 are the public entry points.
  Technical files belong in App, private settings/logs in App/Data, backups in Backups.
- Do not accumulate Archive folders or release ZIPs in the installation. For edits,
  stage and preserve the previous source outside this project temporarily. The owner
  authorized removing old code archives, duplicate releases and obsolete test logs.
- Never delete conversation backups, safety copies or recovery journals as cleanup.
- Codex scope must explicitly include conversation folders and root indexes/databases.
  Plugin/cache exclusions must be recorded in the manifest, disclosed, and left
  untouched on restore. Do not simply skip arbitrary links or SQLite WAL/SHM files.
- Schema 2 scoped units must validate parent key, relative filename, stable unit key
  and file/directory type before any write. Reject traversal and data reparse points.
- Preserve safety snapshots and transaction rollback for files and directories,
  including originally absent sidecars and databases created after the snapshot.
- Continue reading schema-1 snapshots/journals. Do not silently narrow old full backups.
- Native AntiGravity repair must preserve existing titles, pins and archive states,
  add only missing IDs, keep original copies and verify persistence. It is not generic
  index repair for the other apps. Cloud-only data is outside this tool's scope.
- Never restore live app data for tests. Use synthetic fixtures or isolated copies;
  real installation inspection is read only. Keep app-closed and single-instance guards.
- Before backup/restore/recovery, close the selected app tree automatically, then force
  survivors. Never make mid-copy guards terminate processes. Keep native AntiGravity
  repair open/idle and diagnostics read-only. Protect the vault ancestor chain, other
  sessions/accounts, and reused PIDs. Match runtime entry points, not prompt text.
- Keep Backups/<stable-app-id>/<snapshot-id> portable; discover completed snapshots
  and resolve restore destinations from current profiles. Preserve legacy metadata.
- Test Windows PowerShell 5.1 and 7, including App/Tests/Integration.ps1, CodexScope.ps1
  Processes.ps1 and built-in self-tests. PS1 files require UTF-8 BOM. Check locale keys/placeholders.
- Native behavior changes require isolated-engine/restart validation. Document actual
  evidence and limits in App/Docs/VALIDATION.md and RESEARCH.md.
- Publish only allowlisted source/docs. Exclude Backups and App/Data; never publish
  private recovery fixtures, account files or conversation contents.

- Keep operation progress inline via App/Progress.ps1; no Write-Progress overlay.
  Percentages must be measured per phase; unknown totals remain indeterminate.
  Preserve terminal width handling, elapsed time, file paths, output return values,
  redirection fallback, and distinct failure/cancellation versus completion.
- Maintain direct .NET enumeration/ancestor attribute checks with fail-closed link
  handling. Do not remove hashes or silently exclude projects to improve speed.
  App/Tests/Progress.ps1 covers renderer calculations and operation state cleanup.

- Snapshot pickers must show their actual action and app name, never the Create
  backup prompt. Keep backup numbering distinct from app numbering; retry invalid
  choices and preserve 0/empty-Enter cancellation. Localize all 15 catalogs.
- Picker prompt: “Choose an option”, without numeric ranges. Invalid input refers
  to the visible list; cancellation must state that no operation started.

- Catalog footer: separate localized page/page_hint strings. Keep the keyboard
  arrow directions and N/P aliases explicit; omit “no Enter” from the visible hint.

- Preserve the complete restore preview with two localized confirmation choices:
  1 Restore this backup; 0 Cancel. Empty Enter cancels; invalid choices retry.
  Do not require typing RESTAURAR. Apply this shared flow to all 20 profiles/15 locales.
- Cursor display company: SpaceX, verified via the official August 14, 2026 announcement
  (https://cursor.com/blog/joining-spacex), checked September 23, 2026. This presentation
  change must not rename app IDs, paths or backup folders.

- Restore confirmation uses green 1 / gray 0 on separate lines and a cyan localized
  safety-backup hint. Keep the full paths/scope preview. Do not auto-select a newer
  snapshot than the one explicitly chosen by the user.

- Keep the README folder guide synchronized with actual layout, including numbered
  `_transactions` restore journals, per-app snapshots, `.incompleto`, `dados`,
  Exports, AntiGravity repair subfolders, App/Data/Logs and adjacent `.cofre-*` files.
  Explain that journals are not transcripts or full safety snapshots; completed
  journals remain by design. Never remove them as generic cleanup, and keep them
  outside publication. Do not promise automated cleanup that is not implemented.

- Maintain App/Docs/FILES.md and FILES.pt-BR.md whenever program files are added,
  moved or removed. List all source/docs/test/locale files individually and describe
  generated private outputs by pattern, never by exposing actual user filenames.
- An explicit owner-requested publication reset may remove local backup copies and
  logs only after verifying no active operation or pending recovery. Preserve local
  configuration and all program files. This is not authorization for routine backup
  deletion; never extend cleanup into application data outside this project.
