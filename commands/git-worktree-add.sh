#!/bin/bash
# git-worktree-add - Create a git worktree and cd into it
#
# Usage:
#   git-worktree-add <folderName> <branchName>
#
# Examples:
#   git-worktree-add integrator-2589 feat/itgd-2589
#   git-worktree-add hotfix-auth fix/auth-token-expiry

function git-worktree-add() {
  function _show_help() {
    echo "git-worktree-add - Create a git worktree forked from current branch and cd into it"
    echo ""
    echo "Usage:"
    echo "  git-worktree-add <folderName> <branchName>"
    echo ""
    echo "Arguments:"
    echo "  folderName   Name of the worktree directory (created as ../folderName)"
    echo "  branchName   Name of the new branch to create"
    echo ""
    echo "The new branch is forked from the current branch (HEAD)."
    echo ""
    echo "Examples:"
    echo "  git-worktree-add integrator-2589 feat/itgd-2589"
    echo "  git-worktree-add hotfix-auth fix/auth-token-expiry"
  }

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    _show_help
    return 0
  fi

  if [[ -z "$1" || -z "$2" ]]; then
    echo "Error: both folderName and branchName are required" >&2
    echo "" >&2
    _show_help >&2
    return 1
  fi

  local folder_name="$1"
  local branch_name="$2"
  local worktree_path="../${folder_name}"

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: not inside a git repository" >&2
    return 1
  fi

  git worktree add "${worktree_path}" -b "${branch_name}" || return 1
  cd "${worktree_path}" || return 1
}
