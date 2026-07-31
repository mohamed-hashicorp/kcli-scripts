#!/bin/bash

if [ "$1" = "-s" ]; then
  kcli list vm -o name
else
  kcli list vm
fi
