Feature: Alley-PR

  Scenario: Refuses to run on main
    Given current branch is main
    When dude alley-pr is run
    Then error message contains "main"

