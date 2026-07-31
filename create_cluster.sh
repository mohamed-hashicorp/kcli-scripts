#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo "Error: this script needs at least one YAML file argument"
  exit 1
fi

for yaml in "$@"; do
  {
    if [ ! -f "$yaml" ]; then
      echo "Error: file not found: $yaml"
      exit 1
    fi
    cluster=$(basename "$yaml" .yml)
    if kcli list cluster -o name 2>/dev/null | grep -qx "${cluster#*-}"; then
      echo "Skipping $cluster: cluster already exists"
      continue
    fi
    sleep 0.$RANDOM
    kcli create cluster k3s --paramfile "$yaml"
    export name="${cluster#*-}"
    yq e '
      .contexts[0].name = env(name) |
      .contexts[0].context.cluster = env(name) |
      .contexts[0].context.user = env(name) |
      .clusters[0].name = env(name) |
      .users[0].name = env(name) |
      .current-context = env(name)
    ' -i ~/.kcli/clusters/"${cluster#*-}"/auth/kubeconfig  
    #kubectl config get-contexts --kubeconfig=~/.kcli/clusters/"${cluster#*-}"/auth/kubeconfig
  } 
done


