$shortcutPath = "$([Environment]::GetFolderPath('Desktop'))"

If ((Test-Path "$shortcutPath\fuel-qa-tool-suite.lnk") -eq $false) {
    Copy-Item -Path ".\shortcut\Fuel QA Tool Suite.lnk" -Destination $shortcutPath
}

& "D:\Tools\Fuel_QA_Automation_Tool_Suite\app\fuel-qa-tool-suite.ps1"
