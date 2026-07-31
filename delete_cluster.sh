#!/bin/bash

# Parse -y flag and cluster name arguments
confirmed=false
clusters=()

for arg in "$@"; do
  if [ "$arg" = "-y" ]; then
    confirmed=true
  else
    clusters+=("$arg")
  fi
done

# Fall back to stdin if no cluster names were given as arguments
using_stdin=false
if [ ${#clusters[@]} -eq 0 ] && [ ! -t 0 ]; then
  using_stdin=true
  while IFS= read -r line; do
    clusters+=("$line")
  done
fi

# Require at least one cluster name
if [ ${#clusters[@]} -eq 0 ]; then
  echo "Error: this script needs an argument (cluster name)"
  exit 1
fi

# Require -y when reading from stdin
if [ "$using_stdin" = true ] && [ "$confirmed" = false ]; then
  echo "Error: pass -y to confirm deletion when using stdin"
  exit 1
fi

for cluster in "${clusters[@]}"; do
  if [ "$confirmed" = true ]; then
    kcli delete cluster "$cluster" -y
  else
    kcli delete cluster "$cluster"
  fi
  # Remove kubeconfig if still exists
  [ -f ~/.kcli/clusters/$cluster/auth/kubeconfig ] && rm ~/.kcli/clusters/$cluster/auth/kubeconfig
  # Delete any leftover VMs matching the cluster name
  leftover_vms=$(./list_vm.sh -s | grep "$cluster")
  if [ -n "$leftover_vms" ]; then
    echo "$leftover_vms" | ./delete_vm.sh -y
  fi
done
