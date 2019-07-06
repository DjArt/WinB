function Mount-VHD([string]$imagefile, [string]$dirname, [string]$tmpdir)
{
  "select vdisk file=`"$imagefile`"" > "$tmpdir\Mount-VHD"
  "attach vdisk" >> "$tmpdir\Mount-VHD"
  "select partition 2" >> "$tmpdir\Mount-VHD"
  "assign mount=`"$dirname`"" >> "$tmpdir\Mount-VHD"
  (Get-Content -Encoding Unicode "$tmpdir\Mount-VHD" ) | Out-File -Encoding UTF8 "$tmpdir\Mount-VHD"
  Invoke-Expression "diskpart /s `"$tmpdir\Mount-VHD`""
  Remove-Item "$tmpdir\Mount-VHD"
}

function Unmount-VHD([string]$imagefile, [string]$dirname, [string]$tmpdir)
{
  "select vdisk file=`"$imagefile`"" > "$tmpdir\Unmount-VHD"
  "detach vdisk" >> "$tmpdir\Unmount-VHD"
  (Get-Content -Encoding Unicode "$tmpdir\Unmount-VHD" ) | Out-File -Encoding UTF8 "$tmpdir\Unmount-VHD"
  Invoke-Expression "diskpart /s `"$tmpdir\Unmount-VHD`""
  Remove-Item "$tmpdir\Unmount-VHD"
  Remove-Item "$dirname" -Force
}