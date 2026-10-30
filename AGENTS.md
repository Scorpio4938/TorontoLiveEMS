## Agent skills

### Issue tracker

Issues live as GitHub issues in `Scorpio4938/TorontoLiveEMS`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles map 1:1 to label strings of the same name — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Versions

One number — `major.minor.checkpoint` — and the project's `MARKETING_VERSION`, the git tag, and
what Settings shows all carry it. At a checkpoint: bump the version, update the README's tag
table, run `python3 scripts/version_check.py`, then tag. See `docs/releasing.md`.

### Domain docs

Single-context. See `docs/agents/domain.md`.

### Git

Always push after committing.
