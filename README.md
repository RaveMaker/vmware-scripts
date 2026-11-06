# VMware Scripts

PowerCLI / PowerShell utilities for day-to-day VMware admin work — backups via full VM clones, and managed snapshot rotation.

## Scripts

| Script | Folder | Purpose |
|--------|--------|---------|
| **VM Cloner** | [`vm-cloner/`](vm-cloner/) | Clone all VMs in a folder to another datastore (dated backup clones) |
| **VM Snapshot Manager** | [`vm-snapshot-manager/`](vm-snapshot-manager/) | List snapshots (flag manual ones) or create/rotate managed snapshots |

Each folder has its own README with config details.

## Requirements

- [VMware PowerCLI](https://developer.broadcom.com/powercli)
- Network access to your vCenter
- An account that can perform the actions each script needs (clone VMs, create/remove snapshots)

## Quick start

1. Open the script folder you want to use.
2. Edit the `.ps1` file — set `$vCenter`, folders, and other config at the top.
3. Leave `$DebugMode = "True"` for a dry run, then set it to `"False"` to execute.
4. Run from PowerCLI / PowerShell:

```powershell
cd .\vm-cloner
.\vm-cloner.ps1

cd .\vm-snapshot-manager
.\vm-snapshot-manager.ps1
```

## Notes

- Scripts are configured by editing variables in the `.ps1` files (no CLI args yet).
- Each run appends to a dated log file in the working directory.
- Snapshot Manager never removes manually created snapshots — only names matching its managed format.

---

Author: [RaveMaker](http://ravemaker.net)
