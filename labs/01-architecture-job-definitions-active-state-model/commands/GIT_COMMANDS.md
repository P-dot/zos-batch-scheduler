# Git Bash — Install and Publish Lab 01

The package is designed to be extracted from the Windows `Downloads` directory and copied into:

```text
C:\Carrera_Ciberseguridad\06_Portfolio_GitHub\zos-batch-scheduler
```

## Install from Downloads

```bash
cd /c/Users/user/Downloads
unzip -o zos-batch-scheduler-lab01.zip -d zos-batch-scheduler-lab01

cd /c/Carrera_Ciberseguridad/06_Portfolio_GitHub/zos-batch-scheduler

cp -r /c/Users/user/Downloads/zos-batch-scheduler-lab01/README.md .
mkdir -p labs
cp -r /c/Users/user/Downloads/zos-batch-scheduler-lab01/labs/01-architecture-job-definitions-active-state-model labs/
```

## Review

```bash
find . -maxdepth 4 -type f | sort
```

## Publication-safety check

Search text files for obvious private IPv4 addresses or MAC-address patterns:

```bash
grep -RInE '(^|[^0-9])(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})([^0-9]|$)|([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' . || true
```

Screenshots must also be visually reviewed because `grep` does not inspect pixels.

## Git status and remote

```bash
git status
git remote -v
```

The currently created GitHub repository is:

```text
https://github.com/P-dot/zos-bath-scheduler
```

If the remote is not configured:

```bash
git remote add origin https://github.com/P-dot/zos-bath-scheduler.git
```

If `origin` exists but points elsewhere:

```bash
git remote set-url origin https://github.com/P-dot/zos-bath-scheduler.git
```

## Commit and push

```bash
git add README.md labs/01-architecture-job-definitions-active-state-model
git status
git commit -m "Add Lab 01 scheduler architecture and active state model"
git branch -M main
git push -u origin main
```

## Optional repository rename

The local directory is `zos-batch-scheduler`, while the current GitHub repository is `zos-bath-scheduler`. If the GitHub repository is renamed to `zos-batch-scheduler`, update the remote:

```bash
git remote set-url origin https://github.com/P-dot/zos-batch-scheduler.git
git remote -v
git push -u origin main
```
