function Unmount-Image([string]$dirname)
{
  Invoke-Expression "dism /Unmount-Image /MountDir:$dirname /Commit"
}

function Discard-Image([string]$dirname)
{
  Invoke-Expression "dism /Unmount-Image /MountDir:$dirname /Discard"
}

function Add-DriversToImage([string]$imagedir, [string]$driversdir)
{
  Invoke-Expression "dism /Image:$imagedir /Add-Driver /Driver:$driversdir /Recurse"
}

function Add-PackagesToImage([string]$imagedir, [string]$packagesdir)
{
  Invoke-Expression "dism /Image:$imagedir /Add-Package /PackagePath:$packagesdir"
}

function Mount-Image([string]$imagefile, [string]$dirname, [int]$index = 1)
{
  Invoke-Expression "dism /Mount-Image /ImageFile:$imagefile /Index:$index /MountDir:$dirname"
}