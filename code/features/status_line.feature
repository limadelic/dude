Feature: Status line

  Scenario Outline: Context section
    Given <percent>% context usage
    Then the "Context" section shows "<🧠 bar>" in <color>

    Examples:
      | percent | 🧠 bar       | color  |
      | 0       | 🧠 ░░░░░░░░░ | green  |
      | 10      | 🧠 █░░░░░░░░ | green  |
      | 50      | 🧠 █████░░░░ | yellow |
      | 90      | 🧠 ████████░ | red    |

  Scenario Outline: Spend section
    Given daily allowance is $100
    And $<spend> spent
    Then the "Spend" section shows "<💰 bar>" in <color>

    Examples:
      | spend | 💰 bar       | color  |
      | 25    | 💰 ██░░░░░░░ | green  |
      | 40    | 💰 ████░░░░░ | yellow |
      | 80    | 💰 ███████░░ | red    |

  Scenario Outline: Models section
    Given the <active> model
    And <🐸> haiku at $1, <🎸> sonnet at $3, <🎭> opus at 5$ requests
    Then the "Models" section shows "<icons>" in <color>

    Examples:
      | active | 🐸  | 🎸 | 🎭 | icons          | color  | #                |
      | opus   | 0   | 0  | 42 | [🎭¹⁰] 🐸⁰ 🎸⁰ | red    | all opus         |
      | opus   | 50  | 0  | 10 | 🐸⁸ [🎭²] 🎸⁰  | yellow | 5x haiku         |
      | sonnet | 10  | 10 | 10 | 🐸⁴ 🎭³ [🎸³]  | yellow | all models equal |
      | haiku  | 100 | 0  | 0  | [🐸¹⁰] 🎭⁰ 🎸⁰ | red    | all haiku        |
