# VM Cloner

Clone multiple VMware virtual machines to a different datastore as a backup.

Uses PowerCLI `New-VM` to create full clones (thin disks by default). With backup mode enabled, clone names are dated so you keep a history without colliding with the source VM names.

## Requirements

- VMware PowerCLI (or PowerShell with the VMware snap-in)
- Access to a vCenter server
- Target folder, datastore, and resource pool already exist

## Setup

1. Copy this folder to a machine that can reach vCenter.
2. Edit `vm-cloner.ps1` and set the values below.
3. Set `$DebugMode = "False"` when you are ready to clone for real.

### vCenter

| Variable | Example | Notes |
|----------|---------|--------|
| `$vCenter` | `"vc.domain"` | vCenter hostname |
| `$UserName` | `""` | Leave blank to use current credentials |
| `$Password` | `""` | Used only when `$UserName` is set |

### Source and targets

| Variable | Example | Notes |
|----------|---------|--------|
| `$SourceFolder` | `"Production"` | vCenter folder whose VMs will be cloned |
| `$Datastore` | `"ESX1"` | Target datastore for clone disks |
| `$TargetFolder` | `"AutoBackup"` | Existing vCenter folder for clones |
| `$Datacenter` | `"DC1"` | Datacenter name |
| `$TargetResourcePool` | `"AutoBackup"` | Existing resource pool for clones |
| `$TargetHost` | `""` | ESXi host; blank = same host as the source VM |

### Behavior

| Variable | Default | Notes |
|----------|---------|--------|
| `$Backup` | `"True"` | `"True"` appends `-Backup-YYYY-MM-DD` to the clone name |
| `$DebugMode` | `"True"` | `"True"` logs intent but does not create clones |

## What it does

1. Connects to vCenter.
2. Lists every VM in `$SourceFolder`.
3. Clones each VM to `$Datastore` / `$TargetFolder` / `$TargetResourcePool`.
4. Writes a dated log file (`VM-Cloner-YYYY-MM-DD.txt`).

---

Author: [RaveMaker](http://ravemaker.net)
