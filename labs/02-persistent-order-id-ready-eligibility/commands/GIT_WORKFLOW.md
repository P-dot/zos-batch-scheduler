# Git Workflow — Lab 02 Parts 1-2

Recommended branch:

```text
lab/02-persistent-order-id-ready-eligibility
```

Recommended commit:

```text
lab02: add persistent order IDs and READY eligibility
```

Recommended PR title:

```text
Lab 02: Persistent Order-ID and READY eligibility
```

## Workflow

Run from the local repository root.

```bash
git checkout main
git pull --ff-only origin main

git checkout -b lab/02-persistent-order-id-ready-eligibility

git status

git add README.md
git add labs/02-persistent-order-id-ready-eligibility

git status

git commit -m "lab02: add persistent order IDs and READY eligibility"

git push -u origin lab/02-persistent-order-id-ready-eligibility

gh pr create \
  --base main \
  --head lab/02-persistent-order-id-ready-eligibility \
  --title "Lab 02: Persistent Order-ID and READY eligibility" \
  --body-file labs/02-persistent-order-id-ready-eligibility/docs/PULL_REQUEST.md

gh pr view --web
```

After review:

```bash
gh pr checks

gh pr merge --merge --delete-branch

git checkout main
git pull --ff-only origin main

git status
git log --oneline -5
```
