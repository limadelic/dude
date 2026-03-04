If already on a branch with an **open** PR, skip to step 3.
If the PR is merged or closed, treat as if on main — go to step 1.

Make a todo for each step and follow in order

1. Ensure Branch Exist: We cannot push to main so if we r not in a brach we need to make one.

   - Update main
   - Create branch from main.
     - Name: `<type>-<name>` (type: `skill|agent|cmd|plan|rules`, name: max 3 words no verbs)

2. Ensure PR Exist

   - Create PR using gh pr create

3. Commit and Push the changes

4. Start the Watcher again
