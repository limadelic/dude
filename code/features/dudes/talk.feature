@dudes @bg
Feature: Talk

  Scenario: Tell dude dont talk to urself
    * @dude > /abide:
      | 🎳⁰ |
    * > /tell dude do not talk to urself dude:
      | 🎳¹ |
    * > /abided:
      | 🎳⁰ |

  Scenario: Tell elita woof woof
    * @dude > /abide:
      | 🎳⁰ |
    * @elita > /abide:
      | 🎳⁰ 🐶⁰ |
    * @dude > /tell elita woof woof:
      | 🎳⁰ 🐶¹ |
    * @elita > /abided:
      | 🎳⁰ 🐶⁰ |

  Scenario: Ask dude bout meaning of life
    * @dude > /abide:
      | 🎳⁰ |
    * > /ask dude whats the meaning of life:
      | 🎳¹ |
    * > /reply dude 42:
      | 🎳¹ |
    * > /abided:
      | 🎳⁰ |

  Scenario: Ask elita the meaning of life
    * @dude > /abide:
      | 🎳⁰ |
    * @elita > /abide:
      | 🎳⁰ 🐶⁰ |
    * @dude > /ask elita whats the meaning of life:
      | 🎳⁰ 🐶¹ |
    * @elita > /reply dude 42:
      | 🎳¹ 🐶⁰ |
    * @dude > /abided:
      | 🎳⁰ 🐶⁰ |

  Scenario: Knock knock who let the dogs out
    * @dude > /abide:
      | 🎳⁰ |
    * @elita > /abide:
      | 🎳⁰ 🐶⁰ |
    * @dude > /ask elita knock knock:
      | 🎳⁰ 🐶¹ |
    * @elita > /reply dude whos there:
      | 🎳¹ 🐶⁰ |
    * @dude > /reply elita who let:
      | 🎳⁰ 🐶¹ |
    * @elita > /reply dude who let who:
      | 🎳¹ 🐶⁰ |
    * @dude > /reply elita who let the dogs out woof woof:
      | 🎳⁰ 🐶¹ |
    * @elita > /abided:
      | 🎳⁰ 🐶⁰ |
