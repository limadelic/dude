Feature: Alley-PR

  Scenario: Refuses to run on main
    * ~ git branch --show-current
      | main |
    * > /alley-pr:
      | Cannot run on main branch |

  Scenario: Happy path
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:org/repo.git |
    * ~ git push
      | Everything up-to-date |
    * ~ gh workflow run dude.yml
      | triggered workflow |
    * ~ gh run list --json databaseId
      | 12345 |
    * ~ gh run list --json status
      | completed |
    * ~ gh run view --json conclusion
      | success |
    * ~ gh pr list --head feature-branch
      | https://github.com/org/repo/pull/123 |
    * > /alley-pr:
      | https://github.com/org/repo/pull/123 |

  Scenario: Workflow fails
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:org/repo.git |
    * ~ git push
      | Enumerating objects |
    * ~ gh workflow run dude.yml
      | triggered workflow |
    * ~ gh run list --json databaseId
      | 12345 |
    * ~ gh run list --json status
      | completed |
    * ~ gh run view --json conclusion
      | failure |
    * > /alley-pr:
      | Workflow failed |
      | https://github.com/org/repo/actions/runs/12345 |

  Scenario: Workflow succeeds but no PR
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:org/repo.git |
    * ~ git push
      | Enumerating objects |
    * ~ gh workflow run dude.yml
      | triggered workflow |
    * ~ gh run list --json databaseId
      | 12345 |
    * ~ gh run list --json status
      | completed |
    * ~ gh run view --json conclusion
      | success |
    * ~ gh pr list --head feature-branch
      |  |
    * > /alley-pr:
      | No PR found |
      | https://github.com/org/repo/actions/runs/12345 |

  Scenario: Multiple PRs for branch
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:org/repo.git |
    * ~ git push
      | Enumerating objects |
    * ~ gh workflow run dude.yml
      | triggered workflow |
    * ~ gh run list --json databaseId
      | 12345 |
    * ~ gh run list --json status
      | completed |
    * ~ gh run view --json conclusion
      | success |
    * ~ gh pr list --head feature-branch
      | https://github.com/org/repo/pull/122 |
      | https://github.com/org/repo/pull/124 |
    * ~ echo pbcopy
      |  |
    * ~ git commit
      |  |
    * > /alley-pr:
      | https://github.com/org/repo/pull/124 |
      | Multiple PRs found, using newest |
