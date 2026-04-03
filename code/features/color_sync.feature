Feature: Color sync

  Scenario: E0 - Prompt bar gets color on startup
    Given dude is starting for the first time
    And context is 20% (green)
    When dude starts
    Then the prompt bar appears in green

  Scenario: E1 - Prompt bar turns yellow when context rises
    Given dude is running
    And the prompt bar is green
    And context usage is 20%
    When context usage rises to 45%
    Then the prompt bar turns yellow

  @wip
  Scenario: E2 - Prompt bar follows context bar up to red
    Given dude is running with yellow prompt bar
    And context climbs to 75% (red)
    When context threshold is crossed
    Then the prompt bar turns red

  @wip
  Scenario: E3 - Prompt bar gets color on startup when already in yellow
    Given dude is starting for the first time
    And context is 50% (yellow)
    When dude starts
    Then the prompt bar appears in yellow

  @wip
  Scenario: E4 - Prompt bar stays same when color doesn't change
    Given dude is running with green prompt bar
    And context goes from 20% to 30% (still green)
    When context updates
    Then the prompt bar stays green
    And no restart occurs

  @wip
  Scenario: E5 - User can override with /color
    Given dude is running with red prompt bar
    When user runs /color blue
    Then the prompt bar turns blue
    And the prompt bar stays blue on next context change

  @wip
  Scenario: E6 - Prompt bar bounces between colors with rapid context changes
    Given dude is running with green prompt bar
    When context oscillates 32% → 33% → 32% rapidly
    Then the prompt bar turns yellow once
    And then turns green again
    And exactly 2 restarts occur

  @wip
  Scenario: E7 - Prompt bar doesn't restart within same color band
    Given dude is running with green prompt bar
    And context is at 20% (green)
    When context changes to 30% (still green)
    Then no JSONL write occurs
    And no restart occurs
