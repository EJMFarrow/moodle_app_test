# Publish this harness to GitHub

This repository tracks the setup harness only. It intentionally does not track
the Moodle, Moodle App, or STACK checkouts, Docker volumes, TLS certificate,
local `.env`, Android APKs, Gradle download, or VS Code/Codex home data.
Bootstrap recreates those items for each developer.

Before publishing, inspect the staged file list. It should contain only
`README.md`, `.env.example`, `.gitignore`, `compose.yaml`, `.vscode`, `docs`,
`infra`, and `scripts`.

```powershell
cd C:\MoodleApp
git status --ignored
git add README.md .env.example .gitignore .vscode compose.yaml docs infra scripts
git diff --cached --stat
git diff --cached -- . ':!*.md'
git commit -m "Add local STACK Moodle App test harness"
```

Create an empty GitHub repository without a README, licence, or `.gitignore`.
Then link and publish this local repository, replacing the placeholder with its
HTTPS or SSH URL:

```powershell
git branch -M main
git remote add origin https://github.com/YOUR-GITHUB-USER/YOUR-REPOSITORY.git
git push -u origin main
```

If `origin` is already configured, inspect it first and replace it only when
the URL is wrong:

```powershell
git remote -v
git remote set-url origin https://github.com/YOUR-GITHUB-USER/YOUR-REPOSITORY.git
git push -u origin main
```

Use a GitHub fine-grained personal access token when Git prompts for an HTTPS
password, or use an SSH remote after adding an SSH key to GitHub. Never put a
token in `.env`, documentation, or a commit.

After cloning the published harness on another Windows machine, follow the
[fresh-clone setup](local-stack-mobile-setup.md#fresh-clone-and-prerequisites).
Changes to STACK itself remain a separate Git repository at
`C:\MoodleApp\stack`; commit and push them from that checkout (or its remote
workbench path `/workspace/stack`).
