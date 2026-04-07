Feature: Color sync

  @wip
  Scenario: E0 - Prompt bar gets color on startup
    Given 20% context usage
    When dude starts
    Then prompt bar is green

  @wip
  Scenario: E1 - Prompt bar turns yellow when context rises
    Given 20% context usage
    When context changes to 45%
    Then prompt bar is yellow

  @wip
  Scenario: E2 - Prompt bar turns red when context rises
    Given 50% context usage
    When context changes to 75%
    Then prompt bar is red

  @wip
  Scenario: E3 - Prompt bar gets color on startup at yellow
    Given 50% context usage
    When dude starts
    Then prompt bar is yellow

  @wip
  Scenario: E4 - Prompt bar stays green within same band
    Given 20% context usage
    When context changes to 30%
    Then prompt bar is green

  @wip
  Scenario: E5 - User can override color
    Given 20% context usage
    When user overrides color to blue
    Then prompt bar is blue

  @wip
  Scenario: E6 - Prompt bar responds to rapid context changes
    Given 20% context usage
    When context changes to 32%
    Then prompt bar is green
    When context changes to 34%
    Then prompt bar is yellow

  @wip
  Scenario: E7 - Prompt bar stays green within same band
    Given 20% context usage
    When context changes to 30%
    Then prompt bar is green
