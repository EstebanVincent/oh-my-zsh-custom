# oh-my-zsh custom

Personal [oh-my-zsh](https://ohmyz.sh) customizations. Every `*.zsh` file in this folder is sourced
automatically by oh-my-zsh.

## Setup

```sh
git clone https://github.com/EstebanVincent/oh-my-zsh-custom.git "$ZSH_CUSTOM"
```

Enable the plugin in `~/.zshrc`:

```sh
plugins=(... copilot)
```

## Requirements

| Tool                  | Used by                                                         |
| --------------------- | --------------------------------------------------------------- |
| `git`                 | `git.zsh`, `gitflow.zsh`                                        |
| `gh`                  | `gitflow.zsh` (GitHub remotes)                                  |
| `az`, `jq`            | `gitflow.zsh` (Azure DevOps remotes), `azure.zsh`, `docker.zsh` |
| `copilot` CLI         | `gitflow.zsh`, `copilot` plugin                                 |
| `docker` (+ `buildx`) | `docker.zsh`                                                    |
| `terraform`           | `terraform.zsh`                                                 |
| `uv`, `python3.x`     | `python.zsh`                                                    |
| `kubectl`             | `kubernetes.zsh`                                                |
| `fzf`                 | `general.zsh`                                                   |

## Files

| File              | Content                                                               |
| ----------------- | --------------------------------------------------------------------- |
| `git.zsh`         | Git aliases and helpers (`pushup`, `rbin`, `mrin`, `prunelocal`, ...) |
| `gitflow.zsh`     | Branch flows with AI-generated PRs (see below)                        |
| `docker.zsh`      | `dbuild`, `dacr`, `drun`, `dex`, compose aliases                      |
| `terraform.zsh`   | `tf*` aliases, `tfp`/`tfa`/`tfd` with `.tfvars` files                 |
| `python.zsh`      | `mkv`/`mkuv` venv creation in `~/PythonVenvs`, `uv`/`pip` aliases     |
| `azure.zsh`       | `azl`, `kv2env` (Key Vault secrets to env file)                       |
| `kubernetes.zsh`  | `k`, `kgp`, `kga`, `kdp`, `kex`                                       |
| `general.zsh`     | `c`, `ssha`, fuzzy history search on `Ctrl+R`                         |
| `nocorrect.zsh`   | Disable zsh autocorrect for selected commands                         |
| `plugins/copilot` | `:` prefix to talk to the Copilot CLI from the prompt                 |

## Git flows

`gitflow.zsh` provides start/end commands for each branching model. `end` pushes the branch, asks the Copilot
CLI for a PR title and description, then opens the PR(s).

| Command                             | Start from         | `end` opens PR into |
| ----------------------------------- | ------------------ | ------------------- |
| `gff start\|end [name] [remote]`    | develop            | develop             |
| `gtf start\|end [name] [remote]`    | main (trunk-based) | main                |
| `gfr start\|end <version> [remote]` | develop            | main and develop    |
| `gfh start\|end <name> [remote]`    | main               | main and develop    |

The PR tool depends on the remote URL:

- URL contains `github`: `gh pr create`, then opens the PR in the browser. If `gh` is not logged in, you are
  prompted to run `gh auth login`.
- Otherwise: `az repos pr create` (Azure DevOps SSH alias format `alias:v3/ORG/PROJECT/REPO`).

## Copilot plugin

Type a line starting with `:` and press Enter.

| Input            | Action                                                    |
| ---------------- | --------------------------------------------------------- |
| `: <prompt>`     | Send prompt to Copilot                                    |
| `:commit`        | Generate a commit message from the staged diff and commit |
| `:yolo <prompt>` | Run with all tools allowed                                |
| `:resume [id]`   | Resume last or given session                              |
| `:plan <prompt>` | Ask Copilot to plan                                       |
| `:help`          | List commands                                             |

Set `COPILOT_BIN` to override the `copilot` binary.
