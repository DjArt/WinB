$global:W81 = "Windows 8.1 ARM"
$global:W10 = "Windows 10 ARM64"
$global:WPE = "Windows 10 PE ARM"
$global:WIOT = "Windows 10 IoT ARM"
$global:WM = "Windows 10 Mobile ARM"
$global:VERSION = ""
$wi = Get-WorkingIndex

function Check-Files()
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 0: Checking prerequirements ---"
    $test0 = Test-Path "..\source\arm\Images\$global:W81.wim"
    if (!$test0)
    {
        Write-Host -ForegroundColor Red " $global:W81 image is missing!"
    }
    $test1 = Test-Path "..\source\arm64\Images\$global:W10.wim"
    if (!$test1)
    {
        Write-Host -ForegroundColor Red " $global:W10 image is missing!"
    }
    $test0 = $test0 -and $test1
    $test1 = Test-Path "..\source\arm\Images\$global:WPE.wim"
    if (!$test1)
    {
        Write-Host -ForegroundColor Red " $global:WPE image is missing!"
    }
    $test0 = $test0 -and $test1
    $test1 = Test-Path "..\source\arm\Images\$global:WIOT.wim"
    if (!$test1)
    {
        Write-Host -ForegroundColor Red " $global:WIOT image is missing!"
    }
    $test0 = $test0 -and $test1
    $test1 = Test-Path "..\source\arm\Images\$global:WM.wim"
    if (!$test1)
    {
        Write-Host -ForegroundColor Red " $global:WM image is missing!"
    }
    $test0 = $test0 -and $test1
    return $test0;
}

function Select-BuildVersion()
{
    Write-Host "Select build version: "
    Write-Host "0: 10.0.16299"
    Write-Host "1: 10.0.17763"
    Write-Host "2: 10.0.18362"
    $choose = Read-Host -Prompt "Your choise"
    if ($choose -eq "0")
    {
        return "10.0.16299";
    }
    elseif ($choose -eq "1")
    {
        return "10.0.17763";
    }
    elseif ($choose -eq "2")
    {
        return "10.0.18362";
    }
}

function Set-BuildVersion()
{
    if ($global:VERSION -eq "10.0.18362")
    {
        $global:W81 = "W_6.3.9600"
        $global:W10 = "W_10.0.18362"
        $global:WPE = "WPE_10.0.18362"
        $global:WIOT = "WIOT_10.0.17763"
        $global:WM = "WM_10.0.15254"
    }
    elseif ($global:VERSION -eq "10.0.17763")
    {
        $global:W81 = "W_6.3.9600"
        $global:W10 = "W_10.0.17763"
        $global:WPE = "WPE_10.0.17763"
        $global:WIOT = "WIOT_10.0.17763"
        $global:WM = "WM_10.0.15254"
    }
    elseif ($global:VERSION -eq "10.0.16299")
    {
        $global:W81 = "W_6.3.9600"
        $global:W10 = "W_10.0.16299"
        $global:WPE = "WPE_10.0.16299"
        $global:WIOT = "WIOT_10.0.16299"
        $global:WM = "WM_10.0.15254"
    }
}

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

    Write " Copying Windows 8.1 ARM Image: $global:W81"
    Copy-Item "..\source\arm\Images\$global:W81.wim" "..\tmp\$wi\$global:W81.wim"
    Write " Copying Windows 10 ARM64 Image: $global:W10"
    Copy-Item "..\source\arm64\Images\$global:W10.wim" "..\tmp\$wi\$global:W10.wim"
    Write " Copying Windows 10 PE ARM Image: $global:WPE"
    Copy-Item "..\source\arm\Images\$global:WPE.wim" "..\tmp\$wi\$global:WPE.wim"
    Write " Copying Windows 10 IoT ARM Image: $global:WIOT"
    Copy-Item "..\source\arm\Images\$global:WIOT.wim" "..\tmp\$wi\$global:WIOT.wim"
    Write " Copying Windows 10 Mobile ARM Image: $global:WM"
    Copy-Item "..\source\arm\Images\$global:WM.wim" "..\tmp\$wi\$global:WM.wim"

    Write " Mounting $global:W81"
    New-Item "..\tmp\$wi\$global:W81" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$global:W81.wim" "..\tmp\$wi\$global:W81"
    Write " Mounting $global:W10"
    New-Item "..\tmp\$wi\$global:W10" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$global:W10.wim" "..\tmp\$wi\$global:W10"
    Write " Mounting $global:WPE"
    New-Item "..\tmp\$wi\$global:WPE" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$global:WPE.wim" "..\tmp\$wi\$global:WPE"
    Write " Mounting $global:WIOT"
    New-Item "..\tmp\$wi\$global:WIOT" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$global:WIOT.wim" "..\tmp\$wi\$global:WIOT"
    Write " Mounting $global:WM"
    New-Item "..\tmp\$wi\$global:WM" -ItemType Directory > $null
    Mount-Image "..\tmp\$wi\$global:WM.wim" "..\tmp\$wi\$global:WM"
}

function Integrate-CABs
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 2: Integrating Packages  ---"
    Add-PackagesToImage "..\tmp\$wi\$global:WPE" "..\source\arm\Packages\$global:VERSION"
}

function Merge-Images
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 3: Merging images        ---"

    # TO EXCLUDE: $excluded = @("Drivers\*","DriverStore\*","Config\*","catroot\*","catroot2\*")

    Write " Obtain System32 files list"
    Write "  Obtain $global:W10 System32 files list"
    $Original_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$global:W10\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $global:WPE System32 files list"
    $global:WPE_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$global:WPE\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $global:W10 SysArm32 files list"
    $global:W10_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$global:W10\Windows\SysArm32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $global:WIOT System32 files list"
    $global:WIOT_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$global:WIOT\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $global:WM System32 files list"
    $global:WM_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$global:WM\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }
    Write "  Obtain $global:W81 System32 files list"
    $global:W81_List = Get-ChildItem -Name -Recurse -File -Path "..\tmp\$wi\$global:W81\Windows\System32" | ? { -not $_.ToUpper().StartsWith("DRIVERS") -and -not $_.ToUpper().StartsWith("COFIG\") -and -not $_.ToUpper().StartsWith("CATROOT") }

    Write " Comparing lists"
    $Diff0 = Compare-Object2 -IncludeEqual -ReferenceObject $Original_List -DifferenceObject $global:WPE_List | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Comp1 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff0 -DifferenceObject $global:W10_List
    $Diff1 = $Comp1 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy1 = $Comp1 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp2 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff1 -DifferenceObject $global:WIOT_List
    $Diff2 = $Comp2 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy2 = $Comp2 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp3 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff2 -DifferenceObject $global:WM_List
    $Diff3 = $Comp3 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy3 = $Comp3 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp4 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff3 -DifferenceObject $global:W81_List
    $Diff4 = $Comp4 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy4 = $Comp4 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}

    Write $Copy1 > "..\logs\$wi\Copy from $global:W10 System32.log"
    Write $Copy2 > "..\logs\$wi\Copy from $global:WIOT System32.log"
    Write $Copy3 > "..\logs\$wi\Copy from $global:WM System32.log"
    Write $Copy4 > "..\logs\$wi\Copy from $global:W81 System32.log"
    Write $Diff4 > "..\logs\$wi\Not exist in System32.log"
    Write $Comp1 > "..\logs\$wi\Comp1 in System32.log"
    Write $Comp2 > "..\logs\$wi\Comp2 in System32.log"
    Write $Comp3 > "..\logs\$wi\Comp3 in System32.log"
    Write $Comp4 > "..\logs\$wi\Comp4 in System32.log"

    Write " Merging files"
    Write "  Copying from $global:W10"
    foreach ($item in $Copy1)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Recurse -Force -Verbose "..\tmp\$wi\$global:W10\Windows\SysArm32\$item" "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Fonts" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\GameBarPresenceWriter" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Globalization" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Help" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\InputMethod" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\L2Schemas" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\OCR" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\PLA" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\PolicyDefinitions" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Resources" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Schemas" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Security" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\SKB" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\System" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\SystemResources" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\Setup" "..\tmp\$wi\$global:WPE\Windows\"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\SysArm32\explorer.exe" "..\tmp\$wi\$global:WPE\Windows\explorer.exe"
    Copy-Item -Recurse -Force "..\tmp\$wi\$global:W10\Windows\SysArm32\taskmgr.exe" "..\tmp\$wi\$global:WPE\Windows\System32\taskmgr.exe"
    Write "  Copying from $global:WIOT"
    foreach ($item in $Copy2)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$global:WIOT\Windows\System32\$item" "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "  Copying from $global:WM"
    foreach ($item in $Copy3)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$global:WM\Windows\System32\$item" "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "  Copying from $global:W81"
    foreach ($item in $Copy4)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" > $null
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$global:W81\Windows\System32\$item" "..\tmp\$wi\$global:WPE\Windows\System32\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }

    # TODO: Registry checking
    Write " Copying ARM desktop applications"
    Write "  Obtain $global:W81 applications list"
    $global:W81_List = Get-ChildItem -Name -Exclude "WindowsApps" -Path "..\tmp\$wi\$global:W81\Program Files"
    Write "  Copying $global:W81 applications"
    foreach ($item in $global:W81_List)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$global:WPE\Program Files\$folderStruct" > $null
        Copy-Item -Recurse -Force -Verbose "..\tmp\$wi\$global:W81\Program Files\$item" "..\tmp\$wi\$global:WPE\Program Files\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "  Obtain $global:W10 applications list"
    $global:W10_List = Get-ChildItem -Name -Exclude "WindowsApps" -Path "..\tmp\$wi\$global:W10\Program Files"
    Write "  Copying $global:W10 applications"
    foreach ($item in $global:W10_List)
    {
        $folderStruct = Get-Path $item
        New-Item -Force -ItemType Directory "..\tmp\$wi\$global:WPE\Program Files\$folderStruct" > $null
        Copy-Item -Recurse -Force -Verbose "..\tmp\$wi\$global:W10\Program Files\$item" "..\tmp\$wi\$global:WPE\Program Files\$folderStruct" 4>> "..\logs\$wi\copylog in System32.log"
    }

    # TODO: UWP Apps
}

function Construct-Registry
{
    Write-Host -ForegroundColor DarkYellow "--- Stage 4: Constructing registry ---"

    Write " Storing registry from $global:WPE"
    Copy-Item "..\tmp\$wi\$global:WPE\Windows\System32\Config\SYSTEM" "..\tmp\$wi\SYSTEM"
    Write " Copying registry from $global:W10"
    Copy-Item -Force "..\tmp\$wi\$global:W10\Windows\System32\Config\SOFTWARE" "..\tmp\$wi\$global:WPE\Windows\System32\Config\SOFTWARE"
    Copy-Item -Force "..\tmp\$wi\$global:W10\Windows\System32\Config\SYSTEM" "..\tmp\$wi\$global:WPE\Windows\System32\Config\SYSTEM"

    Write " Mounting registry"
    $R_OR = "HKLM:\"+"$wi"+"_OR"
    $R_SY = "HKLM:\"+"$wi"+"_SY"
	$R_SO = "HKLM:\"+"$wi"+"_SO"
	Mount-Hive "..\tmp\$wi\$global:WPE\Windows\System32\Config\SYSTEM" $R_SY.Replace(":","")
	Mount-Hive "..\tmp\$wi\$global:WPE\Windows\System32\Config\SOFTWARE" $R_SO.Replace(":","")
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
      Add-DriversToImage "..\tmp\$wi\$global:WPE" "..\tmp\$wi\Drivers"
      Remove-Item "..\tmp\$wi\Drivers" -Recurse -Force > $null
    }

    Write " Merging drivers"
    Write "  Mounting registry"
    $R_WPE = "HKLM:\"+"$wi"+"_WPE"
    $R_WIOT = "HKLM:\"+"$wi"+"_WIOT"
    $R_WM = "HKLM:\"+"$wi"+"_WM"
    $R_W81 = "HKLM:\"+"$wi"+"_W81"
	Mount-Hive "..\tmp\$wi\$global:WPE\Windows\System32\Config\SYSTEM" $R_WPE.Replace(":","")
    Mount-Hive "..\tmp\$wi\$global:WIOT\Windows\System32\Config\SYSTEM" $R_WIOT.Replace(":","")
    Mount-Hive "..\tmp\$wi\$global:WM\Windows\System32\Config\SYSTEM" $R_WM.Replace(":","")
    Mount-Hive "..\tmp\$wi\$global:W81\Windows\System32\Config\SYSTEM" $R_W81.Replace(":","")

    Write "  Obtain drivers list"
    Write "   Obtain $global:W10 drivers list"
    $excluded = ""
    $Original_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$global:W10\Windows\System32\Drivers"
    Write "   Obtain $global:WPE drivers list"
    $global:WPE_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$global:WPE\Windows\System32\Drivers"
    Write "   Obtain $global:WIOT drivers list"
    $global:WIOT_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$global:WIOT\Windows\System32\Drivers"
    Write "   Obtain $global:WM drivers list"
    $global:WM_List = Get-ChildItem -Name -File -Recurse -Path "..\tmp\$wi\$global:WM\Windows\System32\Drivers"
    Write "   Obtain $global:W81 drivers list"
    $global:W81_List = Get-ChildItem -File -Recurse -Path "..\tmp\$wi\$global:W81\Windows\System32\Drivers"

    Write "  Comparing lists"
    $Diff0 = Compare-Object2 -IncludeEqual -ReferenceObject $Original_List -DifferenceObject $global:WPE_List | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Comp1 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff0 -DifferenceObject $global:WIOT_List
    $Diff1 = $Comp1 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy1 = $Comp1 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp2 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff1 -DifferenceObject $global:WM_List
    $Diff2 = $Comp2 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy2 = $Comp2 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}
    $Comp3 = Compare-Object2 -IncludeEqual -ReferenceObject $Diff2 -DifferenceObject $global:W81_List
    $Diff3 = $Comp3 | ? {$_.SideIndicator -eq '<='} | % {$_.InputObject}
    $Copy3 = $Comp3 | ? {$_.SideIndicator -eq '=='} | % {$_.InputObject}

    Write $Copy1 > "..\logs\$wi\Copy from $global:WIOT Drivers.log"
    Write $Copy2 > "..\logs\$wi\Copy from $global:WM Drivers.log"
    Write $Copy3 > "..\logs\$wi\Copy from $global:W81 Drivers.log"
    Write $Diff3 > "..\logs\$wi\Not exist in Drivers.log"
    Write $Comp1 > "..\logs\$wi\Comp1 in Drivers.log"
    Write $Comp2 > "..\logs\$wi\Comp2 in Drivers.log"
    Write $Comp3 > "..\logs\$wi\Comp3 in Drivers.log"

    Write "  Merging files"
    Write "   Copying from $global:WIOT"
    foreach ($item in $Copy1)
    {
        Copy-Item -Verbose -Force -Recurse "..\tmp\$wi\$global:WIOT\Windows\System32\Drivers\$item" "..\tmp\$wi\$global:WPE\Windows\System32\Drivers\" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "   Copying from $global:WM"
    foreach ($item in $Copy2)
    {
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$global:WM\Windows\System32\Drivers\$item" "..\tmp\$wi\$global:WPE\Windows\System32\Drivers\" 4>> "..\logs\$wi\copylog in System32.log"
    }
    Write "   Copying from $global:W81"
    foreach ($item in $Copy3)
    {
        Copy-Item -Force -Recurse -Verbose "..\tmp\$wi\$global:W81\Windows\System32\Drivers\$item" "..\tmp\$wi\$global:WPE\Windows\System32\Drivers\" 4>> "..\logs\$wi\copylog in System32.log"
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

    Write " Unmounting $global:W10"
    Discard-Image "..\tmp\$wi\$global:W10"
    Remove-Item "..\tmp\$wi\$global:W10.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$global:W10" -Recurse -Force > $null

    Write " Unmounting $global:WIOT"
    Discard-Image "..\tmp\$wi\$global:WIOT"
    Remove-Item "..\tmp\$wi\$global:WIOT.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$global:WIOT" -Recurse -Force > $null

    Write " Unmounting $global:WM"
    Discard-Image "..\tmp\$wi\$global:WM"
    Remove-Item "..\tmp\$wi\$global:WM.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$global:WM" -Recurse -Force > $null

    Write " Unmounting $global:W81"
    Discard-Image "..\tmp\$wi\$global:W81"
    Remove-Item "..\tmp\$wi\$global:W81.wim" -Recurse -Force > $null
    Remove-Item "..\tmp\$wi\$global:W81" -Recurse -Force > $null

    Read-Host "Press Enter to finish building WIM and clean environment"

    Write " Unmounting $global:WPE"
    Unmount-Image "..\tmp\$wi\$global:WPE"
    Remove-Item "..\tmp\$wi\$global:WPE" -Recurse -Force > $null

    Move-Item "..\tmp\$wi\$global:WPE.wim" "..\out\$wi $global:W10.wim"

    Remove-Item -Force -Recurse "..\tmp\$wi"

    Write-Host -ForegroundColor Green "Done!"
    Write "Result file can be found in 'out' folder."
}

function Start-BuildWindows10ARM
{
    $global:VERSION = Select-BuildVersion
    Set-BuildVersion
    if (Check-Files)
    {
        Prepare-Environment
        Integrate-CABs
        Merge-Images
        Construct-Registry
        Integrate-Drivers
        Clean-Environment
        Read-Host "Press Enter to continue"
    }
    else
    {
        Read-Host "Get necessary files and run script again!"
    }
}