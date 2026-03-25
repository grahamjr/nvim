#!/usr/bin/env bash

FILE="$1"

SESSION="$(tmux display-message -p '#{session_name}')"
SOCKET="/tmp/nvim-${SESSION}.sock"

tmux select-window -t "${SESSION}:EDITOR"

if [[ -f $FILE ]]; then
    LINE="${2:-1}"
    nvim --server "$SOCKET" --remote-send "<cmd>e ${FILE}<cr>${LINE}G"
elif [[ -d $FILE ]]; then
    nvim --server "$SOCKET" --remote-send "<cmd>Explore ${FILE}<cr>"
fi
