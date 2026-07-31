#!/bin/bash

# Parse -y flag and VM name arguments
confirmed=false
vms=()

for arg in "$@"; do
  if [ "$arg" = "-y" ]; then
    confirmed=true
  else
    vms+=("$arg")
  fi
done

# Fall back to stdin if no VM names were given as arguments
using_stdin=false
if [ ${#vms[@]} -eq 0 ] && [ ! -t 0 ]; then
  using_stdin=true
  while IFS= read -r line; do
    vms+=("$line")
  done
fi

# Require at least one VM name
if [ ${#vms[@]} -eq 0 ]; then
  echo "Error: this script needs an argument (VM name)"
  exit 1
fi

# Require -y when reading from stdin
if [ "$using_stdin" = true ] && [ "$confirmed" = false ]; then
  echo "Error: pass -y to confirm deletion when using stdin"
  exit 1
fi

for vm in "${vms[@]}"; do
  if [ "$confirmed" = true ]; then
    kcli delete vm "$vm" -y
  else
    kcli delete vm "$vm"
  fi
done
