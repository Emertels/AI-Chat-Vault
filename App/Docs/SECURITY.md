# Data safety

Cofre IA is an offline file backup tool with an optional local AntiGravity repair.
Profiles may contain tokens, personal conversations and account data. Do not attach
backups, native-engine logs or unredacted diagnostics to public issues.

Report reproducible problems with the tool version, Windows/PowerShell version and
synthetic examples. Remove usernames, paths, tokens and conversation content.
Do not run scripts or recovery executables from untrusted issue comments.

The tool does not encrypt backups. Store them on storage protected for your needs.
Hash verification detects accidental changes; it does not authenticate an untrusted
backup author. Restore only backups you trust, and review the destination preview.

Backup/restore can force-close the selected application, its child processes and
associated editor hosts. Save unsaved work first. Process handles and creation times
prevent targeting a reused PID; only the current Windows session/account is eligible.
The vault refuses to close its own ancestor chain. Unknown ownership, access denial
or a relaunching application aborts preparation. The tool does not elevate privileges.
