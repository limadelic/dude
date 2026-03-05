function unlock_keychain {

  [ -z "$SSH_CONNECTION" ] && return
  [ -n "$KEYCHAIN_UNLOCKED" ] && return

  security unlock-keychain ~/Library/Keychains/login.keychain-db
  export KEYCHAIN_UNLOCKED=true

}

function yolo {

  unlock_keychain

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
