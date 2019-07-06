function Extract-Item([string]$from, [string]$to)
{
  Invoke-Expression "$env:PROCESSOR_ARCHITECTURE/7-zip/7z.exe x `"$from`" -o`"$to`""
}