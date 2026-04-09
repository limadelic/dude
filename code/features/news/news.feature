@news @wip
Feature: News

  Scenario: happy path
    * ! claude --version
      | 2.1.90 |
    * ! gh release list -R anthropics/claude-code --limit 1
      | v2.1.96 |
    * ! gh workflow run dude.yml prompt="1 + 1" version=$latest
    * ! gh run list --repo UKGEPIC/dude --json status
      | completed |
    * ! gh run list --repo UKGEPIC/dude --json conclusion
      | success |
    * ! gh release list -R anthropics/claude-code
      | v2.1.96 |
      | v2.1.95 |
      | v2.1.94 |
      | v2.1.93 |
      | v2.1.92 |
    * > /news:
      | Installed: 2.1.90, Latest: v2.1.96 |
      | v2.1.96                             |
      | v2.1.95                             |
      | v2.1.94                             |
      | v2.1.93                             |
      | v2.1.92                             |
      | Vintage 2.1.96: success                 |

  Scenario: smoke test fails
    * ! claude --version
      | 2.1.90 |
    * ! gh release list -R anthropics/claude-code --limit 1
      | v2.1.96 |
    * ! gh workflow run dude.yml prompt="1 + 1" version=$latest
    * ! gh run list --repo UKGEPIC/dude --json status
      | completed |
    * ! gh run list --repo UKGEPIC/dude --json conclusion
      | failure |
    * ! gh run list --repo UKGEPIC/dude --json databaseId
      | 12345 |
    * ! gh api repos/UKGEPIC/dude/actions/runs/12345/jobs
      | 678 |
    * ! gh api repos/UKGEPIC/dude/actions/jobs/678/logs
      | Error: claude timed out after 5s |
    * ! gh release list -R anthropics/claude-code
      | v2.1.96 |
      | v2.1.95 |
      | v2.1.94 |
      | v2.1.93 |
      | v2.1.92 |
    * > /news:
      | Installed: 2.1.90, Latest: v2.1.96                    |
      | v2.1.96                                                |
      | v2.1.95                                                |
      | v2.1.94                                                |
      | v2.1.93                                                |
      | v2.1.92                                                |
      | Vintage 2.1.96: failure                               |
      | https://github.com/UKGEPIC/dude/actions/runs/12345    |
      | Error: claude timed out after 5s                       |

  Scenario: custom limit
    * ! claude --version
      | 2.1.90 |
    * ! gh release list -R anthropics/claude-code --limit 1
      | v2.1.96 |
    * ! gh workflow run dude.yml prompt="1 + 1" version=$latest
    * ! gh run list --repo UKGEPIC/dude --json status
      | completed |
    * ! gh run list --repo UKGEPIC/dude --json conclusion
      | success |
    * ! gh release list -R anthropics/claude-code
      | v2.1.96 |
      | v2.1.95 |
      | v2.1.94 |
    * > /news --limit 3:
      | Installed: 2.1.90, Latest: v2.1.96 |
      | v2.1.96                             |
      | v2.1.95                             |
      | v2.1.94                             |
      | Vintage 2.1.96: success            |
