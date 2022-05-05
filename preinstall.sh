#!/bin/bash

if [[ -d /Users/.old ]]; then
  for d in /Users/.old/*; do
    chmod 0700 "${d}"
    chflags hidden "${d}"
    mv "${d}" /Users
  done
fi

/bin/mkdir -p -m755 /usr/local/bin

exit 0
