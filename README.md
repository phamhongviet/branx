# branx

A simple bash tool for creating isolated git workspaces with randomly generated branch names.

## Overview

`branx` clones a git repository into a unique directory and creates a new branch with a randomly generated name (plant-based names like `oak-42`, `bamboo-71`, `jasmine-33`). This is useful for quickly spinning up isolated environments for experiments, features, or reviews without polluting your main working directory.

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
   REPOS[myrepo]="$HOME/code/myrepo/"
   REPOS[myproject]="https://github.com/myuser/myproject.git"
   WORK_DIR="$HOME/.local/share/branx"
   EOF
   ```

## Usage

```bash
branx clone <repo>
```

Where `<repo>` can be:
- A local directory path (e.g., `~/projects/myapp`)
- A remote git URL (e.g., `https://github.com/user/repo.git`)
- A configured alias from your config file

### Examples

Clone from a remote repository:
```bash
branx clone https://github.com/user/project.git
# Creates: ~/.local/share/branx/project/fern-47/
```

Clone from a local directory:
```bash
branx clone ~/code/myproject
# Creates: ~/.local/share/branx/myproject/willow-23/
```

Clone using a configured alias:
```bash
branx clone myrepo
# Creates: ~/.local/share/branx/myrepo/basil-85/
```

## How It Works

1. Clones the specified repository to `$WORK_DIR/<repo-name>/<random-branch>/`
2. If cloning from a local directory, reconfigures the origin remote to point to the original upstream
3. Creates and switches to a new branch with a randomly generated plant-based name
4. The new branch is based on `origin/HEAD` when available

## Configuration

Create `~/.config/branx/env` to customize behavior:

| Variable | Description | Default |
|----------|-------------|---------|
| `WORK_DIR` | Base directory for cloned workspaces | `~/.local/share/branx` |
| `REPOS[name]` | Repository aliases for quick access | (none) |

## License

GPL-3.0 - See [COPYING](COPYING) for details.
