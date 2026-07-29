# Windmill

## Nodes

- quijote: workhorse where the magic happens
- sancho: information hub

## Sync

- every folder has a twin folder
- use git to move code from sancho to quijote
- use windmill to move files
- use git readonly on quijote

## SetUp

- twin folder exist in sancho first
- in quijote make an empty git repo
- set remote named sancho pointing to twin folder

## Usage

- must be used from folder with twin
- windmill <node> <file|path>: copies file(s) to node relative to twin folder
- windmill <file|path>: current node is implicit, brings file(s) by default
