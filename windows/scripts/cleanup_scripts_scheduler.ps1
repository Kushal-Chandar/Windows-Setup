Function Add-CustomTask {
    Param ($taskname, $taskpath, $days, $script)
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -WorkingDirectory "$PSScriptRoot\cleanup_scripts\" `
        -Argument "-WindowStyle Minimized -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -File $script"

    $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval $days -At '5:30 AM'

    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType S4U

    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -DontStopOnIdleEnd `
        -RestartCount 3 -RestartInterval (New-TimeSpan -Hours 6)

    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
        -Description "An automation task created using cleanup_scripts_scheduler.ps1"

    Register-ScheduledTask -TaskName $taskname -TaskPath $taskpath  -InputObject $task -ErrorAction SilentlyContinue
}
Function Get-TaskName {
    Param ($filename)    
    $filename = $filename.Replace("_", " ")
    $filename = $filename.Replace(".ps1", "")
    $filename = $filename.substring(0, 1).toupper() + $filename.substring(1).tolower()
    return $filename
}

###__main()__###

#region auto clean
$cleanup_scripts = @( #important to order tasks for foreach loop below
    "temp_files_cleanup.ps1", #runs every day
    "system_files_cleanup.ps1", #runs every month
    "telemetry_and_network.ps1"#runs every 2 months 
)
$days = 1
$taskpath = "\User Automation for Windows\"
foreach ($script in $cleanup_scripts) {
    $taskname = Get-TaskName -filename $script
    Add-CustomTask -taskname $taskname -taskpath $taskpath -days $days -script $script
    $days = $days + 30 #adding a month for next task
}
Get-ScheduledTask -TaskPath $taskpath | Start-ScheduledTask
#endregion