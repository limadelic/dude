#!/bin/zsh -l
exec /opt/homebrew/bin/tmux -L "q$$" new-session -c "$HOME/dude" 'zsh -ic yolo'
