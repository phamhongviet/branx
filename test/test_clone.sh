#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
branx_script="$repo_root/branx"

author_name='Branx Tests'
author_email='branx@example.com'

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

assert_eq() {
	local expected="$1"
	local actual="$2"
	local message="$3"
	if [[ "$actual" != "$expected" ]]; then
		fail "$message: expected '$expected', got '$actual'"
	fi
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	local message="$3"
	if [[ "$haystack" != *"$needle"* ]]; then
		fail "$message: missing '$needle'"
	fi
}

assert_path_exists() {
	local path="$1"
	local message="$2"
	if [[ ! -e "$path" ]]; then
		fail "$message: missing '$path'"
	fi
}

run_branx() {
	BRANX_CONFIG_FILE="$config_file" bash "$branx_script" "$@" 2>&1
}

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

upstream_repo="$temp_dir/upstream.git"
seed_repo="$temp_dir/seed-repo"
source_repo="$temp_dir/source-repo"
work_dir="$temp_dir/workspaces"
config_file="$temp_dir/branx-env"

git init --bare "$upstream_repo" >/dev/null 2>&1

git init "$seed_repo" >/dev/null 2>&1
git -C "$seed_repo" checkout -b main >/dev/null 2>&1
git -C "$seed_repo" config user.name "$author_name"
git -C "$seed_repo" config user.email "$author_email"
printf 'main\n' > "$seed_repo/README.md"
git -C "$seed_repo" add README.md
git -C "$seed_repo" commit -m 'Initial commit on main' >/dev/null
git -C "$seed_repo" checkout -b develop >/dev/null 2>&1
printf 'develop\n' > "$seed_repo/README.md"
git -C "$seed_repo" commit -am 'Commit on develop' >/dev/null
git -C "$seed_repo" remote add origin "$upstream_repo"
git -C "$seed_repo" push -u origin main develop >/dev/null 2>&1
git --git-dir="$upstream_repo" symbolic-ref HEAD refs/heads/main
git -C "$seed_repo" checkout main >/dev/null 2>&1

git clone "$upstream_repo" "$source_repo" >/dev/null 2>&1

cat > "$config_file" <<EOF
WORK_DIR="$work_dir"
COPY_TO_CLIPBOARD=false
EOF

# clone with switches, source branch, and a target branch containing a slash
default_target_dir="$work_dir/$(basename "$source_repo")/feature/from-develop"
default_output=$(run_branx clone "$source_repo" --source-branch develop --target-branch feature/from-develop)
assert_contains "$default_output" "Cloned $source_repo to $default_target_dir" "default clone output"
assert_path_exists "$default_target_dir/.git" "default target dir"
assert_eq "feature/from-develop" "$(git -C "$default_target_dir" branch --show-current)" "default target branch"
assert_eq "$(git -C "$source_repo" rev-parse origin/develop)" "$(git -C "$default_target_dir" rev-parse HEAD)" "default clone HEAD"
assert_eq "$upstream_repo" "$(git -C "$default_target_dir" remote get-url origin)" "default clone origin remote"

# clone with an explicit target dir and target branch
custom_target_dir="$temp_dir/custom/location/clone-target"
custom_output=$(run_branx clone "$source_repo" --source-branch develop --target-dir "$custom_target_dir" --target-branch release-candidate)
assert_contains "$custom_output" "Cloned $source_repo to $custom_target_dir" "custom target dir output"
assert_path_exists "$custom_target_dir/.git" "custom target dir"
assert_eq "release-candidate" "$(git -C "$custom_target_dir" branch --show-current)" "custom target branch"
assert_eq "$(git -C "$source_repo" rev-parse origin/develop)" "$(git -C "$custom_target_dir" rev-parse HEAD)" "custom clone HEAD"
assert_eq "$upstream_repo" "$(git -C "$custom_target_dir" remote get-url origin)" "custom clone origin remote"

# clone into an explicit dir while keeping the existing default branch name
main_target_dir="$temp_dir/main-branch-target"
main_output=$(run_branx clone "$source_repo" --target-dir "$main_target_dir" --target-branch main)
assert_contains "$main_output" "Cloned $source_repo to $main_target_dir" "main branch clone output"
assert_path_exists "$main_target_dir/.git" "main target dir"
assert_eq "main" "$(git -C "$main_target_dir" branch --show-current)" "main target branch"
assert_eq "$(git -C "$source_repo" rev-parse origin/main)" "$(git -C "$main_target_dir" rev-parse HEAD)" "main clone HEAD"
assert_eq "$upstream_repo" "$(git -C "$main_target_dir" remote get-url origin)" "main clone origin remote"

# legacy positional branch syntax should now fail
set +e
legacy_output=$(BRANX_CONFIG_FILE="$config_file" bash "$branx_script" clone "$source_repo" develop 2>&1)
legacy_status=$?
set -e
if [[ $legacy_status -eq 0 ]]; then
	fail "legacy positional branch syntax should fail"
fi
assert_contains "$legacy_output" "Error: unexpected positional argument: develop" "legacy positional syntax error"
assert_contains "$legacy_output" "clone <repo> [--source-branch <branch>] [--target-dir <dir>] [--target-branch <branch>]" "legacy positional syntax usage"

echo "PASS: clone switch parsing and branch handling"
