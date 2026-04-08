@wip
Feature: News
  Report on latest Claude Code releases and smoke test status

  @wip
  Scenario: Happy path — smoke test passes
    Given I have Claude Code version "2.1.87" installed
    And the latest Claude Code version is "2.1.96"
    And the GHA workflow will complete with conclusion "success"
    When I run dude news
    Then output shows "Installed: 2.1.87, Latest: 2.1.96" at the top
    And output shows "Smoke test: success"
    And output shows the last 5 release notes

  @wip
  Scenario: Smoke test fails
    Given I have Claude Code version "2.1.87" installed
    And the latest Claude Code version is "2.1.96"
    And the GHA workflow will complete with conclusion "failure"
    When I run dude news
    Then output shows "Smoke test: failure"
    And output includes a link to the run logs

  @wip
  Scenario: Custom limit
    Given I have Claude Code version "2.1.87" installed
    And the latest Claude Code version is "2.1.96"
    And the GHA workflow will complete with conclusion "success"
    When I run dude news --limit 3
    Then output shows "Installed: 2.1.87"
    And output shows the last 3 release notes

  @wip
  Scenario: Version reporting
    Given I have Claude Code version "2.1.87" installed
    And the latest Claude Code version is "2.1.96"
    And the GHA workflow will complete with conclusion "success"
    When I run dude news
    Then output shows "Installed: 2.1.87, Latest: 2.1.96" at the top
