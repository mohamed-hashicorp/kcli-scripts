# kcli-scripts

Bash scripts for managing k3s clusters and VMs on Proxmox via [`kcli`](https://kcli.readthedocs.io).

## What's included

| Script | Description |
|---|---|
| `create_cluster.sh` | Create one or more k3s clusters from YAML param files |
| `delete_cluster.sh` | Delete clusters, remove kubeconfigs, and clean up leftover VMs |
| `list_cluster.sh` | List clusters (full table or names-only with `-s`) |
| `create_vm.sh` | Create a VM on `local-lvm` pool via `vmbr0` network |
| `delete_vm.sh` | Delete one or more VMs (supports stdin and `-y` auto-confirm) |
| `list_vm.sh` | List VMs (full table or names-only with `-s`) |

Cluster parameter files:

| File | Cluster | CPUs | RAM | Workers |
|---|---|---|---|---|
| `k3s-blue.yml` | blue | 2 | 4096 MB | 0 |
| `k3s-green.yml` | green | 2 | 4096 MB | 0 |
| `k3s-yellow.yml` | yellow | 2 | 4096 MB | 1 |

## Prerequisites

- [`kcli`](https://kcli.readthedocs.io) configured and pointing at your Proxmox host
- [`yq`](https://github.com/mikefarah/yq) v4+ — `brew install yq`
- `kubectl` installed

Make all scripts executable:

```bash
chmod +x *.sh
```

## Usage

### Clusters

```bash
# List clusters
./list_cluster.sh           # full table
./list_cluster.sh -s        # names only

# Create clusters (one or more YAML files)
./create_cluster.sh k3s-blue.yml
./create_cluster.sh k3s-blue.yml k3s-green.yml k3s-yellow.yml

# Delete clusters
./delete_cluster.sh blue                        # single, prompts for confirmation
./delete_cluster.sh -y blue green               # multiple, skip confirmation
./list_cluster.sh -s | ./delete_cluster.sh -y   # delete all via stdin
```

### VMs

```bash
# List VMs
./list_vm.sh                # full table
./list_vm.sh -s             # names only

# Create a VM
./create_vm.sh

# Delete VMs
./delete_vm.sh my-vm                        # single, prompts for confirmation
./delete_vm.sh -y vm1 vm2                   # multiple, skip confirmation
./list_vm.sh -s | ./delete_vm.sh -y         # delete all via stdin
```

### Merge kubeconfigs into `~/.kube/config`

After creating clusters, merge all kcli kubeconfigs:

```bash
cp ~/.kube/config ~/.kube/config.bak

KUBECONFIG=$(find ~/.kcli -name kubeconfig | tr '\n' ':')~/.kube/config \
  kubectl config view --flatten > /tmp/merged && \
  mv /tmp/merged ~/.kube/config

kubectl config get-contexts
```

### Switch context

```bash
kubectl config use-context blue

# Or in k9s: type :context and press Enter
k9s --context green
```

## How `create_cluster.sh` works

1. Reads each YAML param file passed as an argument
2. Skips clusters that already exist
3. Creates the cluster with `kcli create cluster k3s --paramfile <file>`
4. Uses `yq` to rename the kubeconfig context from `default` to the cluster name

## How `delete_cluster.sh` works

1. Accepts cluster names as arguments or from stdin (requires `-y` with stdin)
2. Runs `kcli delete cluster <name>`
3. Removes the leftover kubeconfig at `~/.kcli/clusters/<name>/auth/kubeconfig`
4. Lists VMs matching the cluster name and deletes any leftovers

## Full runbook

See [`RUNBOOK.md`](RUNBOOK.md) for detailed step-by-step instructions.
