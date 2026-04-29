Feature: Alley-PR

  Scenario: Refuses to run on main
    * ~ git branch --show-current
      | main |
    * > /alley-pr:
      | Cannot run on main branch |

  Scenario: UKGEPIC workflow happy path
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:UKGEPIC/repo.git |
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
      | https://github.com/UKGEPIC/repo/pull/123 |
    * > /alley-pr:
      | https://github.com/UKGEPIC/repo/pull/123 |

  Scenario: UKGEPIC workflow fails
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:UKGEPIC/repo.git |
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
      | https://github.com/UKGEPIC/repo/actions/runs/12345 |

  Scenario: UKGEPIC workflow succeeds but no PR
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:UKGEPIC/repo.git |
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
      | https://github.com/UKGEPIC/repo/actions/runs/12345 |

  Scenario: Multiple PRs for branch in UKGEPIC workflow
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:UKGEPIC/repo.git |
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
      | https://github.com/UKGEPIC/repo/pull/122 |
      | https://github.com/UKGEPIC/repo/pull/124 |
    * ~ echo pbcopy
      |  |
    * ~ git commit
      |  |
    * > /alley-pr:
      | https://github.com/UKGEPIC/repo/pull/124 |
      | Multiple PRs found, using newest |

  Scenario: Simple PR path happy path
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:msuarz/some-repo.git |
    * ~ git push -u origin feature-branch
      | Everything up-to-date |
    * ~ gh pr create --fill
      | https://github.com/msuarz/some-repo/pull/456 |
    * > /alley-pr:
      | https://github.com/msuarz/some-repo/pull/456 |

  Scenario: Simple PR path copies to clipboard
    * ~ git branch --show-current
      | feature-branch |
    * ~ git remote get-url origin
      | git@github.com:msuarz/some-repo.git |
    * ~ git push -u origin feature-branch
      | Everything up-to-date |
    * ~ gh pr create --fill
      | https://github.com/msuarz/some-repo/pull/456 |
    * ~ echo pbcopy
      |  |
    * > /alley-pr:
      | https://github.com/msuarz/some-repo/pull/456 |
