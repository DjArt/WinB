#region Images
$W81ARM = "arm\Images\W_8.1_ARM.wim"
$W10ARM = "arm\Images\W_10.0.16299.15.wim"
$W10ARM64 = "arm64\Images\W_10.0.16299.15.wim"
$W10PEARM = "arm\Images\W_10.0.16299.15_PE.wim"
$W10IOTARM = "arm\Images\W_10.0.16299.15_IoT.vhd"
#endregion

function Check-Files
{
  $prep = $true
  $files = 
"$W10ARM64
$W81ARM
$W10IOTARM
$W10PEARM".Replace("`r", "").Split("`n")
  for ($i0 = 0; $i0 -lt $files.Length; $i0++)
  {
    $file = $files[$i0]
    if (Test-Path "..\source\$file")
    {

    }
    else
    {
      $prep = $false
    }
  }
  return $prep
}

function Start-BuildWindows10ARM
{
  $ver = "10.0.16299.15"
  if (Check-Files)
  {
    $logsdir = "..\tmp"
    $wi = Get-WorkingIndex
	$unlockedacl = Get-Acl -Path $PSScriptRoot
    Write "Copying W81RTARM.wim"
    Copy-Item "..\source\$W81ARM" "..\tmp\$wi\W81RTARM.wim"
    Write "Copying W10PEARM.wim"
    Copy-Item "..\source\$W10PEARM" "..\tmp\$wi\W10PEARM.wim"
    Write "Copying W10ARM64.wim"
    Copy-Item "..\source\$W10ARM64" "..\tmp\$wi\W10ARM64.wim"
    Write "Copying W10IOTARM.vhd"
    Copy-Item "..\source\$W10IOTARM" "..\tmp\$wi\W10IOTARM.vhd"
	Set-ItemCompreesionFlag "..\tmp\$wi\W10IOTARM.vhd"

    Write "Mounting W10PEARM.wim"
    New-Item "..\tmp\$wi\W10PEARM" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\W10PEARM.wim" "..\tmp\$wi\W10PEARM"

    Write "Integrating drivers"
    foreach ($driverpack in (Get-ChildItem "..\source\arm\drivers" -Name -File -Filter "*.7z"))
    {
	  Write "Integrating $driverpack"
      New-Item "..\tmp\$wi\Drivers" -ItemType Directory > $null
      Extract-Item "..\source\arm\drivers\$driverpack" "..\tmp\$wi\Drivers" > $null
      Add-DriversToImage "..\tmp\$wi\W10PEARM" "..\tmp\$wi\Drivers"
      Remove-Item "..\tmp\$wi\Drivers" -Recurse -Force > $null
    }

    Write "Integrating packages"
    Add-PackagesToImage "..\tmp\$wi\W10PEARM" "..\source\arm\Packages\$ver"
	
	$to = "..\tmp\$wi\W10PEARM"
	$toSystem = "HKLM:\"+"$wi"+"_W10PEARM_SYSTEM"
	$toSoftware = "HKLM:\"+"$wi"+"_W10PEARM_SOFTWARE"
	Mount-Hive "$to\Windows\System32\Config\SYSTEM" $toSystem.Replace(":","")
	Mount-Hive "$to\Windows\System32\Config\SOFTWARE" $toSoftware.Replace(":","")

    Write "Mounting W10ARM64.wim"
    New-Item "..\tmp\$wi\W10ARM64" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\W10ARM64.wim" "..\tmp\$wi\W10ARM64"
	$from = "..\tmp\$wi\W10ARM64"
	$fromSystem = "HKLM:\"+"$wi"+"_W10ARM64_SYSTEM"
	$fromSoftware = "HKLM:\"+"$wi"+"_W10ARM64_SOFTWARE"
	Mount-Hive "$from\Windows\System32\Config\SYSTEM" $fromSystem.Replace(":","")
	Mount-Hive "$from\Windows\System32\Config\SOFTWARE" $fromSoftware.Replace(":","")
	Read-Host "Check registry and continue"
	
###############################################################################
Write "Copy missing files to Windows"
###############################################################################
Copy-Item -Recurse "$from\Windows\Fonts" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\GameBarPresenceWriter" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\Globalization" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\Help" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\InfusedApps" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\InputMethod" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\L2Schemas" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\OCR" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\PLA" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\PolicyDefinitions" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\Resources" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\Schemas" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\Security" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\SKB" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\SysArm32\explorer.exe" "$to\Windows\explorer.exe"
Copy-Item -Recurse "$from\Windows\System" "$to\Windows\"
Copy-Item -Recurse "$from\Windows\SystemResources" "$to\Windows\"
Copy-Item -Recurse -Force "$from\Program Files\Program Files (Arm)" "$to\Windows\Program Files"
###############################################################################

###############################################################################
Write "Copy missing files to Windows\System32"
###############################################################################
$excluded = "Drivers","DriverStore"
$diff = Compare-Object2 -ReferenceObject (Get-ChildItem -Name -Exclude $excluded -Path "$from\Windows\SysArm32") -DifferenceObject (Get-ChildItem -Name -Exclude $excluded -Path "$to\Windows\System32")  | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
Write $diff > "$logsdir\diff-w10arm64.log"
foreach ($item in $diff)
{
  Copy-Item -Recurse "$from\Windows\SysArm32\$item" "$to\Windows\System32\$item"
}
###############################################################################

###############################################################################
Write "Copy ARM apps"
###############################################################################
New-Item "$to\Windows\SystemApps" -ItemType Directory > $null
Copy-Item -Recurse "$from\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" "$to\Windows\SystemApps\"
###############################################################################

###############################################################################
Write "Replacing some files"
###############################################################################
Copy-Item -Recurse -Force "$from\Windows\Setup" "$to\Windows\"
Copy-Item "$from\Windows\SysArm32\taskmgr.exe" "$to\Windows\System32\taskmgr.exe"
###############################################################################

###############################################################################
Write "Copy registry chunks from SYSTEM"
###############################################################################
Copy-Item -Recurse "$fromSystem\ActivationBroker" "$toSystem\"
Copy-Item -Recurse -Force "$fromSystem\ControlSet001\Control" "$toSystem\ControlSet001\"
Copy-Item -Recurse -Force "$fromSystem\ControlSet001\Services" "$toSystem\ControlSet001\"
Copy-Item -Recurse "$fromSystem\Input" "$toSystem\"
Copy-Item -Recurse "$fromSystem\Maps" "$toSystem\"
Copy-Item -Recurse "$fromSystem\ResourceManager" "$toSystem\"
Copy-Item -Recurse "$fromSystem\ResourcePolicyStore" "$toSystem\"
Copy-Item -Recurse -Force "$fromSystem\Setup" "$toSystem\"
Copy-Item -Recurse -Force "$fromSystem\Software" "$toSystem\"
###############################################################################

###############################################################################
Write "Removing unavailable services from SYSTEM\ControlSet001\Services"
###############################################################################
Remove-Item -Force "$toSystem\ControlSet001\Services\iorate"
Remove-Item -Force "$toSystem\ControlSet001\Services\stornvme"
###############################################################################

###############################################################################
Write "Copy registry chunks from SOFTWARE"
###############################################################################
Copy-Item -Recurse -Force "$fromSoftware\Classes" "$toSoftware\"
Copy-Item -Recurse "$fromSoftware\Clients" "$toSoftware\"
Copy-Item -Recurse -Force "$fromSoftware\Microsoft" "$toSoftware\"
Copy-Item -Recurse -Force "$fromSoftware\Policies" "$toSoftware\"
Copy-Item -Recurse "$fromSoftware\RegisteredApplications" "$toSoftware\"
###############################################################################

###############################################################################
Write "Patching wrong data in SOFTWARE\Microsoft"
###############################################################################
Remove-Item -Force "$toSoftware\Microsoft\Wow64"
New-ItemProperty -Path "$toSoftware\Microsoft\Windows NT\CurrentVersion" -Name "BuildLabEx" -Value "16299.15.armfre.rs3_release.170928-1534"
Remove-Item -Force "$toSoftware\Microsoft\Windows\CurrentVersion\CommonFilesDir (Arm)"
Remove-Item -Force "$toSoftware\Microsoft\Windows\CurrentVersion\CommonFilesDir (x86)"
Remove-Item -Force "$toSoftware\Microsoft\Windows\CurrentVersion\ProgramFilesDir (Arm)"
Remove-Item -Force "$toSoftware\Microsoft\Windows\CurrentVersion\ProgramFilesDir (x86)"
###############################################################################

    Write "Unmounting W10ARM64.wim"
	Unmount-Hive $fromSystem.Replace(":","")
	Unmount-Hive $fromSoftware.Replace(":","")
    Discard-Image "..\tmp\$wi\W10ARM64"
	Remove-Item "..\tmp\$wi\SYSTEM"
	Remove-Item "..\tmp\$wi\SOFTWARE"
    Remove-Item "..\tmp\$wi\W10ARM64" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\W10ARM64.wim" -Force > $null

    Write "Mounting W10IOTARM.vhd"
    New-Item "..\tmp\$wi\W10IOTARM" -ItemType Directory > $null
    Mount-VHD (Get-Item "..\tmp\$wi\W10IOTARM.vhd").FullName (Get-Item "..\tmp\$wi\W10IOTARM").FullName "..\tmp\$wi"
	Start-Sleep -s 5
	$from = "..\tmp\$wi\W10IOTARM"
	$fromSystem = "HKLM:\"+"$wi"+"_W10IOTARM_SYSTEM"
	$fromSoftware = "HKLM:\"+"$wi"+"_W10IOTARM_SOFTWARE"
	Mount-Hive "$from\Windows\System32\Config\SYSTEM" $fromSystem.Replace(":","")
	Mount-Hive "$from\Windows\System32\Config\SOFTWARE" $fromSoftware.Replace(":","")
	Read-Host "Check registry and continue"
	
###############################################################################
# PCIIdle driver - not included to WinPE
Write "Adding PCIIdle driver"
###############################################################################
Copy-Item "$from\Windows\System32\Drivers\pciidle.sys" "$to\Windows\System32\Drivers\pciidle.sys"
###############################################################################

###############################################################################
# IntelIdle driver - not included to WinPE
Write "Adding IntelIdle driver"
###############################################################################
Copy-Item "$from\Windows\System32\Drivers\intelidle.sys" "$to\Windows\System32\Drivers\intelidle.sys"
###############################################################################

###############################################################################
# ATAPI driver - not included to WinPE
Write "Adding ATAPI driver"
###############################################################################
Copy-Item "$from\Windows\System32\Drivers\atapi.sys" "$to\Windows\System32\Drivers\atapi.sys"
###############################################################################

###############################################################################
# StorACHI driver - not include to WinPE
Write "Adding StorACHI driver"
###############################################################################
Copy-Item "$from\Windows\System32\Drivers\storahci.sys" "$to\Windows\System32\Drivers\storahci.sys"
###############################################################################

###############################################################################
Write "Copy missing files to Windows\System32"
###############################################################################
$excluded = "Drivers","DriverStore"
$diff = Compare-Object2 -ReferenceObject (Get-ChildItem -Name -Exclude $excluded -Path "$from\Windows\System32") -DifferenceObject (Get-ChildItem -Name -Exclude $excluded -Path "$to\Windows\System32")  | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
foreach ($item in $diff)
{
  Copy-Item -Recurse "$from\Windows\System32\$item" "$to\Windows\System32\$item"
}
###############################################################################

###############################################################################
Write "Copy ARM apps"
###############################################################################
Copy-Item -Recurse "$from\Windows\SystemApps\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy" "$to\Windows\SystemApps\"
Copy-Item -Recurse "$from\Windows\SystemApps\Microsoft.AccountsControl_cw5n1h2txyewy" "$to\Windows\SystemApps\"
Copy-Item -Recurse "$from\Windows\SystemApps\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy" "$to\Windows\SystemApps\"
Copy-Item -Recurse "$from\Windows\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy" "$to\Windows\SystemApps\"
###############################################################################

    Write "Unmounting W10IOTARM.vhd"
	Unmount-Hive $fromSystem.Replace(":","")
	Unmount-Hive $fromSoftware.Replace(":","")
    Unmount-VHD (Get-Item "..\tmp\$wi\W10IOTARM.vhd").FullName "..\tmp\$wi\W10IOTARM" "..\tmp\$wi"
	Remove-Item "..\tmp\$wi\SYSTEM"
	Remove-Item "..\tmp\$wi\SOFTWARE"
    Remove-Item "..\tmp\$wi\W10IOTARM" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\W10IOTARM.vhd" -Force > $null
	
	Write "Mounting W81RTARM.wim"
    New-Item "..\tmp\$wi\W81RTARM" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\W81RTARM.wim" "..\tmp\$wi\W81RTARM"
	$from = "..\tmp\$wi\W81RTARM"
	$fromSystem = "HKLM:\"+"$wi"+"_W81RTARM_SYSTEM"
	$fromSoftware = "HKLM:\"+"$wi"+"_W81RTARM_SOFTWARE"
	Mount-Hive "$from\Windows\System32\Config\SYSTEM" $fromSystem.Replace(":","")
	Mount-Hive "$from\Windows\System32\Config\SOFTWARE" $fromSoftware.Replace(":","")
	Read-Host "Check registry and continue"
	
###############################################################################
# SDBus driver - Surface RT won't boot without this
###############################################################################
Copy-Item -Force "$from\Windows\System32\Drivers\sdbus.sys" "$to\Windows\System32\Drivers\sdbus.sys"
Copy-Item -Force "$from\Windows\System32\Drivers\dumpsd.sys" "$to\Windows\System32\Drivers\dumpsd.sys"
Copy-Item -Recurse "$from\Windows\System32\DriverStore\FileRepository\sdbus.inf_arm_19c0b9eb981e116f" "$to\Windows\System32\DriverStore\FileRepository\"
Copy-Item -Force "$from\Windows\inf\sdbus.inf" "$to\Windows\inf\sdbus.inf"
Copy-Item -Recurse -Force "$fromSystem\DriverDatabase\DriverInfFiles\sdbus.inf" "$toSystem\DriverDatabase\DriverInfFiles\sdbus.inf"
Copy-Item -Recurse "$fromSystem\DriverDatabase\DriverPackages\sdbus.inf_arm_19c0b9eb981e116f" "$toSystem\DriverDatabase\DriverPackages\"
###############################################################################

###############################################################################
# ReadyBoost driver - not aviliable in other Windows 10 ARM builds
###############################################################################
Copy-Item "$from\Windows\System32\Drivers\rdyboost.sys" "$to\Windows\System32\Drivers\rdyboost.sys"
###############################################################################

    Write "Unmonting W81RTARM.wim"
	Unmount-Hive $fromSystem.Replace(":","")
	Unmount-Hive $fromSoftware.Replace(":","")
    Discard-Image "..\tmp\$wi\W81RTARM"
	Remove-Item "..\tmp\$wi\SYSTEM"
	Remove-Item "..\tmp\$wi\SOFTWARE"
    Remove-Item "..\tmp\$wi\W81RTARM" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\W81RTARM.wim" -Force > $null

    Write "Umounting W10ARM.wim"
	Unmount-Hive $toSystem.Replace(":","")
	Unmount-Hive $toSoftware.Replace(":","")
    Unmount-Image "..\tmp\$wi\W10PEARM"
    Remove-Item "..\tmp\$wi\W10PEARM" -Recurse -Force > $null

    Move-Item "..\tmp\$wi\W10PEARM.wim" "..\source\$W10ARM"
    Remove-Item "..\tmp\$wi" -Recurse -Force > $null
    Write "Done!"
  }
  else
  {
    Write "Obtain required files and restart this script"
  }
  Read-Host "Press Enter to continue"
}