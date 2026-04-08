@wip
Feature: News
  Report on latest Claude Code releases and smoke test status

  Scenario: Happy path — smoke test passes
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news
    Then news shows "Installed: 2.1.87, Latest: 2.1.96"
    And news shows "Smoke test: success"
    And news lists 5 releases

  Scenario: Smoke test fails
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "failure"
    When > /news
    Then news shows "Smoke test: failure"
    And news shows "github.com"

  Scenario: Custom limit
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news --limit 3
    Then news shows "Installed: 2.1.87"
    And news lists 3 releases

  Scenario: Version reporting
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news
    Then news starts with "Installed: 2.1.87, Latest: 2.1.96"
