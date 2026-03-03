When SSH'd into the Mac, some commands (like `gh`) need GUI context for keychain access. A launchd watcher runs in GUI context and executes scripts dropped in /tmp/ssh.

To run a command with GUI context:

1. Write script with cd to current dir: `echo "cd $(pwd) && $ARGUMENTS" > /tmp/ssh/run.sh`
2. Wait for execution: `sleep 2`
3. Read output: `cat /tmp/ssh/out.txt`

Example: `/ssh gh pr list`
