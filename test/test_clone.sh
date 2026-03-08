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

assert_ne() {
	local unexpected="$1"
	local actual="$2"
	local message="$3"
	if [[ "$actual" == "$unexpected" ]]; then
		fail "$message: did not expect '$unexpected'"
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

write_config() {
	cat > "$config_file" <<EOF
WORK_DIR="$work_dir"
COPY_TO_CLIPBOARD=false
EOF

	if (($# > 0)); then
		printf 'GIT_FETCH=%s\n' "$1" >> "$config_file"
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

write_config

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

# advance upstream after source_repo was cloned so source_repo's origin refs stay stale
git -C "$seed_repo" checkout develop >/dev/null 2>&1
printf 'develop v2\n' > "$seed_repo/README.md"
git -C "$seed_repo" commit -am 'Advance develop upstream' >/dev/null
git -C "$seed_repo" push origin develop >/dev/null 2>&1
git -C "$seed_repo" checkout main >/dev/null 2>&1
printf 'main v2\n' > "$seed_repo/README.md"
git -C "$seed_repo" commit -am 'Advance main upstream' >/dev/null
git -C "$seed_repo" push origin main >/dev/null 2>&1

stale_develop_commit=$(git -C "$source_repo" rev-parse origin/develop)
stale_main_commit=$(git -C "$source_repo" rev-parse origin/main)
fresh_develop_commit=$(git --git-dir="$upstream_repo" rev-parse refs/heads/develop)
fresh_main_commit=$(git --git-dir="$upstream_repo" rev-parse refs/heads/main)
assert_ne "$stale_develop_commit" "$fresh_develop_commit" "stale develop ref check"
assert_ne "$stale_main_commit" "$fresh_main_commit" "stale main ref check"

# default GIT_FETCH=true should fetch updated upstream refs before branching
write_config
with_fetch_target_dir="$temp_dir/with-fetch-target"
with_fetch_output=$(run_branx clone "$source_repo" --source-branch develop --target-dir "$with_fetch_target_dir" --target-branch feature/with-fetch)
assert_contains "$with_fetch_output" "Cloned $source_repo to $with_fetch_target_dir" "with fetch output"
assert_path_exists "$with_fetch_target_dir/.git" "with fetch target dir"
assert_eq "feature/with-fetch" "$(git -C "$with_fetch_target_dir" branch --show-current)" "with fetch target branch"
assert_eq "$fresh_develop_commit" "$(git -C "$with_fetch_target_dir" rev-parse HEAD)" "with fetch HEAD"
assert_eq "$upstream_repo" "$(git -C "$with_fetch_target_dir" remote get-url origin)" "with fetch origin remote"
assert_eq "origin" "$(git -C "$with_fetch_target_dir" config --get 'branch.feature/with-fetch.remote')" "with fetch upstream remote"
assert_eq "refs/heads/develop" "$(git -C "$with_fetch_target_dir" config --get 'branch.feature/with-fetch.merge')" "with fetch upstream merge"

# GIT_FETCH=false should skip fetching and branch from cached source refs
write_config false
no_fetch_target_dir="$temp_dir/no-fetch-target"
no_fetch_output=$(run_branx clone "$source_repo" --source-branch develop --target-dir "$no_fetch_target_dir" --target-branch feature/no-fetch)
assert_contains "$no_fetch_output" "Cloned $source_repo to $no_fetch_target_dir" "no fetch output"
assert_path_exists "$no_fetch_target_dir/.git" "no fetch target dir"
assert_eq "feature/no-fetch" "$(git -C "$no_fetch_target_dir" branch --show-current)" "no fetch target branch"
assert_eq "$stale_develop_commit" "$(git -C "$no_fetch_target_dir" rev-parse HEAD)" "no fetch HEAD"
assert_ne "$fresh_develop_commit" "$(git -C "$no_fetch_target_dir" rev-parse HEAD)" "no fetch should avoid refreshed develop ref"
assert_eq "$upstream_repo" "$(git -C "$no_fetch_target_dir" remote get-url origin)" "no fetch origin remote"
assert_eq "origin" "$(git -C "$no_fetch_target_dir" config --get 'branch.feature/no-fetch.remote')" "no fetch upstream remote"
assert_eq "refs/heads/develop" "$(git -C "$no_fetch_target_dir" config --get 'branch.feature/no-fetch.merge')" "no fetch upstream merge"

# GIT_FETCH=false should also reuse cached origin/HEAD for the default branch
no_fetch_main_target_dir="$temp_dir/no-fetch-main-target"
no_fetch_main_output=$(run_branx clone "$source_repo" --target-dir "$no_fetch_main_target_dir" --target-branch main)
assert_contains "$no_fetch_main_output" "Cloned $source_repo to $no_fetch_main_target_dir" "no fetch main output"
assert_path_exists "$no_fetch_main_target_dir/.git" "no fetch main target dir"
assert_eq "main" "$(git -C "$no_fetch_main_target_dir" branch --show-current)" "no fetch main target branch"
assert_eq "$stale_main_commit" "$(git -C "$no_fetch_main_target_dir" rev-parse HEAD)" "no fetch main HEAD"
assert_ne "$fresh_main_commit" "$(git -C "$no_fetch_main_target_dir" rev-parse HEAD)" "no fetch should avoid refreshed main ref"
assert_eq "$upstream_repo" "$(git -C "$no_fetch_main_target_dir" remote get-url origin)" "no fetch main origin remote"
assert_eq "origin" "$(git -C "$no_fetch_main_target_dir" config --get 'branch.main.remote')" "no fetch main upstream remote"
assert_eq "refs/heads/main" "$(git -C "$no_fetch_main_target_dir" config --get 'branch.main.merge')" "no fetch main upstream merge"

echo "PASS: clone switch parsing, branch handling, and optional fetch"
