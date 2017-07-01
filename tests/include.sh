#!/bin/bash

echo "include.sh"

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/incl.sh"

die;

echo "end include.sh"

# . "$DIR/main.sh"


exit 0;
