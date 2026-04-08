@wip
Feature: News
  Report on latest Claude Code releases and smoke test status

  Scenario: Happy path — smoke test passes
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news
    Then output shows "Installed: 2.1.87, Latest: 2.1.96" at the top
    And output shows "Smoke test: success"
    And output shows the last 5 release notes

  Scenario: Smoke test fails
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "failure"
    When > /news
    Then output shows "Smoke test: failure"
    And output includes a link to the run logs

  Scenario: Custom limit
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news --limit 3
    Then output shows "Installed: 2.1.87"
    And output shows the last 3 release notes

  Scenario: Version reporting
    Given CC is installed at "2.1.87"
    And latest CC release is "2.1.96"
    And GHA workflow conclusion is "success"
    When > /news
    Then output shows "Installed: 2.1.87, Latest: 2.1.96" at the top
