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
| `WORK_DIR` | Base directory for cloned workspaces | `~/.local/share/branx` |
| `REPOS[name]` | Repository aliases for quick access | (none) |

## License

GPL-3.0 - See [COPYING](COPYING) for details.
