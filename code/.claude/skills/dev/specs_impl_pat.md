# Spec Implementation Patterns

## Sut

- always declare the Sut first at the top 
- declare `let :sut { described_class.new }`

## Deps

- Deps are always injected Test Doubles
- declare: `let :dep { Object.new }`
- inject: `before { stub(Dude::Dep).new { dep }}`

## Const

- avoid magic values with Const
- use Const to enhance readability
- use Const in place of complex data structures
- declare: `let :pi { 3.14 }`

## Test

- name Test describing the intention
- dont leak the implementation

## Steps

- a Test has a max of 3 steps Setup, Exercise & Verify
- they are also equivalent to Arrange Act Assert 
- and Given When Then

## Helper

- extract repeated patterns into Helpers
- keep Test DRY by extracting dup tmi

## Setup

- Setup delays Exercise, minimize it
- keep it DRY by extracting common Setup 
- keep Setup that helps explaining the Test
- hide Setup that must exist but its tmi
- never copy-paste a before block, override only what differs

## Stub

- stubs belong in Setup
- use them when a call must return something needed
- it is usually needed as Arg to another method 
- or to be verified in the result
- trainwreck in 2 lines when Args and result are too long

## Mock

- mocks belong in Setup, next to stubs
- mocks are seldom needed
- they express something was called (side effects, sagas)
- RR mocks auto-verify after Exercise

## Args

- Args tend to be noisy, minimize noise
- use them when they explain the scenario
- use regexes to keep string expressive

## Exercise

- there can only be one Exercise per Test
- Exercise is a method called on the Sut
- never Exercise a test double

## Result

- prefer Verify chained to Exercise
- otherwise capture Exercise into Result 

## Verify

- ideally a single Verify per Test
- it should prove the intention of the Test name
- when chained to Exercise write the trainwreck in 2 lines

## Teardown

- keep Teardown code as invisible as possible
- when needed try to put it outside of the Test
