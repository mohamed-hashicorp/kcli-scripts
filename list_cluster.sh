#!/bin/bash

if [ "$1" = "-s" ]; then
  kcli list cluster -o name
else
  kcli list cluster
fi

