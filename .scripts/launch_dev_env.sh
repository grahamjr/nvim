#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [-s session_name] [-v venv_path] [-d project_dir] 
  -s session_name   tmux session name (default: dev)
  -v venv_cmd       Command used to activate the environment. (optional)
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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SESSION="dev"
VENV_CMD=""
PROJECT_DIR="$PWD"

while getopts ":s:v:d:h" opt; do
  case ${opt} in
    s) SESSION="$OPTARG" ;;
    v) VENV_CMD="$OPTARG" ;;
    d) PROJECT_DIR="$OPTARG" ;;
    h) usage ;;
    :) echo "Missing arg for -$OPTARG"; usage ;;
    \?) echo "Invalid option -$OPTARG"; usage ;;
  esac
done
shift $((OPTIND - 1))


NVIM_SOCK="/tmp/nvim-${SESSION}.sock"
HAS_CODEX=0
SHARED_VENV_PATH=""
PATH_PREFIX="${PROJECT_DIR}/.scripts:${SCRIPT_DIR}"
if command -v codex >/dev/null 2>&1; then
  HAS_CODEX=1
fi

# If session already exists, just attach (no re-sending)
if tmux has-session -t "${SESSION}" 2>/dev/null; then
  tmux attach-session -t "${SESSION}"
  exit 0
fi

echo "Creating tmux session '${SESSION}'..."
# Bootstrap with a temporary window so we can seed a shared session env first.
tmux new-session -d -s "${SESSION}" -n BOOTSTRAP
tmux set-option -t "${SESSION}" renumber-windows on
BOOTSTRAP_PANE="${SESSION}:BOOTSTRAP.0"

# Shared environment for all windows created in this session.
tmux set-environment -t "${SESSION}" PROJECT_DIR "${PROJECT_DIR}"
tmux set-environment -t "${SESSION}" SCRIPT_DIR "${SCRIPT_DIR}"
tmux set-environment -t "${SESSION}" NVIM_SOCK "${NVIM_SOCK}"
tmux set-environment -t "${SESSION}" PATH "${PATH_PREFIX}:${PATH}"

if [ -n "${VENV_CMD}" ]; then
  TMP_ENV_FILE="/tmp/tmux-${SESSION}-env.$$"
  TMUX_WAIT_CHANNEL="env-ready-${SESSION}-$$"
  BOOTSTRAP_PATH=""
  sendln "${BOOTSTRAP_PANE}" "cd \"${PROJECT_DIR}\""
  sendln "${BOOTSTRAP_PANE}" "${VENV_CMD}"
  sendln "${BOOTSTRAP_PANE}" "env -0 > \"${TMP_ENV_FILE}\"; tmux wait-for -S \"${TMUX_WAIT_CHANNEL}\""
  tmux wait-for "${TMUX_WAIT_CHANNEL}"

  while IFS='=' read -r -d '' key val; do
    case "${key}" in
      PWD|OLDPWD|SHLVL|_|TMUX|TMUX_PANE|TERM|DIRENV_*) continue ;;
    esac
    if [ "${key}" = "PATH" ]; then
      BOOTSTRAP_PATH="${val}"
      continue
    fi
    if [ "${key}" = "VIRTUAL_ENV" ]; then
      SHARED_VENV_PATH="${val}"
    fi
    tmux set-environment -t "${SESSION}" "${key}" "${val}"
  done < "${TMP_ENV_FILE}"

  if [ -n "${BOOTSTRAP_PATH}" ]; then
    tmux set-environment -t "${SESSION}" PATH "${PATH_PREFIX}:${BOOTSTRAP_PATH}"
  fi

  rm -f "${TMP_ENV_FILE}"
fi

# Create working windows after env setup so panes inherit the same base env.
tmux new-window -t "${SESSION}" -n EDITOR
tmux new-window -t "${SESSION}" -n GIT
tmux new-window -t "${SESSION}" -n BUILD
if [ "${HAS_CODEX}" -eq 1 ]; then
  tmux new-window -t "${SESSION}" -n CODEX
fi
tmux kill-window -t "${SESSION}:BOOTSTRAP"

EDITOR_PANE="${SESSION}:EDITOR.0"
GIT_PANE="${SESSION}:GIT.0"
BUILD_PANE="${SESSION}:BUILD.0"
if [ "${HAS_CODEX}" -eq 1 ]; then
  GPT_PANE="${SESSION}:CODEX.0"
fi

sleep 0.1
sendln "$EDITOR_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${SHARED_VENV_PATH}" ]; then
  sendln "$EDITOR_PANE" "source \"${SHARED_VENV_PATH}/bin/activate\""
fi
sendln "$EDITOR_PANE" "export PATH=\"${PATH_PREFIX}:\$PATH\""
# sendln "$EDITOR_PANE" "[ -f \"${OPENAI_KEY_ENV_FILE}\" ] && source \"${OPENAI_KEY_ENV_FILE}\""
sendln "$EDITOR_PANE" "nvim . --listen \"${NVIM_SOCK}\""

sleep 0.1
sendln "$GIT_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${SHARED_VENV_PATH}" ]; then
  sendln "$GIT_PANE" "source \"${SHARED_VENV_PATH}/bin/activate\""
fi
sendln "$GIT_PANE" "export PATH=\"${PATH_PREFIX}:\$PATH\""
sendln "$GIT_PANE" "lazygit -ucf \"${SCRIPT_DIR}\"/tmux_session_config.yml"

sleep 0.1
sendln "$BUILD_PANE" "cd \"${PROJECT_DIR}\""
if [ -n "${SHARED_VENV_PATH}" ]; then
  sendln "$BUILD_PANE" "source \"${SHARED_VENV_PATH}/bin/activate\""
fi
sendln "$BUILD_PANE" "export PATH=\"${PATH_PREFIX}:\$PATH\""
# sendln "$BUILD_PANE" "PATH=\"${SCRIPT_DIR}:\$PATH\" \"${SCRIPT_DIR}/start_codex_cmp_proxy.sh\" || true"

sleep 0.1
if [ "${HAS_CODEX}" -eq 1 ]; then
  sendln "$GPT_PANE" "cd \"${PROJECT_DIR}\""
  if [ -n "${SHARED_VENV_PATH}" ]; then
    sendln "$GPT_PANE" "source \"${SHARED_VENV_PATH}/bin/activate\""
  fi
  sendln "$GPT_PANE" "export PATH=\"${PATH_PREFIX}:\$PATH\""
  sendln "$GPT_PANE" "codex"
else
  echo "Info: 'codex' executable not found; skipping CODEX window."
fi

# Ensure we land in editor window
tmux select-window -t "${SESSION}:EDITOR"
tmux attach-session -t "${SESSION}"
