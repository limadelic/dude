#!/bin/bash
touch "$(dirname "$0")/restart" && kill "$1"
