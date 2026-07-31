---
name: kcli-proxmox
description: Use when the user wants to create, modify, or troubleshoot helper shell scripts that operate kcli or Proxmox VMs — covering VM lifecycle (create, delete, list), kcli plan/cluster YAML files, and bash best practices for these scripts. Trigger phrases: "kcli script", "proxmox script", "create vm script", "delete vm script", "list vm", "kcli plan", "k3s cluster", "kcli helper".
---

# kcli / Proxmox Helper Scripts

This skill guides script authoring and editing for the kcli + Proxmox project.

## Project Context

The workspace contains helper bash scripts and kcli plan YAMLs for managing Proxmox VMs via kcli:

| File | Purpose |
|---|---|
| `create_vm.sh` | Create a VM on `local-lvm` pool attached to `vmbr0` |
| `delete_vm.sh` | Delete one or more named VMs (accepts multiple args, loops over them) |
| `list_vm.sh` | List VMs; `-s` flag outputs names only (`kcli list vm -o name`) |
| `list_cluster.sh` | List clusters; `-s` flag outputs names only (`kcli list cluster -o name`) |
| `delete_cluster.sh` | Delete one or more clusters — supports args and stdin; `-y` skips kcli prompt |
| `k3s-single.yml` | kcli plan for a single-node k3s cluster on Proxmox |

**Key Proxmox/kcli conventions used in this project:**
- Pool: `local-lvm`
- Network bridge: `vmbr0`
- Default image: `centos9stream`
- Domain: `lab.aymantech.net`

---

## Authoring Rules for Scripts in This Project

1. **Shebang**: Always start with `#!/bin/bash`.
2. **Bash 3 compatibility**: macOS ships with bash 3. Do NOT use `mapfile`. Use `while IFS= read -r line` to read stdin into an array.
3. **Argument validation**: Use `$#` for count checks; use a manual `for arg in "$@"` loop to parse flags mixed with positional args.
4. **Quoting**: Always quote variables: `"$var"`, `"$1"`.
5. **Exit codes**: Exit `1` on error, `0` (implicit) on success.
6. **No unnecessary output**: Only echo when it aids the user (errors, confirmations).
7. **kcli commands**: Use the standard form `kcli <verb> <resource> [args]`.
8. **Idempotency**: Scripts that create resources must be safe to run multiple times. Before creating a resource, check whether it already exists and skip with an informational message if it does. Use `kcli list <resource> -o name | grep -qx "<name>"` to check existence.

---

## Scripting Patterns

### Simple argument guard (single required arg)
```bash
if [ "$#" -eq 0 ]; then
  echo "Error: this script needs an argument (<description>)"
  exit 1
fi
```

### Loop over multiple arguments
```bash
for item in "$@"; do
  kcli delete vm "$item"
done
```

### Idempotent create (skip if already exists)
Use this for any script that creates a resource. Derive the resource name from the input (e.g. strip `.yml` from a filename with `basename`), check existence, and skip if found:

```bash
for yaml in "$@"; do
  name=$(basename "$yaml" .yml)
  if kcli list <resource> -o name 2>/dev/null | grep -qx "$name"; then
    echo "Skipping $name: already exists"
    continue
  fi
  kcli create <resource> ... "$yaml"
done
```

**Key details:**
- `basename "$yaml" .yml` — strips path and `.yml` suffix to derive the resource name from the filename
- `grep -qx` — `-q` suppresses output, `-x` matches the full line (exact name, no partial matches)
- `2>/dev/null` — suppresses kcli stderr in case no resources exist yet
- Always `continue` (not `exit`) so remaining items in the loop are still processed

### `-s` flag for short/name-only output
```bash
if [ "$1" = "-s" ]; then
  kcli list vm -o name
else
  kcli list vm
fi
```

### Parse mixed flags and positional args + stdin fallback + conditional `-y`
This is the pattern used by `delete_cluster.sh` — use it for any destructive script that:
- accepts multiple targets as args OR piped stdin
- has an optional `-y` flag to skip kcli's interactive confirmation prompt
- requires `-y` when targets come from stdin (non-interactive pipe)

```bash
#!/bin/bash

# Parse -y flag and positional arguments
confirmed=false
items=()

for arg in "$@"; do
  if [ "$arg" = "-y" ]; then
    confirmed=true
  else
    items+=("$arg")
  fi
done

# Fall back to stdin if no positional args were given
using_stdin=false
if [ ${#items[@]} -eq 0 ] && [ ! -t 0 ]; then
  using_stdin=true
  while IFS= read -r line; do
    items+=("$line")
  done
fi

# Require at least one target
if [ ${#items[@]} -eq 0 ]; then
  echo "Error: this script needs an argument (<description>)"
  exit 1
fi

# Require -y when reading from stdin (non-interactive)
if [ "$using_stdin" = true ] && [ "$confirmed" = false ]; then
  echo "Error: pass -y to confirm deletion when using stdin"
  exit 1
fi

for item in "${items[@]}"; do
  if [ "$confirmed" = true ]; then
    kcli delete <resource> "$item" -y
  else
    kcli delete <resource> "$item"
  fi
done
```

**Key details:**
- `[ ! -t 0 ]` — true when stdin is a pipe (not a terminal)
- `-y` is forwarded to kcli only when the user explicitly passed it; without it kcli prompts interactively
- `-y` is mandatory when stdin is used, because the terminal prompt cannot be answered through a pipe

---

## Common kcli Commands to Use in Scripts

```bash
kcli list vm                                      # list all VMs
kcli list vm -o name                              # names only
kcli create vm -P pool=local-lvm -P nets="[vmbr0]" [name]
kcli delete vm <name> [-y]
kcli start vm <name>
kcli stop vm <name>
kcli info vm <name>
kcli list cluster
kcli list cluster -o name
kcli delete cluster <name> [-y]
kcli create cluster k3s --paramfile <plan.yml>
```

---

## kcli Plan YAML Conventions

When creating or editing `.yml` plan files, follow the structure of `k3s-single.yml`:

```yaml
cluster: <cluster-name>
domain: lab.aymantech.net
ctlplanes: <n>
workers: <n>
image: centos9stream
numcpus: <n>
memory: <MB>
disk_size: <GB>
network: vmbr0
pool: local-lvm
```

---

## Workflow: Writing a New Helper Script

1. Read any existing scripts with `read_file` to follow established patterns.
2. Apply the authoring rules above.
3. Choose the right pattern from the **Scripting Patterns** section above.
4. Use `write_file` for new scripts, `apply_diff` for edits.
5. Make the file executable: run `chmod +x <script>.sh` via `execute_command`.

## Workflow: Editing an Existing Script

1. Read the target file first with `read_file`.
2. Make the minimal targeted change using `apply_diff`.
3. Do not reformat or refactor unrelated parts of the file.
