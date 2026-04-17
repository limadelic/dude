Feature: El

  Scenario: Send a message, get a response
    Given a Claude process in stream-json mode
    When I send "say hello"
    Then I get a successful response

  Scenario: Multi-turn conversation
    Given a Claude process in stream-json mode
    When I send "what is 2 plus 2"
    Then I get a successful response containing "4"
    When I send "multiply that by 3"
    Then I get a successful response containing "12"
