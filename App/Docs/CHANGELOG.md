# 4.1.4 — Cursor attribution and restore confirmation

- Display Cursor (SpaceX), based on Cursor's official acquisition announcement.
- Keep the complete restore preview; replace the typed RESTAURAR token with
  localized 1 Restore this backup / 0 Cancel options. Empty Enter cancels and
  invalid choices retry. Safety snapshots, transactional writes and paths unchanged.
- Update both README and AGENTS languages and record the source in RESEARCH.md.

# 4.1.3 — simpler backup picker wording

- Use “Choose an option” for every application’s backup picker, including restore.
- Remove redundant numeric ranges; invalid input refers to the visible list.
- Keep numbered snapshots, 0 Back, retry and cancellation behavior unchanged.
- Update all 15 locales and bilingual README/AGENTS.

# 4.1.2 — catalog footer polish

- Separate page count and a concise keyboard-arrow/N/P hint in all 15 locales.
- Removed the parenthetical no-Enter wording; navigation behavior is unchanged.
- Updated README and AGENTS in English and Brazilian Portuguese.

# 4.1.1 — immediate arrow-key paging

- Right/Left arrows switch application pages without Enter. N/P remain aliases.
- Numeric 1–20 selection still uses Enter; Backspace edits and Esc returns.
- Redirected/non-console input retains line-based navigation. Updated all 15 hints
  and both README/AGENTS language versions. Backup and restore logic unchanged.

# 4.1.0 — automatic application shutdown

- Graceful close followed by forced termination of the selected app tree before
  backup, restore and recovery; detect orphan OpenCode CLI sidecars.
- Verify shutdown before reading data; keep reappearance checks read-only.
- Same-session/account enforcement, ancestor protection and creation-time checks
  against PID reuse; runtime matching ignores prompt arguments.
- Localized progress in all 15 languages. Two pages of ten and portable per-app
  Backups layout unchanged. Native AntiGravity repair remains open and idle.

# Changelog

## 4.0.0 — 2026-09-22

- Rename the launcher to Start AI Chat Vault.cmd and the main script to AI-Chat-Vault.ps1.
- Consolidate technical files under App; private runtime data under App/Data;
  recovery journals and exports stay inside Backups. Remove obsolete archives/releases.
- Codex conversation scope excludes plugin-cache junctions; selected root SQLite,
  WAL/SHM and metadata files use typed snapshot units with explicit exclusion records.
- Scoped restore preserves excluded caches, current-data safety copies and rollback;
  schema-1 backups remain supported. Scoped schema-2 snapshots require version 4+.
- Restore two application pages of ten entries while keeping all descriptions/colors.


## 3.1.0 — 2026-09-22

- Expand to 15 interface locales: add Portuguese (Portugal), Arabic, Dutch,
  Traditional Chinese and Hindi; preserve existing saved locale IDs.
- Language selector: Automatic at 0, alphabetical English language names at 1–15,
  Enter to return. Distinguish pt-PT and Traditional Chinese Windows display locales.
- Includes the single-list application selector from 3.0.2.
- Preserve the documented Diagnostico command alias alongside Diagnostics.

## 3.0.2 — 2026-09-21

- Show all 20 applications in a single alphabetical list without pagination.
- Preserve descriptions, company names, colors, data status and numeric selection.

## 3.0.1 — 2026-09-21

- Language selector names now use alphabetically sorted ASCII English labels.
- Automatic selection, Back and surrounding interface text remain localized.
- Locale IDs and saved preferences remain compatible.

## 3.0.0 — 2026-09-21

- Retains the original ten apps and adds Augment Code, Cline, Continue, Kilo Code,
  Kiro, OpenCode Desktop, Qwen Code, Roo Code, Tabnine and Zed.
- Alphabetical colored catalog with company, description, local-data status and paging.
- Ten interface locales, Windows display-language detection and persistent selection.
- Extension-aware detection, v2 custom-profile migration and unchanged snapshot schema.
- Actionable locked-file messages without skipping SQLite sidecars.
- English folder layout, bilingual README/AGENTS and private-data publication exclusions.
- AntiGravity native recovery preserved and revalidated against an isolated 2.15.1 engine.

## 2.0.0 — 2026-09-21

- Modular snapshot backup, SHA-256 verification, staged restore, safety snapshots,
  recoverable transaction journal and native AntiGravity 2.x missing-ID reconstruction.

### 4.1 inline operation display and inventory performance

- Replaced the PowerShell overlay with compact inline action/phase progress, elapsed
  time, current path and measured per-phase percentages. Counts remain indeterminate
  until discovery is complete; cancellation and failure cannot report success.
- Applied display to backup, restore, recovery, verification, extraction, diagnostics
  and native repair without changing native RPC/write semantics.
- Direct .NET file enumeration and ancestor attribute checks reduce provider overhead;
  reuse the synchronous hash buffer. Full hashes, source rereads and link rejection
  remain. Large ZCode projects/dependencies are retained, not silently excluded.

### 4.1.1 backup selection clarity

- Correct action header and app name on restore/verify/extract/safety pickers.
- Dedicated localized backup-number prompt with valid range and retry on invalid input.
