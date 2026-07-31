# kcli Cluster Management Runbook

Scripts for managing k3s clusters on Proxmox via `kcli`.

## Prerequisites

- [`kcli`](https://kcli.readthedocs.io) configured and connected to Proxmox
- [`yq`](https://github.com/mikefarah/yq) v4+ installed (`brew install yq`)
- `kubectl` installed
- All scripts must be executable:
  ```bash
  chmod +x create_cluster.sh delete_cluster.sh list_cluster.sh \
           create_vm.sh delete_vm.sh list_vm.sh
  ```

---

## Cluster Scripts

### List Clusters

```bash
# Full table output
./list_cluster.sh

# Names only (one per line — useful for piping)
./list_cluster.sh -s
```

---

### Create Clusters

Accepts one or more YAML parameter files. Skips clusters that already exist.
After creation, renames the kubeconfig context from `default` to the cluster name.

```bash
# Create a single cluster
./create_cluster.sh k3s-blue.yml

# Create multiple clusters in one call
./create_cluster.sh k3s-blue.yml k3s-green.yml k3s-yellow.yml
```

**Available cluster configs:**

| File | Cluster | CPUs | RAM | Workers |
|---|---|---|---|---|
| `k3s-blue.yml` | blue | 2 | 4096 MB | 0 |
| `k3s-green.yml` | green | 2 | 4096 MB | 0 |
| `k3s-yellow.yml` | yellow | 2 | 4096 MB | 1 |

---

### Delete Clusters

Deletes the cluster, removes its kubeconfig, and cleans up any leftover VMs.

```bash
# Delete a single cluster (prompts for confirmation)
./delete_cluster.sh blue

# Delete multiple clusters
./delete_cluster.sh blue green

# Skip confirmation prompt
./delete_cluster.sh -y blue green

# Delete all clusters via stdin (requires -y)
./list_cluster.sh -s | ./delete_cluster.sh -y
```

---

### Merge Kubeconfigs

After creating clusters, merge all kcli kubeconfigs into `~/.kube/config`:

```bash
cp ~/.kube/config ~/.kube/config.bak

KUBECONFIG=$(find ~/.kcli -name kubeconfig | tr '\n' ':')~/.kube/config \
  kubectl config view --flatten > /tmp/merged && \
  mv /tmp/merged ~/.kube/config

kubectl config get-contexts
```

---

### Switch Context

```bash
# Switch to a specific cluster
kubectl config use-context blue

# Or interactively inside k9s
k9s
# then type :context and press Enter

# Launch k9s directly in a context
k9s --context green
```

---

## VM Scripts

### List VMs

```bash
# Full table output
./list_vm.sh

# Names only (one per line — useful for piping)
./list_vm.sh -s
```

---

### Create VM

Creates a VM using the `local-lvm` pool on `vmbr0` network:

```bash
./create_vm.sh
```

---

### Delete VMs

```bash
# Delete a single VM (prompts for confirmation)
./delete_vm.sh my-vm

# Delete multiple VMs
./delete_vm.sh vm1 vm2

# Skip confirmation prompt
./delete_vm.sh -y vm1 vm2

# Delete all VMs via stdin (requires -y)
./list_vm.sh -s | ./delete_vm.sh -y
```

---

## Common Workflows

### Full cluster setup (create + merge kubeconfig)

```bash
./create_cluster.sh k3s-blue.yml k3s-green.yml k3s-yellow.yml

cp ~/.kube/config ~/.kube/config.bak
KUBECONFIG=$(find ~/.kcli -name kubeconfig | tr '\n' ':')~/.kube/config \
  kubectl config view --flatten > /tmp/merged && mv /tmp/merged ~/.kube/config

kubectl config get-contexts
```

### Tear down all clusters

```bash
./list_cluster.sh -s | ./delete_cluster.sh -y
```

### Tear down specific clusters

```bash
./delete_cluster.sh -y blue green
```
