@dudes
Feature: Pub Sub

  Scenario: Pub dude
    * @dude > /pub:
      | 🎳ˣ |

  Scenario: Pub another dude
    * @dude > /pub:
      | 🎳ˣ |
    * @elita > /pub:
      | 🎳ˣ 🐶ˣ |

  Scenario: The Dude Abides
    * @dude > /pub:
      | 🎳ˣ |
    * @dude > /abide:
      | 🎳⁰ |

  Scenario: Another dude abides
    * @dude > /pub:
      | 🎳ˣ |
    * @elita > /pub:
      | 🎳ˣ 🐶ˣ |
    * @dude > /abide:
      | 🎳⁰ 🐶⁰ |
