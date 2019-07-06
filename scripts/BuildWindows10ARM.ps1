$W81 = "W_6.3.9600.0"
$W10 = "W_10.0.18362.1"
$WPE = "WPE_10.0.18362.1"
$WIOT = "WIOT_10.0.17763.1"
$WM = "WM_10.0.15254.530"
$wi = Get-WorkingIndex

function Get-Path([string]$item)
{
    $folderStruct = $item -split '\\'
    if ($folderStruct.Length -eq 1)
    {
        $folderStruct = ""
    }
    else
    {
        $folderStruct = ($folderStruct[0 .. ($folderStruct.Length - 2)] -join '\') + '\'
    }
    return $folderStruct
}

function Prepare-Environment
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 1: Preparing environment ---"

    Write " Working directory is: $wi" 

    New-Item "..\logs\$wi" -ItemType Directory > $null

    Write " Copying Windows 8.1 ARM Image: $W81"
    Copy-Item "..\source\arm\Images\$W81.wim" "..\tmp\$wi\$W81.wim"
    Write " Copying Windows 10 ARM64 Image: $W10"
    Copy-Item "..\source\arm64\Images\$W10.wim" "..\tmp\$wi\$W10.wim"
    Write " Copying Windows 10 PE ARM Image: $WPE"
    Copy-Item "..\source\arm\Images\$WPE.wim" "..\tmp\$wi\$WPE.wim"
    Write " Copying Windows 10 IoT ARM Image: $WIOT"
    Copy-Item "..\source\arm\Images\$WIOT.wim" "..\tmp\$wi\$WIOT.wim"
    Write " Copying Windows 10 Mobile ARM Image: $WM"
    Copy-Item "..\source\arm\Images\$WM.wim" "..\tmp\$wi\$WM.wim"

    Write " Mounting $W81"
    New-Item "..\tmp\$wi\$W81" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$W81.wim" "..\tmp\$wi\$W81"
    Write " Mounting $W10"
    New-Item "..\tmp\$wi\$W10" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$W10.wim" "..\tmp\$wi\$W10"
    Write " Mounting $WPE"
    New-Item "..\tmp\$wi\$WPE" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$WPE.wim" "..\tmp\$wi\$WPE"
    Write " Mounting $WIOT"
    New-Item "..\tmp\$wi\$WIOT" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$WIOT.wim" "..\tmp\$wi\$WIOT"
    Write " Mounting $WM"
    New-Item "..\tmp\$wi\$WM" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$WM.wim" "..\tmp\$wi\$WM"
}

function Integrate-CABs
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 2: Integrating Packages  ---"
    Add-PackagesToImage "..\tmp\$wi\$WPE" "..\source\arm\Packages"
}

function Merge-Images
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 3: Merging images        ---"

    # TO EXCLUDE: $excluded = @("Drivers\*","DriverStore\*","Config\*","catroot\*","catroot2\*")

    Write " Obtain System32 files list"
    Write "  Obtain $W10 System32 files list"
    $Original_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$W10\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $WPE System32 files list"
    $WPE_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$WPE\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $W10 SysArm32 files list"
    $W10_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$W10\Windows\SysArm32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $WIOT System32 files list"
    $WIOT_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$WIOT\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $WM System32 files list"
    $WM_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$WM\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $W81 System32 files list"
    $W81_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$W81\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }

    Write " Comparing lists"
    $Diff0 = Compare-Object2 -IncludeEqual -ReferenceObject $Original_List -DifferenceObject $WPE_List | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Comp1 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff0 -DifferenceObject $W10_List
    $Diff1 = $Comp1 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy1 = $Comp1 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp2 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff1 -DifferenceObject $WIOT_List
    $Diff2 = $Comp2 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy2 = $Comp2 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp3 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff2 -DifferenceObject $WM_List
    $Diff3 = $Comp3 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy3 = $Comp3 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp4 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff3 -DifferenceObject $W81_List
    $Diff4 = $Comp4 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy4 = $Comp4 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}

    Write $Copy1 > "..\logs\$wi\Copy from $W10 System32.log"
    Write $Copy2 > "..\logs\$wi\Copy from $WIOT System32.log"
    Write $Copy3 > "..\logs\$wi\Copy from $WM System32.log"
    Write $Copy4 > "..\logs\$wi\Copy from $W81 System32.log"
    Write $Diff4 > "..\logs\$wi\Not exist in System32.log"
    Write $Comp1 > "..\logs\$wi\Comp1 in System32.log"
    Write $Comp2 > "..\logs\$wi\Comp2 in System32.log"
    Write $Comp3 > "..\logs\$wi\Comp3 in System32.log"
    Write $Comp4 > "..\logs\$wi\Comp4 in System32.log"

    Write " Merging files"
    Write "  Copying from $W10"
    foreach ($item in $Copy1)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Recurse -Force -Verbose "..\tmp\$wi\$W10\Windows\SysArm32\$item" "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Fonts" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\GameBarPresenceWriter" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Globalization" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Help" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\InputMethod" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\L2Schemas" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\OCR" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\PLA" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\PolicyDefinitions" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Resources" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Schemas" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Security" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\SKB" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\SysArm32\explorer.exe" "..\tmp\$wi\$WPE\Windows\explorer.exe"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\System" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\SystemResources" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\Setup" "..\tmp\$wi\$WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$W10\Windows\SysArm32\taskmgr.exe" "..\tmp\$wi\$WPE\Windows\System32\taskmgr.exe"
    Write "  Copying from $WIOT"
    foreach ($item in $Copy2)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$WIOT\Windows\System32\$item" "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "  Copying from $WM"
    foreach ($item in $Copy3)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$WM\Windows\System32\$item" "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "  Copying from $W81"
    foreach ($item in $Copy4)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$W81\Windows\System32\$item" "..\tmp\$wi\$WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }

    # TODO: Registry checking
    Write " Copying ARM desktop applications"
    Write "  Obtain $W81 applications list"
    $W81_List = Get-ChildItem -Name -Exclude "WindowsApps" -Path "..\tmp\$wi\$W81\Program Files"
    Write "  Copying $W81 applications"
    foreach ($item in $W81_List)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$WPE\Program Files\$folderStruct" > $null
        Copy-Item -Recurse -Force -Verbose "..\tmp\$wi\$W81\Program Files\$item" "..\tmp\$wi\$WPE\Program Files\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "  Obtain $W10 applications list"
    $W10_List = Get-ChildItem -Name -Exclude "WindowsApps" -Path "..\tmp\$wi\$W10\Program Files"
    Write "  Copying $W10 applications"
    foreach ($item in $W10_List)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$WPE\Program Files\$folderStruct" > $null
        Copy-Item -Recurse -Force -Verbose "..\tmp\$wi\$W10\Program Files\$item" "..\tmp\$wi\$WPE\Program Files\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }

    # TODO: UWP Apps
}

function Construct-Registry
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 4: Constructing registry ---"

    Write " Storing registry from $WPE"
    Copy-Item "..\tmp\$wi\$WPE\Windows\System32\Config\SYSTEM" "..\tmp\$wi\SYSTEM"
    Write " Copying registry from $W10"
    Copy-Item -Force "..\tmp\$wi\$W10\Windows\System32\Config\SOFTWARE" "..\tmp\$wi\$WPE\Windows\System32\Config\SOFTWARE"
    Copy-Item -Force "..\tmp\$wi\$W10\Windows\System32\Config\SYSTEM" "..\tmp\$wi\$WPE\Windows\System32\Config\SYSTEM"

    Write " Mounting registry"
    $R_OR = "HKLM:\"+"$wi"+"_OR"
    $R_SY = "HKLM:\"+"$wi"+"_SY"
	$R_SO = "HKLM:\"+"$wi"+"_SO"
	Mount-Hive "..\tmp\$wi\$WPE\Windows\System32\Config\SYSTEM" $R_SY.Replace(":","")
	Mount-Hive "..\tmp\$wi\$WPE\Windows\System32\Config\SOFTWARE" $R_SO.Replace(":","")
	Mount-Hive "..\tmp\$wi\SYSTEM" $R_OR.Replace(":","")

    Write " Fixing DriverDatabase"
    Remove-Item -Force -Recurse "$R_SY\DriverDatabase"
    Copy-Item -Recurse -Force "$R_OR\DriverDatabase" "$R_SY\DriverDatabase"

    Write " Fixing OSExtensionDatabase"
    Remove-Item -Force -Recurse "$R_SY\ControlSet001\Control\OSExtensionDatabase"
    Copy-Item -Recurse -Force "$R_OR\ControlSet001\Control\OSExtensionDatabase" "$R_SY\ControlSet001\Control\OSExtensionDatabase"

    Write " Clean SysWOW"
    Remove-Item -Force -Recurse "$R_SO\WOW6432Node"
    Remove-Item -Force -Recurse "$R_SO\WowAA32Node"

    [gc]::Collect()
    Start-Sleep 5

    Write " Unmounting registry"
    Unmount-Hive $R_OR.Replace(":","")
    Unmount-Hive $R_SO.Replace(":","")
    Unmount-Hive $R_SY.Replace(":","")
}

function Integrate-Drivers
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 5: Integrating drivers   ---"

    foreach ($driverpack in (Get-ChildItem "..\source\arm\drivers" -Name -File -Filter "*.7z"))
    {
	  Write " Integrating $driverpack"
      New-Item "..\tmp\$wi\Drivers" -ItemType Directory > $null
      Extract-Item "..\source\arm\drivers\$driverpack" "..\tmp\$wi\Drivers" > $null
      Add-DriversToImage "..\tmp\$wi\$WPE" "..\tmp\$wi\Drivers"
      Remove-Item "..\tmp\$wi\Drivers" -Recurse -Force > $null
    }

    Write " Merging drivers"
    Write "  Mounting registry"
    $R_WPE = "HKLM:\"+"$wi"+"_WPE"
    $R_WIOT = "HKLM:\"+"$wi"+"_WIOT"
    $R_WM = "HKLM:\"+"$wi"+"_WM"
    $R_W81 = "HKLM:\"+"$wi"+"_W81"
	Mount-Hive "..\tmp\$wi\$WPE\Windows\System32\Config\SYSTEM" $R_WPE.Replace(":","")
    Mount-Hive "..\tmp\$wi\$WIOT\Windows\System32\Config\SYSTEM" $R_WIOT.Replace(":","")
    Mount-Hive "..\tmp\$wi\$WM\Windows\System32\Config\SYSTEM" $R_WM.Replace(":","")
    Mount-Hive "..\tmp\$wi\$W81\Windows\System32\Config\SYSTEM" $R_W81.Replace(":","")

    Write "  Obtain drivers list"
    Write "   Obtain $W10 drivers list"
    $excluded = ""
    $Original_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$W10\Windows\System32\Drivers"
    Write "   Obtain $WPE drivers list"
    $WPE_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$WPE\Windows\System32\Drivers"
    Write "   Obtain $WIOT drivers list"
    $WIOT_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$WIOT\Windows\System32\Drivers"
    Write "   Obtain $WM drivers list"
    $WM_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$WM\Windows\System32\Drivers"
    Write "   Obtain $W81 drivers list"
    $W81_List = Get-ChildItem -File -Recurse -Path "..\tmp\$wi\$W81\Windows\System32\Drivers"

    Write "  Comparing lists"
    $Diff0 = Compare-Object2 -IncludeEqual -ReferenceObject $Original_List -DifferenceObject $WPE_List | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Comp1 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff0 -DifferenceObject $WIOT_List
    $Diff1 = $Comp1 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy1 = $Comp1 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp2 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff1 -DifferenceObject $WM_List
    $Diff2 = $Comp2 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy2 = $Comp2 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp3 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff2 -DifferenceObject $W81_List
    $Diff3 = $Comp3 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy3 = $Comp3 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}

    Write $Copy1 > "..\logs\$wi\Copy from $WIOT Drivers.log"
    Write $Copy2 > "..\logs\$wi\Copy from $WM Drivers.log"
    Write $Copy3 > "..\logs\$wi\Copy from $W81 Drivers.log"
    Write $Diff3 > "..\logs\$wi\Not exist in Drivers.log"
    Write $Comp1 > "..\logs\$wi\Comp1 in Drivers.log"
    Write $Comp2 > "..\logs\$wi\Comp2 in Drivers.log"
    Write $Comp3 > "..\logs\$wi\Comp3 in Drivers.log"

    Write "  Merging files"
    Write "   Copying from $WIOT"
    foreach ($item in $Copy1)
    {
        Copy-Item -Verbose -Force -Recurse "..\tmp\$wi\$WIOT\Windows\System32\Drivers\$item" "..\tmp\$wi\$WPE\Windows\System32\Drivers\" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "   Copying from $WM"
    foreach ($item in $Copy2)
    {
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$WM\Windows\System32\Drivers\$item" "..\tmp\$wi\$WPE\Windows\System32\Drivers\" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "   Copying from $W81"
    foreach ($item in $Copy3)
    {
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$W81\Windows\System32\Drivers\$item" "..\tmp\$wi\$WPE\Windows\System32\Drivers\" 4>> "..\logs\$wi\copylog in System32.log"
    }

    Write "   Fixing registry"
    $Diff3 = $Diff3 | ? { -not $_.Contains("\") }
    Write $Diff3 > "..\logs\$wi\For remove Drivers.log"
    foreach ($item in $Diff3)
    {
        $item = $item.Split(".")[0]
        Remove-Item -Force -Recurse -Path "$R_WPE\ControlSet001\Services\$item"
    }

    [gc]::Collect()
    Start-Sleep 5

    Write "  Unmounting registry"
    Unmount-Hive $R_WPE.Replace(":","")
    Unmount-Hive $R_WIOT.Replace(":","")
    Unmount-Hive $R_WM.Replace(":","")
    Unmount-Hive $R_W81.Replace(":","")
}

function Clean-Environment
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 6: Cleanup               ---"

	Remove-Item "..\tmp\$wi\SYSTEM"

    Write " Unmounting $W10"
    Discard-Image "..\tmp\$wi\$W10"
    Remove-Item "..\tmp\$wi\$W10.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$W10" -Recurse -Force > $null

    Write " Unmounting $WIOT"
    Discard-Image "..\tmp\$wi\$WIOT"
    Remove-Item "..\tmp\$wi\$WIOT.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$WIOT" -Recurse -Force > $null

    Write " Unmounting $WM"
    Discard-Image "..\tmp\$wi\$WM"
    Remove-Item "..\tmp\$wi\$WM.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$WM" -Recurse -Force > $null

    Write " Unmounting $W81"
    Discard-Image "..\tmp\$wi\$W81"
    Remove-Item "..\tmp\$wi\$W81.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$W81" -Recurse -Force > $null

    Read-Host "Press Enter to finish building WIM and clean environment"

    Write " Unmounting $WPE"
    Unmount-Image "..\tmp\$wi\$WPE"
    Remove-Item "..\tmp\$wi\$WPE" -Recurse -Force > $null

    Move-Item "..\tmp\$wi\$WPE.wim" "..\out\$wi $W10.wim"

    Remove-Item -Force -Recurse "..\tmp\$wi"

    Write-Host -ForegroundColor Green "Done!"
    Write "Result file can be found in 'out' folder."
}

function Start-BuildWindows10ARM
{
    Prepare-Environment
    Integrate-CABs
    Merge-Images
    Construct-Registry
    Integrate-Drivers
    Clean-Environment
    Read-Host "Press Enter to continue"
}