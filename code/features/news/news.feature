@news
Feature: News
  Report on latest Claude Code releases and smoke test status

  Scenario: Happy path — smoke test passes
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news
    Then shows
      | Installed: 2.1.87, Latest: 2.1.96 |
      | Smoke test: success                |
      | v2.1.96                            |
      | v2.1.95                            |
      | v2.1.94                            |
      | v2.1.93                            |
      | v2.1.92                            |

  Scenario: Smoke test fails
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "failure"
    When > /news
    Then shows
      | Smoke test: failure    |
      | github.com             |

  Scenario: Custom limit
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news --limit 3
    Then shows
      | v2.1.96 |
      | v2.1.95 |
      | v2.1.94 |

  Scenario: Version reporting
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news
    Then shows "Installed: 2.1.87, Latest: 2.1.96"
