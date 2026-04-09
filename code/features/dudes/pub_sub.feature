@dudes @bg
Feature: Dudes

  Scenario: No pubs
    Then the "Dudes" section is empty

  Scenario: Pub dude
    Given dudes
      | home | icon |
      | dude | 🎳   |
    When > /pub dude:
      | 🎳ˣ |

  Scenario: Pub another dude
    Given dudes
      | home  | icon | pub |
      | dude  | 🎳   | yes |
      | elita | 🐶   | no  |
    When > /pub:
      | 🎳ˣ 🐶ˣ |

  Scenario: The Dude Abides
    Given dudes
      | home | icon | pub |
      | dude | 🎳   | yes |
    When @dude > /abide:
      | 🎳⁰ |

  Scenario: Another dude abides
    Given dudes
      | home  | icon | pub | abide |
      | dude  | 🎳   | yes | yes   |
      | elita | 🐶   | yes | no    |
    When @dude > /abide:
      | 🎳⁰ 🐶⁰ |
