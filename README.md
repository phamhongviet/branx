# branx

A simple bash script that clones a git repository and creates a new branch with a randomly generated plant-based name (like `oak-mint`, `bamboo-sage`, `jasmine-thyme`).

The script is short and readable—[take a look](branx).

## Installation

1. Copy `branx` to a directory in your PATH:
   ```bash
   cp branx ~/.local/bin/
   chmod +x ~/.local/bin/branx
   ```

2. (Optional) Create a config file at `~/.config/branx/env` to define repository aliases and customize the work directory:
   ```bash
   mkdir -p ~/.config/branx
   cat > ~/.config/branx/env << 'EOF'
   WORK_DIR="$HOME/workspaces"

   work_dir_rule "/Codes/org-1/*" "/WorkSpaces/org-1"
   work_dir_rule "/Codes/org-2/*" "/WorkSpaces/org-2"

   REPOS[myrepo]="$HOME/code/myrepo/"
   REPOS[myproject]="https://github.com/myuser/myproject.git"
   EOF
   ```

   By default, `branx` loads `~/.config/branx/env` if it exists. You can override
   the config path by setting `BRANX_CONFIG_FILE` before running `branx`:
   ```bash
   BRANX_CONFIG_FILE=/etc/branx/env branx clone myrepo
   ```

   If `BRANX_CONFIG_FILE` is set, the file must exist and be readable or `branx`
   exits with an error. If the default config file is missing, `branx` continues
   with built-in defaults.

## Usage

```bash
branx clone <repo> [branch]
branx random
```

Where:
- `<repo>` can be:
  - A local directory path (e.g., `~/projects/myapp`)
  - A remote git URL (e.g., `https://github.com/user/repo.git`)
  - A configured alias from your config file
- `[branch]` (optional) specifies the base branch to create your new branch from (e.g., `develop`, `feature/main`)

### Examples

Generate a random branch name only:
```bash
branx random
# Prints: oak-mint
```

Clone from a remote repository:
```bash
branx clone https://github.com/user/project.git
# Creates: ~/.local/share/branx/project/fern-sage/
```

Clone from a local directory:
```bash
branx clone ~/code/myproject
# Creates: ~/.local/share/branx/myproject/willow-thyme/
```

Clone using a configured alias:
```bash
branx clone myrepo
# Creates: ~/.local/share/branx/myrepo/basil-cedar/
```

Clone from a specific base branch:
```bash
branx clone myrepo develop
# Creates: ~/.local/share/branx/myrepo/maple-olive/ branched from origin/develop
```

## Configuration

Create `~/.config/branx/env` to customize behavior:

| Variable | Description | Default |
|----------|-------------|---------|
| `WORK_DIR` | Base directory for cloned workspaces when no rule matches | `~/.local/share/branx` |
| `GIT_FETCH` | Whether to run `git fetch origin` after cloning from a local repo path that has an upstream `origin` remote | `true` |
| `REPOS[name]` | Repository aliases for quick access | (none) |

To skip the fetch step for local clones, set:

```bash
GIT_FETCH=false
```

When disabled, `branx` still repoints `origin` to the source repository's upstream URL, but it creates the new branch from the already-available `origin/...` refs copied from the local source clone.

You can also declare ordered workspace routing rules in the config file:

```bash
work_dir_rule "/Codes/org-1/*" "/WorkSpaces/org-1"
work_dir_rule "/Codes/org-2/*" "/WorkSpaces/org-2"
work_dir_rule "/Codes/org-3/*" "/Work-for-org-3"
```

Rules are evaluated in declaration order against the resolved repo value after
`REPOS[...]` alias expansion. The first match wins. If no rule matches, `branx`
uses `WORK_DIR`.

For example:

- `/Codes/org-1/infra` → `/WorkSpaces/org-1/infra/<branch>`
- `/Codes/org-2/infra` → `/WorkSpaces/org-2/infra/<branch>`
- `/Codes/org-3/guardrails` → `/Work-for-org-3/guardrails/<branch>`

## License

GPL-3.0 - See [COPYING](COPYING) for details.
