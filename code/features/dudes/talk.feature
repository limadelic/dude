@dudes
Feature: Talk

  Scenario: Tell dude dont talk to urself
    Given dudes "dude" abide
    Then the "Dudes" section shows "🎳⁰"
    When > /tell dude do not talk to urself dude
    Then the "Dudes" section shows "🎳¹"
    When > /abided
    Then the "Dudes" section shows "🎳⁰"

  Scenario: Tell elita woof woof
    Given dudes "dude, elita" abide
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"
    When dude > /tell elita woof woof
    Then the "Dudes" section shows "🎳⁰ 🐶¹"
    When elita > /abided
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"

  Scenario: Ask dude bout meaning of life
    Given dudes "dude" abide
    Then the "Dudes" section shows "🎳⁰"
    When > /ask dude whats the meaning of life
    Then the "Dudes" section shows "🎳¹"
    When > /reply dude 42
    Then the "Dudes" section shows "🎳¹"
    When > /abided
    Then the "Dudes" section shows "🎳⁰"

  Scenario: Ask elita the meaning of life
    Given dudes "dude, elita" abide
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"
    When dude > /ask elita whats the meaning of life
    Then the "Dudes" section shows "🎳⁰ 🐶¹"
    When elita > /reply dude 42
    Then the "Dudes" section shows "🎳¹ 🐶⁰"
    When dude > /abided
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"

  Scenario: Knock knock who let the dogs out
    Given dudes "dude, elita" abide
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"
    When dude > /ask elita knock knock
    Then the "Dudes" section shows "🎳⁰ 🐶¹"
    When elita > /reply dude whos there
    Then the "Dudes" section shows "🎳¹ 🐶⁰"
    When dude > /reply elita who let
    Then the "Dudes" section shows "🎳⁰ 🐶¹"
    When elita > /reply dude who let who
    Then the "Dudes" section shows "🎳¹ 🐶⁰"
    When dude > /reply elita who let the dogs out woof woof
    Then the "Dudes" section shows "🎳⁰ 🐶¹"
    When elita > /abided
    Then the "Dudes" section shows "🎳⁰ 🐶⁰"