#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [-s session_name] [-v venv_path] [-d project_dir] 
  -s session_name   tmux session name (default: dev)
  -v venv_path      path to virtualenv directory or path to activate script
  -d project_dir    directory to cd into before launching nvim (default: \$PWD)
EOF
  exit 1
}
sendln () {
  local target="$1"
  shift
  tmux send-keys -t "$target" -l "$*"
  tmux send-keys -t "$target" C-m
}
wait_for_pane() {
  local target="$1"   # e.g. dev:editor.0
  local tries=200     # ~2s at 10ms
  while ! tmux has-session -t "${target%%:*}" 2>/dev/null; do
    sleep 0.01
    ((tries--)) || return 1
  done

  while ! tmux list-panes -t "$target" >/dev/null 2>&1; do
    sleep 0.01
    ((tries--)) || return 1
  done
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SESSION="dev"
VENV=""
PROJECT_DIR="$PWD"

while getopts ":s:v:d:h" opt; do
  case ${opt} in
    s) SESSION="$OPTARG" ;;
    v) VENV="$OPTARG" ;;
    d) PROJECT_DIR="$OPTARG" ;;
    h) usage ;;
    :) echo "Missing arg for -$OPTARG"; usage ;;
    \?) echo "Invalid option -$OPTARG"; usage ;;
  esac
done
shift $((OPTIND - 1))

# Resolve activation script if user passed -v
ACTIVATE=""
if [ -n "${VENV}" ]; then
  if [ -f "${VENV}" ]; then
    ACTIVATE="${VENV}"
  elif [ -f "${VENV}/bin/activate" ]; then
    ACTIVATE="${VENV}/bin/activate"
  else
    echo "Warning: venv not found at '${VENV}' or '${VENV}/bin/activate'. Ignoring -v."
    ACTIVATE=""
  fi
fi

NVIM_SOCK="/tmp/nvim-${SESSION}.sock"

# If session already exists, just attach (no re-sending)
if tmux has-session -t "${SESSION}" 2>/dev/null; then
  tmux attach-session -t "${SESSION}"
  exit 0
fi

echo "Creating tmux session '${SESSION}'..."
tmux new-session -d -s "${SESSION}" -n EDITOR
tmux new-window -t "${SESSION}" -n GIT
tmux new-window -t "${SESSION}" -n BUILD
tmux new-window -t "${SESSION}" -n CODEX

EDITOR_PANE="${SESSION}:EDITOR.0"
BUILD_PANE="${SESSION}:BUILD.0"
GIT_PANE="${SESSION}:GIT.0"
GPT_PANE="${SESSION}:CODEX.0"

sleep 0.1
sendln "$EDITOR_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${ACTIVATE}" ]; then
  sendln "$EDITOR_PANE" "source \"${ACTIVATE}\""
fi
sendln "$EDITOR_PANE" "PATH=\"${SCRIPT_DIR}:\$PATH\" nvim . --listen \"${NVIM_SOCK}\""

sleep 0.1
sendln "$GIT_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${ACTIVATE}" ]; then
  sendln "$GIT_PANE" "source \"${ACTIVATE}\""
fi
sendln "$GIT_PANE" "PATH=\"${SCRIPT_DIR}:\$PATH\" lazygit -ucf \"${SCRIPT_DIR}\"/tmux_session_config.yml"

sleep 0.1
sendln "$BUILD_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${ACTIVATE}" ]; then
  sendln "$BUILD_PANE" "source \"${ACTIVATE}\""
fi

sleep 0.1
sendln "$GPT_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${ACTIVATE}" ]; then
  sendln "$GPT_PANE" "source \"${ACTIVATE}\""
fi
sendln "$GPT_PANE" "codex"

# Ensure we land in editor window
tmux select-window -t "${SESSION}:EDITOR"
tmux attach-session -t "${SESSION}"
