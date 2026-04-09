@dudes @bg
Feature: Dudes

  Scenario: No pubs
    Then the "Dudes" section is empty

  Scenario: Pub dude
    Given dudes
      | home | icon |
      | dude | 🎳   |
    * > /pub dude:
      | 🎳ˣ |

  Scenario: Pub another dude
    Given dudes
      | home  | icon | pub |
      | dude  | 🎳   | yes |
      | elita | 🐶   | no  |
    * > /pub:
      | 🎳ˣ 🐶ˣ |

  Scenario: The Dude Abides
    Given dudes
      | home | icon | pub |
      | dude | 🎳   | yes |
    * @dude > /abide:
      | 🎳⁰ |

  Scenario: Another dude abides
    Given dudes
      | home  | icon | pub | abide |
      | dude  | 🎳   | yes | yes   |
      | elita | 🐶   | yes | no    |
    * @dude > /abide:
      | 🎳⁰ 🐶⁰ |
