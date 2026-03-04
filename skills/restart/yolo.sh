function yolo {
  local initial_args="$@"
  while true; do
    if [[ -f restart ]]; then
      rm restart
      source ~/.zshrc
      claude -c --dangerously-skip-permissions "continue"
    else
      claude --dangerously-skip-permissions $initial_args
    fi
    [[ ! -f restart ]] && return
  done
}
