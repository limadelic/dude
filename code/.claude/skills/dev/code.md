# Code Rules

## DDD
- one class per file, filename matches class name
- split following SRP into DDD-named modules
- use domain words, not technical jargon
- names should read like the business, not the framework
- short and clear — never abbreviated, never obfuscated
- abstractions model the domain, not the technology
- names reveal intent, not implementation

## DONT
- NO comments in code — ever. Code should be self-explanatory.
- NO .freeze — ever. Not on constants, not on strings, not anywhere. 