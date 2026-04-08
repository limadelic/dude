@dudes
Feature: Dudes

  Scenario: No pubs
    Then the "Dudes" section is empty

  Scenario: Pub dude
    Given dudes
      | home | icon |
      | dude | 🎳   |
    When > /pub dude
    Then the "Dudes" section shows "🎳ˣ"

  Scenario: Pub another dude
    Given dudes
      | home  | icon | pub |
      | dude  | 🎳   | yes |
      | elita | 🐶   | no  |
    When > /pub
    Then the "Dudes" section shows "🎳ˣ 🐶ˣ"

  Scenario: The Dude Abides
    Given dudes
      | home | icon | pub |
      | dude | 🎳   | yes |
    When > /abide
    Then the "Dudes" section shows "🎳⁰"

  Scenario: Another dude abides
    Given dudes
      | home  | icon | pub | abide |
      | dude  | 🎳   | yes | yes   |
      | elita | 🐶   | yes | no    |
    When > /abide
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"