Feature: Pomo

  Scenario Outline: Work session
    Given <min> passed into a work session
    Then the "Pomo" bar shows "<🍅 bar>" in red

    Examples:
      | min | 🍅 bar       |
      | 0   | 🍅 ░░░░░░░░░ |
      | 8   | 🍅 ███░░░░░░ |
      | 16  | 🍅 ██████░░░ |
      | 24  | 🍅 █████████ |

  Scenario Outline: Break
    Given <min> passed into a break session
    Then the "Pomo" bar shows "<🍏 bar>" in green

    Examples:
      | min | 🍏 bar       |
      | 0   | 🍏 ░░░░░░░░░ |
      | 1   | 🍏 ██░░░░░░░ |
      | 2   | 🍏 ████░░░░░ |
      | 4   | 🍏 ███████░░ |

  Scenario Outline: Long break
    Given <min> passed into a long break session
    Then the "Pomo" bar shows "<🍏 bar>" in green

    Examples:
      | min | 🍏 bar       |
      | 0   | 🍏 ░░░░░░░░░ |
      | 4   | 🍏 ██░░░░░░░ |
      | 8   | 🍏 █████░░░░ |
      | 12  | 🍏 ███████░░ |
