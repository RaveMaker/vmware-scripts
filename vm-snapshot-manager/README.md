# VM Snapshot Manager

List all VM snapshots (and call out manual ones), or create/rotate managed snapshots.

Managed names look like:

```text
vm-snapshot-manager-snapshot-DATE-yy-mm-dd--HOUR-hh-mm-ss
```

Create mode only removes or creates snapshots with that format. Manually created snapshots are listed and highlighted, but never touched.

## Requirements

- VMware PowerCLI (or PowerShell with the VMware snap-in)
- Access to a vCenter server
- VMs live in the configured source folder

## Setup

1. Copy this folder to a machine that can reach vCenter.
2. Edit `vm-snapshot-manager.ps1` and set the values below.
3. Set `$DebugMode = "False"` when you are ready to create or remove snapshots.

### vCenter

| Variable | Example | Notes |
|----------|---------|--------|
| `$vCenter` | `"vc.domain"` | vCenter hostname |
| `$UserName` | `""` | Leave blank to use current credentials |
| `$Password` | `""` | Used only when `$UserName` is set |

### Scope and mode

| Variable | Default | Notes |
|----------|---------|--------|
| `$SourceFolder` | `"Production"` | vCenter folder whose VMs are processed |
| `$Mode` | `"List"` | `"List"` = inventory; `"Create"` = rotate + create |
| `$MaxSnapshots` | `2` | Max managed snapshots to keep per VM (Create mode) |

### Snapshot options

| Variable | Default | Notes |
|----------|---------|--------|
| `$Memory` | `"False"` | `"True"` includes VM memory in the snapshot |
| `$Quiesce` | `"False"` | `"True"` quiesces the guest via VMware Tools (VSS) |
| `$DebugMode` | `"True"` | `"True"` shows intended actions but does not create/remove |

## Modes

### List (default)

Shows every snapshot on each VM:

- **Managed** — matches the name format above
- **Manual** — anything else; printed loudly so you notice it

### Create / rotate

1. Count only managed snapshots.
2. While count ≥ `$MaxSnapshots`, remove the oldest managed snapshot.
3. Create a new managed snapshot.

Manual snapshots are ignored for the count and never removed.

---

Author: [RaveMaker](http://ravemaker.net)
