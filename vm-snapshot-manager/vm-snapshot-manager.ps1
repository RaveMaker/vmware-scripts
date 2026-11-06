# PowerShell/PowerCLI - vmware-scripts/vm-snapshot-manager/vm-snapshot-manager.ps1
# List or create/rotate managed VMware VM snapshots.
#
# by RaveMaker - http://ravemaker.net

# use PowerCLI/PowerShell Switches
$CLIMode = "PowerCLI"

# Establish Connection
if ($CLIMode -eq "PowerShell") {
	# Add the VMware snapin for PowerShell - not needed for VMware PowerCLI
	Add-PSSnapin VMware.VimAutomation.Core
}

# Mode = List  : Show all snapshots; highlight manually created ones.
# Mode = Create: Rotate managed snapshots and create a new one.
$Mode = "List"

# Max managed snapshots to keep per VM (Create mode).
$MaxSnapshots = 2

# Memory = True  : Include VM memory in the snapshot.
# Memory = False : Disk-only snapshot.
$Memory = "False"

# Quiesce = True  : Quiesce guest file system via VMware Tools (VSS).
# Quiesce = False : Crash-consistent snapshot (no quiesce).
$Quiesce = "False"

# DebugMode = True  : Will not create or remove snapshots.
# DebugMode = False : Will create/remove as needed.
$DebugMode = "True"

# Managed snapshot name prefix / format:
# vm-snapshot-manager-snapshot-DATE-yy-mm-dd--HOUR-hh-mm-ss
$SnapshotPrefix = "vm-snapshot-manager-snapshot-"

# Get current date/time for log and new snapshot names.
$RunDate = (Get-Date -uformat %Y-%m-%d)
$SnapshotStamp = (Get-Date -uformat "DATE-%y-%m-%d--HOUR-%H-%M-%S")

# Log File.
$LogFile = "VM-Snapshot-Manager-" + $RunDate + ".txt"
echo "Snapshot manager started at ($RunDate) mode=$Mode - ($LogFile)" >> $LogFile

# vCenter Server and Credentials - leave blank to use without user and password
$vCenter = "vc-hostname.domain"
$UserName = ""
$Password = ""

# Establish Connection
if ($UserName -eq "") {
  Connect-VIServer -server $vCenter
}
else {
  Connect-VIServer -server $vCenter -user $UserName -password $Password
}

# SourceFolder is a folder in your vCenter structure.
$SourceFolder = "Production"

# Get servers list from the Source Folder
$VMwareServers = Get-VM -Location $SourceFolder

function Test-ManagedSnapshotName {
  param([string]$Name)
  # Match: vm-snapshot-manager-snapshot-DATE-yy-mm-dd--HOUR-hh-mm-ss
  return $Name -match "^vm-snapshot-manager-snapshot-DATE-\d{2}-\d{2}-\d{2}--HOUR-\d{2}-\d{2}-\d{2}$"
}

function Get-ManagedSnapshotSortKey {
  param([string]$Name)
  if ($Name -match "DATE-(\d{2})-(\d{2})-(\d{2})--HOUR-(\d{2})-(\d{2})-(\d{2})") {
    return "20$($Matches[1])$($Matches[2])$($Matches[3])$($Matches[4])$($Matches[5])$($Matches[6])"
  }
  return $Name
}

echo "Begin ($SourceFolder) mode=$Mode" >> $LogFile

foreach ($VM in $VMwareServers) {
  $VMName = $VM.Name
  Write-Host -ForegroundColor Cyan "==== $VMName ===="

  $AllSnapshots = @(Get-Snapshot -VM $VM -ErrorAction SilentlyContinue)

  if ($AllSnapshots.Count -eq 0) {
    Write-Host "  (no snapshots)"
    echo "$VMName : no snapshots" >> $LogFile
  }

  $ManagedSnapshots = @()
  foreach ($Snap in $AllSnapshots) {
    $IsManaged = Test-ManagedSnapshotName -Name $Snap.Name
    if ($IsManaged) {
      $ManagedSnapshots += $Snap
      Write-Host -ForegroundColor Green "  [managed] $($Snap.Name)  created=$($Snap.Created)"
      echo "$VMName : managed snapshot $($Snap.Name)" >> $LogFile
    }
    else {
      Write-Host -ForegroundColor Yellow "  !!! MANUAL SNAPSHOT !!! $($Snap.Name)  created=$($Snap.Created)"
      Write-Host -ForegroundColor Yellow "      Description: $($Snap.Description)"
      echo "$VMName : MANUAL snapshot $($Snap.Name) created=$($Snap.Created)" >> $LogFile
    }
  }

  if ($Mode -ne "Create") {
    continue
  }

  # Create mode: only touch managed snapshots; never remove manual ones.
  Write-Host -ForegroundColor Green "Create/rotate for $VMName (max=$MaxSnapshots, memory=$Memory, quiesce=$Quiesce)"

  # Sort managed oldest-first using name stamp (fallback: Created).
  $ManagedSorted = @(
    $ManagedSnapshots | Sort-Object @{
      Expression = { Get-ManagedSnapshotSortKey -Name $_.Name }
    }, Created
  )

  while ($ManagedSorted.Count -ge $MaxSnapshots) {
    $Oldest = $ManagedSorted[0]
    Write-Host -ForegroundColor Magenta "  Removing oldest managed snapshot: $($Oldest.Name)"
    echo "$VMName : removing oldest managed $($Oldest.Name)" >> $LogFile

    if ($DebugMode -ne "True") {
      Remove-Snapshot -Snapshot $Oldest -Confirm:$false -ErrorAction Stop
    }
    else {
      Write-Host -ForegroundColor DarkYellow "  [DebugMode] skip remove $($Oldest.Name)"
    }

    $ManagedSorted = @($ManagedSorted | Select-Object -Skip 1)
  }

  $NewName = $SnapshotPrefix + $SnapshotStamp
  Write-Host -ForegroundColor Green "  Creating snapshot: $NewName"
  echo "$VMName : creating $NewName memory=$Memory quiesce=$Quiesce" >> $LogFile

  if ($DebugMode -ne "True") {
    $NewSnapParams = @{
      VM          = $VM
      Name        = $NewName
      Description = "Created by vm-snapshot-manager"
      Memory      = ($Memory -eq "True")
      Quiesce     = ($Quiesce -eq "True")
      Confirm     = $false
    }
    New-Snapshot @NewSnapParams -ErrorAction Stop

    if (Get-Snapshot -VM $VM -Name $NewName -ErrorAction SilentlyContinue) {
      echo "$VMName : created $NewName OK" >> $LogFile
      Write-Host -ForegroundColor Green "  Created $NewName"
    }
    else {
      echo "$VMName : FAILED creating $NewName" >> $LogFile
      Write-Host -ForegroundColor Red "  Failed creating $NewName"
    }
  }
  else {
    Write-Host -ForegroundColor DarkYellow "  [DebugMode] skip create $NewName"
    echo "$VMName : DebugMode skip create $NewName" >> $LogFile
  }
}

echo "Snapshot manager finished at $(Get-Date)" >> $LogFile
Write-Host -ForegroundColor Cyan "Done. Log: $LogFile"
