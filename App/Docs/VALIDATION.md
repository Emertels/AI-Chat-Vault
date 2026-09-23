# AI Chat Vault 4.1 — validation

Windows, 2026-09-22. No live application data was restored for these tests.

The generic suite passed on PowerShell 5.1 and 7.6.5. The scoped Codex suite passed
on both runtimes, including injected rollback after file and directory changes.
A genuine schema-1 snapshot made with the previous 3.1.0 code was also restored
successfully with version 4.0.0. Source parsing and two-page selection were checked.

- Built-in eight-group synthetic tests cover hashes, Unicode, empty directories,
  restore, safety return, wrong-app rejection, injected rollback, absent roots,
  corruption and hostile relative paths.
- Integration suite covers all 20 profiles and 15 locale catalogs, matching keys
  and placeholders, language preferences, display-language mapping, profile migration,
  extension gates, moving the program, cross-language restore and locked-file failure.
- CodexScope reproduces a junction in excluded plugins/cache pointing at an external
  sentinel. It verifies schema-2 root files and conversations, explicit exclusions,
  preserving the cache target, restoring absent WAL and subsequent databases, safety
  undo, injected mixed file/directory rollback, and refusal of links inside selected
  data plus malicious mapping paths. Runs use temporary fixture directories.
- Source inspection of the installed Codex was read-only; the process guard detects
  its running process. A real backup requires closing Codex outside this task first.
- UI: two pages of ten, global numbering 1–20, descriptions/colors and localized
  navigation. Language menu remains 0 Automatic, 1–15 English names and Enter back.
- Native AntiGravity logic was not changed. Prior isolated-engine tests on 2.15.1
  verified missing-entry recovery, title preservation, idempotence and persistence
  after engine restart. No new live repair was run for the packaging/scoping change.

## Reproduce

Use both Windows PowerShell 5.1 and PowerShell 7:

```powershell
.\AI-Chat-Vault.ps1 -Acao AutoTeste
.\App\Tests\Integration.ps1
.\App\Tests\CodexScope.ps1
.\App\Tests\Processes.ps1
```

Synthetic test fixtures remain in the system temporary directory for inspection.
All 20 applications have not been restored through their real interfaces. Candidate
paths, cloud exclusions and version compatibility limits remain documented in research.
Translation catalogs have not undergone native-speaker review; complex script display
depends on the terminal. Byte hashes do not establish app-level compatibility.

## 4.1 process preparation

Processes.ps1 tests all 20 profile trees with synthetic process records, orphan
OpenCode sidecar detection, runtime entry points versus prompt arguments, orphan
children, reused parent IDs, session isolation and vault ancestor protection.
A compiled disposable Windows helper and its child ignore graceful close and must
be forcibly terminated before backup and before restore. Creation-time mismatch
must leave the process alive; read-only reappearance guards must also leave it alive.
These tests never close real user applications or restore their live data.

## 4.1 inline display and performance

Progress.ps1 tests measured percentages, unknown totals, elapsed time, bounds,
wide text clipping, preserving function output, cancellation and exception cleanup.
Both PowerShell 5.1 and 7 are used. Inventory, copy, source reread, restore/rollback,
malicious paths, link refusal and locked files remain in the existing regression suites.
The process fixture suite also exercises the new wrappers with real disposable helper
processes; it does not terminate any real user application.

A nested synthetic 1,000-file tree produced identical sorted inventories/hashes in
the installed v4.0 and staged v4.1: 21.38 s versus 2.72 s on PowerShell 5.1. This does
not measure an entire backup or imply a guarantee on other disks. A metadata-only
scan of the actual ZCode workspace found 73,062 files / 1.65 GiB, including 35,637
node_modules files. No ZCode data was modified or omitted. Native repair changes are
display-only; the underlying repair behavior was not retested against the live app.

```powershell
.\App\Tests\Progress.ps1
```

## 4.1.1 navigation and picker validation

- Real ConPTY input in PowerShell 7 confirmed Right/Left keys without Enter, two-digit
  editing with Backspace, and Esc return. In Windows PowerShell 5.1, the full catalog
  navigated 1 -> 2 -> 1 -> 2 immediately and numeric 20 + Enter selected Zed.
- Integration, scoped Codex and built-in regression suites passed on both runtimes.
- The picker uses a dedicated backup-number prompt and contextual action header;
  invalid numbers retry instead of returning to the previous screen. No real backup
  was restored as part of UI testing.

## 4.1.4 restore confirmation and company label

The company label was checked against Cursor's August 14, 2026 acquisition
announcement on its official website. Profile IDs, roots and snapshot schemas
are unchanged. Restore preview details remain in place.

Confirmation now uses a shared 1 Restore this backup / 0 Cancel menu, with a
localized safety-backup hint across all 15 languages. Manual simulated inputs
verified invalid choices retry, 1 applies and 0/empty Enter cancel. A real ConPTY
Windows PowerShell 5.1 check displayed the cyan hint, green restore option and
gray cancel option; entering 1 returned True without invoking any live restore.
The disposable process/restore suite uses numeric confirmation; the full data
regression suites continue to operate only on synthetic fixtures.