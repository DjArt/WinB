#region Image Servicing
function Set-ItemCompreesionFlag([string]$filename)
{
  Invoke-Expression "compact /U `"$filename`""
}

function Get-WorkingIndex
{
  $folders = (Get-ChildItem "../tmp" -Name -Directory)
  if ($folders -eq $null)
  {
    New-Item "../tmp/0" -ItemType Directory > $null
    return 0
  }
  else
  {
    $folders = $folders.Replace("`r", "").Split("`n") | group length | sort name | foreach {$_.group | sort}
    $next = 1
    $success = [System.UInt32]::TryParse($folders[$folders.Length - 1], [ref]$next)
    if ($success)
    {
      $next++
      New-Item "../tmp/$next" -ItemType Directory > $null
      return $next
    }
    else
    {
      throw "The tmp folder must contain only numeric names in directories!"
    }
  }
}
#endregion

#region Registry Servicing
function Mount-Hive([string]$hive, [string]$dir)
{
  reg load "$dir" $hive
}

function Unmount-Hive([string]$dir)
{
  reg unload "$dir"
}
#endregion

#region Custom Compare
# From https://blogs.technet.microsoft.com/ashleymcglone/2017/08/07/use-hash-tables-to-go-faster-than-powershell-compare-object/
<#
.SYNOPSIS
Faster version of Compare-Object for large data sets with a single value.
.DESCRIPTION
Uses hash tables to improve comparison performance for large data sets.
.PARAMETER ReferenceObject
Specifies an array of objects used as a reference for comparison.
.PARAMETER DifferenceObject
Specifies the objects that are compared to the reference objects.
.PARAMETER IncludeEqual
Indicates that this cmdlet displays characteristics of compared objects that
are equal. By default, only characteristics that differ between the reference
and difference objects are displayed.
.PARAMETER ExcludeDifferent
Indicates that this cmdlet displays only the characteristics of compared
objects that are equal.
.EXAMPLE
Compare-Object2 -ReferenceObject 'a','b','c' -DifferenceObject 'c','d','e' `
    -IncludeEqual -ExcludeDifferent
.EXAMPLE
Compare-Object2 -ReferenceObject (Get-Content .\file1.txt) `
    -DifferenceObject (Get-Content .\file2.txt)
.EXAMPLE
$p1 = Get-Process
notepad
$p2 = Get-Process
Compare-Object2 -ReferenceObject $p1.Id -DifferenceObject $p2.Id
.NOTES
Does not support objects with properties. Expand the single property you want
to compare before passing it in.
Includes optimization to run even faster when -IncludeEqual is omitted.
#>            
function Compare-Object2 {            
param(            
    [psobject[]]            
    $ReferenceObject,            
    [psobject[]]            
    $DifferenceObject,            
    [switch]            
    $IncludeEqual,            
    [switch]            
    $ExcludeDifferent            
)            
            
    # Put the difference array into a hash table,            
    # then destroy the original array variable for memory efficiency.            
    $DifHash = @{}            
    $DifferenceObject | ForEach-Object {$DifHash.Add($_,$null)}            
    Remove-Variable -Name DifferenceObject            
            
    # Put the reference array into a hash table.            
    # Keep the original array for enumeration use.            
    $RefHash = @{}            
    for ($i=0;$i -lt $ReferenceObject.Count;$i++) {            
        $RefHash.Add($ReferenceObject[$i],$null)            
    }            
            
    # This code is ugly but faster.            
    # Do the IF only once per run instead of every iteration of the ForEach.            
    If ($IncludeEqual) {            
        $EqualHash = @{}            
        # You cannot enumerate with ForEach over a hash table while you remove            
        # items from it.            
        # Must use the static array of reference to enumerate the items.            
        ForEach ($Item in $ReferenceObject) {            
            If ($DifHash.ContainsKey($Item)) {            
                $DifHash.Remove($Item)            
                $RefHash.Remove($Item)            
                $EqualHash.Add($Item,$null)            
            }            
        }            
    } Else {            
        ForEach ($Item in $ReferenceObject) {            
            If ($DifHash.ContainsKey($Item)) {            
                $DifHash.Remove($Item)            
                $RefHash.Remove($Item)            
            }            
        }            
    }            
            
    If ($IncludeEqual) {            
        $EqualHash.Keys | Select-Object @{Name='InputObject';Expression={$_}},`
            @{Name='SideIndicator';Expression={'=='}}            
    }            
            
    If (-not $ExcludeDifferent) {            
        $RefHash.Keys | Select-Object @{Name='InputObject';Expression={$_}},`
            @{Name='SideIndicator';Expression={'<='}}            
        $DifHash.Keys | Select-Object @{Name='InputObject';Expression={$_}},`
            @{Name='SideIndicator';Expression={'=>'}}            
    }            
}            

#endregion

#region Main Activity
function Load-Modules
{
    foreach ($module in (Get-ChildItem -File -Path "..\modules"))
    {
        Import-Module -Name $module.FullName
    }
}

function Load-Scripts
{
    return (Get-ChildItem -File -Name -Path "..\scripts")
}

function Start-Script([string]$scriptname)
{
    Import-Module "..\scripts\$scriptname.ps1"
    Invoke-Expression "Start-$scriptname"
    Remove-Module $scriptname
}

function Start-Menu
{
    # TODO: Check user
    # TODO: Color schema
    Load-Modules
    Clear-Host
    Write-Host -ForegroundColor Yellow "--------------------------------------"
    Write-Host -ForegroundColor Yellow "-Windows Builder v. 0.0.0.10 by djart-"
    Write-Host -ForegroundColor Yellow "--------------------------------------"
    $scripts = (Load-Scripts).Split("`n")
    for ($i0 = 0; $i0 -lt $scripts.Length; $i0++)
    {
        $scripts[$i0] = $scripts[$i0].Substring(0, $scripts[$i0].Length-4)
        $scriptname = $scripts[$i0]
        Write "  $i0 : $scriptname"
    }
    $exit = $scripts.Length
    Write "  $exit : Exit"
    $choose = Read-Host -Prompt "Your choise"
    if ($choose -eq $exit)
    {
        Clear-Host
    }
    else
    {
        Start-Script $scripts[$choose]
        Start-Menu
    }
}

Start-Menu
#endregion