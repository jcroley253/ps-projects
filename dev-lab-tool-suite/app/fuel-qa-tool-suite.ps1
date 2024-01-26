$ErrorActionPreference = 'SilentlyContinue'
$date = Get-Date -Format "yyyy-MM-dd"

try { 
    $servers = Get-content '.\Servers.txt'
}
catch {
    LogIt -Message "Failed to retrieve Servers.txt file." -Severity Error -ForegroundColor Red
}

function LogIt {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)][string]$message,
        [Parameter(Mandatory = $false)][string]$foregroundColor,
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$severity = 'Information'
    )

    if ($foregroundColor) {
        Write-Host $message -ForegroundColor $foregroundColor
    }
    else {
        Write-Host $message
    }
 
    [pscustomobject]@{
        Time     = (Get-Date)
        Message  = $message
        Severity = $severity
    } | Export-Csv -Path ".\logs\Run-Log_$date.csv" -Append -NoTypeInformation
}

LogIt -Message "Starting program" -Severity Information


function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json) {
    $indent = 0;
  ($json -Split '\n' |
    % {
        if ($_ -match '[\}\]]') {
            # This line contains  ] or }, decrement the indentation level
            $indent--
        }
        $line = ("`t" * $indent) + $_.TrimStart().Replace(':  ', ': ')
        if ($_ -match '[\{\[]') {
            # This line contains [ or {, increment the indentation level
            $indent++
        }
        $line
    }) -Join "`n"
}


Function getServices {

    LogIt -Message "Starting getService Function" -Severity Information
    $services = @()

    ForEach ($server in $servers) {

        If ($server -like "SERVERNAMINGCONVENTION*") {
            If (Test-Connection $server -Count 2) {
                LogIt -Message "Connecting to $server." -Severity Information
                $status = "ONLINE"
            }
            Else {
                LogIt -Message "$server is OFFLINE." -Severity Warning -ForegroundColor Red
                $status = "OFFLINE"
            }

            LogIt -Message "Checking services on $server" -Severity Information

            $fts1 = (get-service -ComputerName $server -Name "Fuel Tlog Upload Service").Status
            If ($null -eq $fts1) {
                LogIt -Message "Fuel Tlog Upload Service is not installed on $server." -Severity Warning -foregroundColor Yellow
                $fts1 = "MISSING"
            }

            $xl1 = (get-service -ComputerName $server -Name "XLight FTP Server").Status
            If ($null -eq $xl1) {
                LogIt -Message "XLight FTP Server is not installed on $server." -Severity Warning -foregroundColor Yellow
                $xl1 = "MISSING"
            }

            $ss1 = (get-service -ComputerName $server -Name "SiteService").Status
            If ($null -eq $ss1) {
                LogIt -Message "SiteService is not installed on $server." -Severity Warning -foregroundColor Yellow
                $ss1 = "MISSING"
            }

            $splunk = (get-service -ComputerName $server -Name "SplunkForwarder").Status
            If ($null -eq $splunk) {
                LogIt -Message "SplunkForwarder is not installed on $server." -Severity Warning -foregroundColor Yellow
                $splunk = "MISSING"
            }

            $services += New-Object -TypeName psobject -Property @{
                Server                     = $server
                "Server Status"            = $status
                "Fuel TLOG Upload Service" = $fts1
                "Site Service"             = $ss1
                Xlight                     = $xl1
                Splunk                     = $splunk
            }
        }
    }
    
    LogIt -Message "Finished checking service statuses on US Lab Servers." -Severity Information
    $services | Select Server, "Server Status", "Fuel TLOG Upload Service", "Site Service", Xlight, Splunk | Out-GridView -Wait -Title "US Lab Server Services"

}

Function caGetServices {

    LogIt -Message "Starting CA getService Function" -Severity Information
    $services = @()

    ForEach ($server in $servers) {
        If ($server -like "SERVERNAMINGCONVENTION*") {
            If (Test-Connection $server -Count 2) {
                LogIt -Message "Connecting to $server." -Severity Information
                $status = "ONLINE"
            }
            Else {
                LogIt -Message "$server is OFFLINE." -Severity Warning -ForegroundColor Red
                $status = "OFFLINE"
            }

            LogIt -Message "Checking services on $server" -Severity Information

            $radviewer = (get-service -ComputerName $server -Name "RadViewerAuthServer").Status
            If ($null -eq $radviewer) {
                LogIt -Message "RadViewerAuthServer is not installed on $server." -Severity Warning -foregroundColor Yellow
                $radviewer = "MISSING"
            }

            $retailix = (get-service -ComputerName $server -Name "RadViewerAuthServer").Status
            If ($null -eq $retailix) {
                LogIt -Message "POS_Srv_Manager is not installed on $server." -Severity Warning -foregroundColor Yellow
                $retailix = "MISSING"
            }

            $epsilon = (get-service -ComputerName $server -Name "Epsilon").Status
            If ($null -eq $epsilon) {
                LogIt -Message "Epsilon is not installed on $server." -Severity Warning -foregroundColor Yellow
                $epsilon = "MISSING"
            }

            $splunk = (get-service -ComputerName $server -Name "SplunkForwarder").Status
            If ($null -eq $splunk) {
                LogIt -Message "SplunkForwarder is not installed on $server." -Severity Warning -foregroundColor Yellow
                $splunk = "MISSING"
            }

            $xl1 = (get-service -ComputerName $server -Name "XLight FTP Server").Status
            If ($null -eq $xl1) {
                LogIt -Message "XLight FTP Server is not installed on $server." -Severity Warning -foregroundColor Yellow
                $xl1 = "MISSING"
            }
            
            If ($null -eq (Get-Process -Name RouteSrv)) {
                LogIt -Message "RouteSrv is not running on $server." -Severity Warning -foregroundColor Yellow
                $routesrv = "NOT RUNNING"
            }
            Else {
                $routesrv = "RUNNING"
            }

            If ($null -eq (Get-Process -Name PumpSrv)) {
                LogIt -Message "PumpSrv is not running on $server." -Severity Warning -foregroundColor Yellow
                $pumpsrv = "NOT RUNNING"
            }
            Else {
                $pumpsrv = "RUNNING"
            }

            $services += New-Object -TypeName psobject -Property @{
                Server          = $server
                "Server Status" = $status
                Epsilon         = $epsilon
                RadViewer       = $radviewer
                Retailix        = $retailix
                PumpSrv         = $pumpsrv
                RouteSrv        = $routesrv
                Xlight          = $xl1
                Splunk          = $splunk
            }
        }
    }

    LogIt -Message "Finished checking service statuses on CA Lab Servers." -Severity Information
    $services | Select Server, "Server Status", Epsilon, RadViewer, Retailix, PumpSrv, RouteSrv, Xlight, Splunk | Out-GridView -Wait -Title "CA Lab Server Services"
        
}


Function startServices {

    LogIt -Message "Starting start service function" -Severity Information
    $services = @()

    ForEach ($server in $servers) {
        If ($server -like "SERVERNAMINGCONVENTION*") {
            If (Test-Connection $server -Count 2) {
                LogIt -Message "Connecting to $server." -Severity Information
                $status = "Online"
            }
            Else {
                LogIt -Message "$server is OFFLINE." -Severity Error -ForegroundColor Red
                $status = "Offline"
            }

            LogIt -Message "Checking services on $server" -Severity Information

            $fts = (get-service -ComputerName $server -Name "Fuel Tlog Upload Service").Status
            If ($fts -eq 'Stopped') {
                LogIt -Message "Fuel Tlog Upload Service is not running on $server. Attempting to Start Fuel Tlog Upload Service" -Severity Information
                get-service -ComputerName $server -Name "Fuel Tlog Upload Service" | Start-Service
            }

            $xl = (get-service -ComputerName $server -Name "XLight FTP Server").Status
            If ($xl -eq 'Stopped') {
                LogIt -Message "XLight FTP Server is not running on $server. Attempting to Start XLight FTP Server" -Severity Information
                get-service -ComputerName $server -Name "XLight FTP Server" | Start-Service
            }

            $ss = (get-service -ComputerName $server -Name "SiteService").Status
            If ($ss -eq 'Stopped') {
                LogIt -Message "SiteService is not running on $server. Attempting to Start SiteService" -Severity Information
                get-service -ComputerName $server -Name "SiteService" | Start-Service
            }

            $spl = (get-service -ComputerName $server -Name "SplunkForwarder").Status
            If ($spl -eq 'Stopped') {
                LogIt -Message "SplunkForwarder is not running on $server. Attempting to Start SplunkForwarder" -Severity Information
                get-service -ComputerName $server -Name "SplunkForwarder" | Start-Service
            }

            Sleep 3

            $fts1 = (get-service -ComputerName $server -Name "Fuel Tlog Upload Service").Status
            If ($null -eq $fts1) {
                LogIt -Message "Fuel Tlog Upload Service is not installed on $server." -Severity Warning -foregroundColor Yellow
                $fts1 = "MISSING"
            }

            $xl1 = (get-service -ComputerName $server -Name "XLight FTP Server").Status
            If ($null -eq $xl1) {
                LogIt -Message "XLight FTP Server is not installed on $server." -Severity Warning -foregroundColor Yellow
                $xl1 = "MISSING"
            }

            $ss1 = (get-service -ComputerName $server -Name "SiteService").Status
            If ($null -eq $ss1) {
                LogIt -Message "SiteService is not installed on $server." -Severity Warning -foregroundColor Yellow
                $ss1 = "MISSING"
            }

            $splunk = (get-service -ComputerName $server -Name "SplunkForwarder").Status
            If ($null -eq $splunk) {
                LogIt -Message "SplunkForwarder is not installed on $server." -Severity Warning -foregroundColor Yellow
                $splunk = "MISSING"
            }

            $services += New-Object -TypeName psobject -Property @{
                Server                     = $server
                "Server Status"            = $status
                "Fuel TLOG Upload Service" = $fts1
                "Site Service"             = $ss1
                Xlight                     = $xl1
                Splunk                     = $splunk
            }
        }
    }

    LogIt -Message "Finished starting services on US Lab Servers." -Severity Information
    $services | Select Server, "Fuel TLOG Upload Service", "Site Service", Xlight, Splunk | Out-GridView -Wait -Title "US Lab Server Services"
}

Function caStartServices {

    LogIt -Message "Starting start CA service function" -Severity Information
    $services = @()

    ForEach ($server in $servers) {
        If ($server -like "SERVERNAMINGCONVENTION*") {
            If (Test-Connection $server -Count 2) {
                LogIt -Message "Connecting to $server." -Severity Information
                $status = "Online"
            }
            Else {
                LogIt -Message "$server is OFFLINE." -Severity Error -ForegroundColor Red
                $status = "Offline"
            }

            LogIt -Message "Checking services on $server" -Severity Information

            $radviewer = (get-service -ComputerName $server -Name "RadViewerAuthServer").Status
            If ($null -eq $radviewer) {
                LogIt -Message "RadViewerAuthServer is not running on $server. Attempting to start RadViewerAuthServer." -Severity Warning -foregroundColor Yellow
                get-service -ComputerName $server -Name "RadViewerAuthServer" | Start-Service
            }

            $retailix = (get-service -ComputerName $server -Name "POS_Srv_Manager").Status
            If ($null -eq $retailix) {
                LogIt -Message "Epsilon is not running on $server. Attempting to start POS_Srv_Manager." -Severity Warning -foregroundColor Yellow
                get-service -ComputerName $server -Name "POS_Srv_Manager" | Start-Service
            }

            $epsilon = (get-service -ComputerName $server -Name "Epsilon").Status
            If ($epsilon -eq 'Stopped') {
                LogIt -Message "Epsilon is not running on $server. Attempting to start Epsilon." -Severity Warning -foregroundColor Yellow
                get-service -ComputerName $server -Name "Epsilon" | Start-Service
            }

            $xl = (get-service -ComputerName $server -Name "XLight FTP Server").Status
            If ($xl -eq 'Stopped') {
                LogIt -Message "XLight FTP Server is not running on $server. Attempting to Start XLight FTP Server" -Severity Information
                get-service -ComputerName $server -Name "XLight FTP Server" | Start-Service
            }

            $spl = (get-service -ComputerName $server -Name "SplunkForwarder").Status
            If ($spl -eq 'Stopped') {
                LogIt -Message "SplunkForwarder is not running on $server. Attempting to Start SplunkForwarder" -Severity Information
                get-service -ComputerName $server -Name "SplunkForwarder" | Start-Service
            }

            Sleep 3

            $radviewer = (get-service -ComputerName $server -Name "RadViewerAuthServer").Status
            If ($null -eq $radviewer) {
                LogIt -Message "RadViewerAuthServer is not installed on $server." -Severity Warning -foregroundColor Yellow
                $radviewer = "MISSING"
            }

            $retailix = (get-service -ComputerName $server -Name "POS_Srv_Manager").Status
            If ($null -eq $retailix) {
                LogIt -Message "POS_Srv_Manager is not installed on $server." -Severity Warning -foregroundColor Yellow
                $retailix = "MISSING"
            }

            $epsilon = (get-service -ComputerName $server -Name "Epsilon").Status
            If ($null -eq $epsilon) {
                LogIt -Message "Epsilon is not installed on $server." -Severity Warning -foregroundColor Yellow
                $epsilon = "MISSING"
            }

            $splunk = (get-service -ComputerName $server -Name "SplunkForwarder").Status
            If ($null -eq $splunk) {
                LogIt -Message "SplunkForwarder is not installed on $server." -Severity Warning -foregroundColor Yellow
                $splunk = "MISSING"
            }

            $xl1 = (get-service -ComputerName $server -Name "XLight FTP Server").Status
            If ($null -eq $xl1) {
                LogIt -Message "XLight FTP Server is not installed on $server." -Severity Warning -foregroundColor Yellow
                $xl1 = "MISSING"
            }
            
            If ($null -eq (Get-Process -Name RouteSrv)) {
                LogIt -Message "RouteSrv is not running on $server." -Severity Warning -foregroundColor Yellow
                $routesrv = "NOT RUNNING"
            }
            Else {
                $routesrv = "RUNNING"
            }

            If ($null -eq (Get-Process -Name PumpSrv)) {
                LogIt -Message "PumpSrv is not running on $server." -Severity Warning -foregroundColor Yellow
                $pumpsrv = "NOT RUNNING"
            }
            Else {
                $pumpsrv = "RUNNING"
            }

            $services += New-Object -TypeName psobject -Property @{
                Server          = $server
                "Server Status" = $status
                Epsilon         = $epsilon
                RadViewer       = $radviewer
                Retailix        = $retailix
                PumpSrv         = $pumpsrv
                RouteSrv        = $routesrv
                Xlight          = $xl1
                Splunk          = $splunk
            }
        }
    }

    LogIt -Message "Finished checking service statuses on CA Lab Servers." -Severity Information
    $services | Select Server, "Server Status", Epsilon, RadViewer, Retailix, PumpSrv, RouteSrv, Xlight, Splunk | Out-GridView -Wait -Title "CA Lab Server Services"
}

Function getAppVersions {

    LogIt -Message "Starting get application version function" -Severity Information
    $versions = @()

    foreach ($server in $servers) {
        If ($server -like "SERVERNAMINGCONVENTION*") {
            LogIt -Message "Checking application versions on US Lab Server $server" -Severity Information

            $server_status = "Online"
            if (!(Test-Connection $server -Count 2)) {
                LogIt -Message "Unable to connect to server $server" -Severity Warning -ForegroundColor Red
                $server_status = "OFFLINE"
                continue
            }

            $chrome = ((Get-ChildItem -Path "\\$server\C$\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo).ProductVersion
            if ($null -eq $chrome) {
                LogIt -Message "Chrome is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $chrome = "NOT INSTALLED"
            }

            $config_client = Get-Content "\\$server\D$\ConfigClient\Version.txt"
            $index = $config_client.LastIndexOf(" ")
            $config_client.Substring($index).Trim()
            if ($null -eq $config_client) {
                LogIt -Message "Config Client is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $config_client = "NOT INSTALLED"
            }

            $site_service_config = "\\$server\D$\PATHTOFILE\version.json"
            $site_service = (Get-Content -Raw $site_service_config | ConvertFrom-Json | Select-Object -ExpandProperty Data).version
            if ($null -eq $site_service) {
                LogIt -Message "Site Service is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $site_service = "NOT INSTALLED"
            }

            $fuel_tlog_service = ((Get-ChildItem -Path "\\$server\D$\PATHTOFILE\FuelTlogUploadService.exe").VersionInfo).ProductVersion
            if ($null -eq $fuel_tlog_service) {
                LogIt -Message "Fuel Tlog Upload Service is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $fuel_tlog_service = "NOT INSTALLED"
            }

            $splunk = ((Get-ChildItem -Path "\\$server\D$\Program Files\SplunkUniversalForwarder\bin\splunk.exe").VersionInfo).ProductVersion
            if ($null -eq $splunk) {
                LogIt -Message "Splunk is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $splunk = "NOT INSTALLED"
            }

            $xlight = ((Get-ChildItem -Path "\\$server\D$\xlight\xlight.exe").VersionInfo).ProductVersion
            if ($null -eq $xlight) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $xlight = "NOT INSTALLED"
            }

            $versions += New-Object -TypeName psobject -Property @{
                "Server"                   = $server
                "Server Status"            = $server_status
                "Google Chrome"            = $chrome
                "Site Service"             = $site_service
                "Config Client"            = $config_client
                "Fuel TLOG Upload Service" = $fuel_tlog_service
                "Splunk"                   = $splunk
                "Xlight"                   = $xlight
            }
        }
    }

    LogIt -Message "Finished checking application versions on US Lab Servers" -Severity Information
    $versions | Select-Object "Server", "Server Status", "Google Chrome", "Config Client", "Site Service", "Fuel TLOG Upload Service", "Splunk", "Xlight" | Out-GridView -Wait -Title "US Lab Server App Versions"

}

Function caGetAppVersions {

    LogIt -Message "Starting get application version function" -Severity Information
    $versions = @()

    foreach ($server in $servers) {
        If ($server -like "SERVERNAMINGCONVENTION*") {
            LogIt -Message "Checking application versions on US Lab Server $server" -Severity Information

            $server_status = "Online"
            if (!(Test-Connection $server -Count 2)) {
                LogIt -Message "Unable to connect to server $server" -Severity Warning -ForegroundColor Red
                $server_status = "OFFLINE"
                continue
            }

            $chrome = ((Get-ChildItem -Path "\\$server\C$\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo).ProductVersion
            if ($null -eq $chrome) {
                LogIt -Message "Chrome is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $chrome = "NOT INSTALLED"
            }

            $sqlExpress = ((Get-ChildItem -Path "\\$server\C$\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\sqlservr.exe").VersionInfo).ProductVersion
            if ($null -eq $sqlEngine) {
                LogIt -Message "SQL Engine is missing component on $server" -Severity Warning -ForegroundColor Yellow
                $sqlEngine = "NOT INSTALLED"
            }

            $sqlEngine = ((Get-ChildItem -Path "\\$server\D$\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\sqlservr.exe").VersionInfo).ProductVersion
            if ($null -eq $sqlEngine2) {
                LogIt -Message "SQL Engine is missing component on $server" -Severity Warning -ForegroundColor Yellow
                $sqlEngine2 = "NOT INSTALLED"
            }

            $splunk = ((Get-ChildItem -Path "\\$server\D$\Program Files\SplunkUniversalForwarder\bin\splunk.exe").VersionInfo).ProductVersion
            if ($null -eq $splunk) {
                LogIt -Message "Splunk is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $splunk = "NOT INSTALLED"
            }

            $xlight = ((Get-ChildItem -Path "\\$server\D$\xlight\xlight.exe").VersionInfo).ProductVersion
            if ($null -eq $xlight) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $xlight = "NOT INSTALLED"
            }

            $pumpsrv = ((Get-ChildItem -Path "\\$server\C$\Program Files (x86)\StoreLine\PumpSrv\PumpSrv.exe").VersionInfo).ProductVersion
            if ($null -eq $pumpsrv) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $pumpsrv = "NOT INSTALLED"
            }

            $routesrv = ((Get-ChildItem -Path "\\$server\C$\PCMASTER\Drv32\PumpSrv.exe").VersionInfo).FileVersion
            if ($null -eq $routesrv) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $routesrv = "NOT INSTALLED"
            }

            $rfs = ((Get-ChildItem -Path "\\$server\C$\Program Files (x86)\StoreLine\PumpSrv\RFS.exe").VersionInfo).ProductVersion
            if ($null -eq $rfs) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $rfs = "NOT INSTALLED"
            }

            $epsilon = ((Get-ChildItem -Path "\\$server\C$\PCMASTER\Drv32\EpsilonLinkServer\EpsilonLinkSrv.exe").VersionInfo).FileVersion
            if ($null -eq $rfs) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $rfs = "NOT INSTALLED"
            }

            $radViewer = ((Get-ChildItem -Path "\\$server\C$\Program Files (x86)\NCR\RadViewerAuthServer\Bin\RadViewerAuthServer.exe").VersionInfo).FileVersion
            if ($null -eq $rfs) {
                LogIt -Message "Xlight is not installed on $server" -Severity Warning -ForegroundColor Yellow
                $rfs = "NOT INSTALLED"
            }

            $versions += New-Object -TypeName psobject -Property @{
                "Server"        = $server
                "Server Status" = $server_status
                "Google Chrome" = $chrome
                PumpSrv         = $pumpsrv
                RouteSrv        = $routesrv
                RFS             = $rfs
                Epsilon         = $epsilon
                RadViewer       = $radViewer
                "SQL Express"   = $sqlExpress
                "SQL Engine"    = $sqlEngine
                "Splunk"        = $splunk
                "Xlight"        = $xlight
            }
        }
    }

    LogIt -Message "Finished checking application versions on US Lab Servers" -Severity Information
    $versions | Select-Object "Server", "Server Status", "Google Chrome", PumpSrv, RouteSrv, RFS, "SQL Express", "SQL Engine", "Splunk", "Xlight" | Out-GridView -Wait -Title "US Lab Server App Versions"

}

Function logCollector {

    LogIt -Message "Starting US Lab Log Collection function" -Severity Information

    do {
        $server = Read-Host -Prompt "Enter the US Lab site server name (ex. SERVERNAMINGCONVENTION)"
        $prompt = "Y"
        If ($server.Length -gt 14) {
            Write-Host "$server has MORE characters then the standard naming convention. The normal length is 14 characters. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server.Length -lt 14) {
            Write-Host "$server has LESS characters then the standard naming convention. The normal length is 14 characters. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server -NotLike "WPSFSS*" -or $server -NotLike "*T01") {
            Write-Host "$server has DOES NOT meet the PROD Standard Naming Convention. The standard naming convention in Prod is SERVERNAMINGCONVENTION. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
    }
    while ($prompt -ne "Y")

    LogIt -Message "User entered the following US Lab server for Log Collection: $server." -Severity Information

    If (Test-Connection $server -Count 2) {

        LogIt -Message "$server is online." -Severity Information
            
        # Creates NP Domain Credentials variable for NP server connection
        $User = Read-Host -Prompt "Enter NP user id"
        $Creds = "np\$User"
    
        # Creates Project Folder for QA Logs
        $ProjectNumber = Read-Host -Prompt "Enter the Fuel Turn Over Number associated with the QA Test conducted."
        $destination = "C:\Tools\Fuel_QA_Automation_Tool_Suite\Log-Collection\FT$ProjectNumber"  

        LogIt -Message "User entered Project Number FT#$ProjectNumber" -Severity Information
        
        # Paths to Site Server files
        $ss = "\\$server\D$"
        $ssTLog = "$ss\Costco_logs\FuelTLogUpload.log"
        $ssConfig = "$ss\ConfigClient\ConfigClient\ConfigClient.log"
        $ssUpgrade = "$ss\PATHTOFILE\sw-upgrade-engine\log\access.log" 
        $ssAuth = "$ss\PATHTOFILE\smartcrind_PumpAuthSiteService*"
        $ssDeadPool = "$ss\PATHTOFILE\Deadpool"
        $ssOutput = "$ss\PATHTOFILE\Output"
        $ssDump = "$ss\PATHTOFILE\Dump"

        # Path to FMS Server
        do {

            Write-Host "
            US Lab FT Servers
            +++++++++++++++++++++++++++++++++++++++++++++++++++

            Option 1 : RTS1 - SERVERNAMINGCONVENTION
            Option 2 : RTS2 - SERVERNAMINGCONVENTION
            Option 3 : RTS3 - SERVERNAMINGCONVENTION
            Option 4 : RTS4 - SERVERNAMINGCONVENTION

            +++++++++++++++++++++++++++++++++++++++++++++++++++
            "

            try {
                # try/catch inserted to prevent errors from populating on the screen if user enters anything other than a number.
                [int]$fms = Read-Host -Prompt "Select the number associated with the FMS Server used for testing. (1, 2 ,3...)"
            }
            catch {}

            If ($fms -gt 4 -or $fms -lt 1 -or $fms -isnot [int] -or $fms -eq "") {
                Write-Host "Invalid Option selected. Please try again..." -ForegroundColor Red
                $oops = $true
            }
            Else {
                $oops = $false
            }
        }

        while ($oops -eq $true)

        switch ($fms) {
            1 { $fmsServer = 'SERVERIP' }
            2 { $fmsServer = 'SERVERIP' }
            3 { $fmsServer = 'SERVERIP' }
            4 { $fmsServer = 'SERVERIP' }
        }

        LogIt -Message "User selected FMS Server IP: $fmsServer" -Severity Information

        New-Item -ItemType Directory -Path $destination -Force
        New-Item -ItemType Directory -Path "$destination\DumpFiles" -Force
        New-Item -ItemType Directory -Path "$destination\Fipay_Logs" -Force

        # Creates temp PS Drive required to pass credentials and copy files cross domain
        try {
            LogIt -Message "Establishing connection to FT Server $fmsServer." -Severity Information            
            New-PSDrive -Name L -PSProvider filesystem -Root "$fmsServer" -Credential $Creds -Persist
            
            # Copies and renames fipay logs to include location and pump number
            $folders = (Get-ChildItem L:\FTserv\stores\ | Select Name).Name
        }
        catch {
            LogIt -Message "Failed to connect to FT Server $fmsServer." -Severity Error -ForegroundColor Red
        }

        # Moves logs from test fms and site server to destination folder
        try {
            LogIt -Message "Gathering log collection for FT#$ProjectNumber QA Test." -Severity Information
            Copy-Item -Path $ssTLog, $ssConfig, $ssUpgrade, $ssAuth, $ssDeadPool, $ssOutput, L:\costco_logs, L:\ftservlog.log -Recurse -Destination $destination -Force
        }
        catch {
            LogIt -Message "FAILED to gather log collection." -Severity Error -ForegroundColor Red
        }

        ForEach ($folder in $folders) {
            $fDate = (Get-Date).AddDays(-1).ToString("yyyyMMdd")
            $fipay = "L:\FTserv\stores\$folder\up\fipayeps.$fDate.log.gz"

            if (Test-Path $fipay) {
                try {
                    LogIt -Message "Gathering fipay logs." -Severity Information
                    Move-Item -Path $fipay -Destination "$destination\Fipay_Logs\fipayeps.$fDate.log.gz*" -Force
                    try {
                        LogIt -Message "Renaming fipay logs." -Severity Information    
                        Rename-Item -Path "$destination\Fipay_Logs\$folder.fipayeps.$fDate.log.gz" -NewName "$folder.fipayeps.$fDate.log.gz"
                    }
                    catch {
                        LogIt -Message "FAILED to rename fipay logs." -Severity Error -ForegroundColor Red
                    }
                }
                catch {
                    LogIt -Message "FAILED to gather fipay logs." -Severity Error -ForegroundColor Red
                }
            }
        }

        # Dump File Processing
        $dFiles = (Get-ChildItem $ssDump | Where { $_.LastWriteTime -ge $date.AddDays(-1) } | Select Name).Name
        ForEach ($file in $dFiles) {
            try {
                LogIt -Message "Gathering Dump logs." -Severity Information
                Move-Item $ssDump\$file -Destination $destination\DumpFiles
            }
            catch {
                LogIt -Message "FAILED to gather Dump logs." -Severity Error -ForegroundColor Red
            }
        }

        # Deletes temp Drive
        LogIt -Message "Disconnecting FT Server connection." -Severity Information
        Remove-PSDrive -Name L
    }
    Else {
        LogIt -Message "$server is OFFLINE. Unable to complete log collection" -Severity Error -ForegroundColor Red
    }
    
    Write-Host "Log Collection Complete. Collected logs are located in the following folder: 
    $destination"
    Read-Host -Prompt "Press 'ENTER' to continue."
}


Function enableCILUS {
    LogIt -Message "Starting enableCILUS function" -Severity Information

    do {
        $server = Read-Host -Prompt "Enter the US Lab site server name"
        $prompt = "Y"
        If ($server.Length -gt 14) {
            Write-Host "$server has MORE characters then the standard naming convention. The normal length is 14 characters. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server.Length -lt 14) {
            Write-Host "$server has LESS characters then the standard naming convention. The normal length is 14 characters. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server -NotLike "SERVERNAMINGCONVENTION*" -or $server -NotLike "*SERVERNAMINGCONVENTION") {
            Write-Host "$server has DOES NOT meet the PROD Standard Naming Convention. The standard naming convention in Prod is SERVERNAMINGCONVENTION. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
    }
    while ($prompt -ne "Y")

    LogIt -Message "User entered the following US Lab server to Enable Auto Auth: $server." -Severity Information

    If (Test-Connection $server -Count 2) {
        $siteConfig = 'D:\PATHTOFILE\siteConfig.json'
        $json = Get-Content -Raw $siteConfig | ConvertFrom-Json
        $wh = $json.storeId 
        $realFile = (Get-ChildItem -Path "\\$server\D$\PATHTOFILE\$wh*_config" | Select -Last 1 Name).Name
        $configFile = "\\$server\D$\PATHTOFILE\$realFile"
        $json = Get-Content -Raw $configFile | ConvertFrom-Json

        LogIt -Message "Activating CIL at store $wh on $server." -Severity Information

        $json.Update | % { $json.StoreConfiguration.Other.PumpAuthClient = "Y" }
        $json.Update | % { $json.StoreConfiguration.Other.AttendentApproving = "Y" }

        $json | ConvertTo-Json -Depth 8 | Format-Json | Out-File "\\$server\PATHTOFILE\Config_Update.json" -Encoding UTF8
        LogIt -Message "CIL Activated on $server. Please allow time for the config to be applied to the pumps." -Severity Information
    }
    Else {
        LogIt -Message "$server is OFFLINE. Unable to enable CIL." -Severity Warning -ForegroundColor Red
    }
}

Function enableAutoAuthUS {
    LogIt -Message "Starting enableAutoAuthUS function" -Severity Information

    do {
        $server = Read-Host -Prompt "Enter the US Lab site server name"
        $prompt = "Y"
        If ($server.Length -gt 14) {
            Write-Host "$server has MORE characters then the standard naming convention. The normal length is 14 characters. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server.Length -lt 14) {
            Write-Host "$server has LESS characters then the standard naming convention. The normal length is 14 characters. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server -NotLike "WPSFSS*" -or $server -NotLike "*T01") {
            Write-Host "$server has DOES NOT meet the LAB Standard Naming Convention. The standard naming convention in Prod is SERVERNAMINGCONVENTION. Example: SERVERNAMINGCONVENTION" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
    }
    while ($prompt -ne "Y")

    LogIt -Message "User entered the following US Lab server to Enable Auto Auth: $server." -Severity Information

    If (Test-Connection $server -Count 2) {
        $siteConfig = 'D:\PATHTOFILE\siteConfig.json'
        $json = Get-Content -Raw $siteConfig | ConvertFrom-Json
        $wh = $json.storeId 
        $realFile = (Get-ChildItem -Path "\\$server\D$\PATHTOFILE\SmartCRIND-2\siteserviceapi\oldVersionedStoreConfig\$wh*_config" | Select -Last 1 Name).Name
        $configFile = "\\$server\D$\PATHTOFILE\SmartCRIND-2\siteserviceapi\oldVersionedStoreConfig\$realFile"
        $json = Get-Content -Raw $configFile | ConvertFrom-Json

        LogIt -Message "Activating Auto Auth at store $wh on $server." -Severity Information

        $json.Update | % { $json.StoreConfiguration.Other.PumpAuthClient = "Y" }
        $json.Update | % { $json.StoreConfiguration.Other.AttendentApproving = "Y" }
        $json.Update | % { $json.StoreConfiguration.Other.P2PE = "Y" }

        $json | ConvertTo-Json -Depth 8 | Format-Json | Out-File "\\$server\PATHTOFILE\WatchDir\Config_Update.json" -Encoding UTF8
        LogIt -Message "Auto Auth Activated on $server. Please allow time for the config to be applied to the pumps." -Severity Information
    }
    Else {
        LogIt -Message "$server is OFFLINE. Unable to enable Auto Auth" -Severity Warning -ForegroundColor Red
    }
}

Function disableCILUS {
    LogIt -Message "Starting disableCILUS function" -Severity Information

    do {
        $server = Read-Host -Prompt "Enter the US Lab site server name (ex. WPSFSSxxxxxT01)"
        $prompt = "Y"
        If ($server.Length -gt 14) {
            Write-Host "$server has MORE characters then the standard naming convention. The normal length is 14 characters. Example: WPSFSS01234T01" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server.Length -lt 14) {
            Write-Host "$server has LESS characters then the standard naming convention. The normal length is 14 characters. Example: WPSFSS01234T01" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
        ElseIf ($server -NotLike "WPSFSS*" -or $server -NotLike "*T01") {
            Write-Host "$server has DOES NOT meet the US Site Server Standard Naming Convention. The standard naming convention in the lab is WPSFSSxxxxxT01. Example: WPSFSS01234T01" -ForegroundColor Yellow
            $prompt = Read-Host -Prompt "Are you sure $server is correct? (Y for Yes)"
        }
    }
    while ($prompt -ne "Y")

    LogIt -Message "User entered the following US Lab server to Disable Auto Auth: $server." -Severity Information

    If (Test-Connection $server -Count 2) {
        $siteConfig = 'D:\PATHTOFILE\siteConfig.json'
        $json = Get-Content -Raw $siteConfig | ConvertFrom-Json
        $wh = $json.storeId 
        $realFile = (Get-ChildItem -Path "\\$server\D$\PATHTOFILE\SmartCRIND-2\siteserviceapi\oldVersionedStoreConfig\$wh*_config" | Select -Last 1 Name).Name
        $configFile = "\\$server\D$\PATHTOFILE\SmartCRIND-2\siteserviceapi\oldVersionedStoreConfig\$realFile"
        $json = Get-Content -Raw $configFile | ConvertFrom-Json

        LogIt -Message "Disabling CIL and Auto Auth at store $wh on $server." -Severity Information

        $json.Update | % { $json.StoreConfiguration.Other.PumpAuthClient = "N" }
        $json.Update | % { $json.StoreConfiguration.Other.AttendentApproving = "N" }
        $json.Update | % { $json.StoreConfiguration.Other.P2PE = "N" }

        $json | ConvertTo-Json -Depth 8 | Format-Json | Out-File "\\$server\PATHTOFILE\WatchDir\Config_Update.json" -Encoding UTF8
        LogIt -Message "CIL Activated on $server. Please allow time for the config to be applied to the pumps." -Severity Information
    }
    Else {
        LogIt -Message "$server is OFFLINE. Unable to disable CIL." -Severity Warning -ForegroundColor Red
    }
}

Function usPatchValidation {
    LogIt -Message "Starting usPatchValidation function" -Severity Information
    if (!(Test-Connection $server -Count 2)) {
        LogIt -Message "$server is OFFLINE. Unable to check patches." -Severity Warning -ForegroundColor Yellow
        continue
    }
    Else {
        ForEach ($server in $servers) {
            If ($server -like "SERVERNAMINGCONVENTION*") {
                Get-HotFix -ComputerName $server | Select Source, HotFixID, InstalledOn
            }
        }
    }
}

Function caPatchValidation {
    LogIt -Message "Starting usPatchValidation function" -Severity Information
    if (!(Test-Connection $server -Count 2)) {
        LogIt -Message "$server is OFFLINE. Unable to check patches." -Severity Warning -ForegroundColor Yellow
        continue
    }
    Else {
        ForEach ($server in $servers) {
            If ($server -like "SERVERNAMINGCONVENTION*") {
                Get-HotFix -ComputerName $server | Select Source, HotFixID, InstalledOn
            }
        }
    }
}

# MENU FUNCTIONS
Function usOptions {
    do {
        $loopUsOptions = $true
        do {
            Write-Host "
            Fuel QA Tool Suite
            +++++++++++++++++++++++++++++++++++++++++++++++++++

            1 : View Service Status
            2 : Start Services
            3 : Get Application Versions
            4 : Log Collection for recent QA test
            5 : Enable Clerk in the Loop
            6 : Enable Auto Authorization
            7 : Disable Clerk in the Loop & Auto Authorization
            8 : View installed patches on US servers
            9 : Go back to Main Menu 

            +++++++++++++++++++++++++++++++++++++++++++++++++++
            "

            try {
                # try/catch inserted to prevent errors from populating on the screen if user enters anything other than a number.
                [int]$mainMenu = Read-Host -Prompt "Select the number associated with the system tests you would like to access. (1, 2 ,3...)"
            }
            catch {}

            If ($mainMenu -gt 8 -or $mainMenu -lt 1 -or $mainMenu -isnot [int] -or $mainMenu -eq "") {
                Write-Host "Invalid Option selected. Please try again..." -ForegroundColor Red
                $oops = $true
            }
            Else {
                $oops = $false
            }
        }
        while ($oops -eq $true)

        switch ($mainMenu) {
            1 { getServices }
            2 { startServices }
            3 { getAppVersions }
            4 { logCollector }
            5 { enableCILUS }
            6 { enableAutoAuthUS }
            7 { disableCILUS }
            8 { usPatchValidation }
            9 { $loopUsOptions = $false }
        }
    }
    while ($loopUsOptions -eq $true)
}

Function caOptions {
    do {
        $loopCaOptions = $true
        do {
            Write-Host "
            Fuel QA Tool Suite
            +++++++++++++++++++++++++++++++++++++++++++++++++++

            1 : View Service Status
            2 : Start Services
            3 : Get Application Versions
            4 : Log Collection for recent QA test (NOT OPERATIONAL AT THIS TIME)
            5 : View installed patches on CA servers
            6 : Go back to Main Menu 

            +++++++++++++++++++++++++++++++++++++++++++++++++++
            "

            try {
                # try/catch inserted to prevent errors from populating on the screen if user enters anything other than a number.
                [int]$mainMenu = Read-Host -Prompt "Select the number associated with the system tests you would like to access. (1, 2 ,3...)"
            }
            catch {}

            If ($mainMenu -gt 8 -or $mainMenu -lt 1 -or $mainMenu -isnot [int] -or $mainMenu -eq "") {
                Write-Host "Invalid Option selected. Please try again..." -ForegroundColor Red
                $oops = $true
            }
            Else {
                $oops = $false
            }
        }
        while ($oops -eq $true)

        switch ($mainMenu) {
            1 { caGetServices }
            2 { caStartServices }
            3 { caGetAppVersions }
            4 { caLogCollector }
            5 { caPatchValidation }
            6 { $loopCaOptions = $false }
        }
    }
    while ($loopCaOptions -eq $true)
}

Function gasBuyingOptions {
    #do {
    #$loopGasBuying = $true
    Write-Host "There are no Gas Buying system options at this time." -ForegroundColor Yellow
    Read-Host -Prompt "Press 'Enter' to go back to the previous menu."
    #}
    #while($loopGasBuying -eq $true)
}


# MAIN MENU
do {
    $appRun = $true
    do {
        Write-Host "
        Fuel QA Tool Suite
        +++++++++++++++++++++++++++++++++++++++++++++++++++

        1 : US Fuel
        2 : Canada Fuel
        3 : Gas Buying
        4 : Exit Application

        +++++++++++++++++++++++++++++++++++++++++++++++++++
        "

        try {
            # try/catch inserted to prevent errors from populating on the screen if user enters anything other than a number.
            [int]$mainMenu = Read-Host -Prompt "Select the number associated with the system tests you would like to access. (1, 2 ,3...)"
        }
        catch {}
        If ($mainMenu -gt 4 -or $mainMenu -lt 1 -or $mainMenu -isnot [int] -or $mainMenu -eq "") {
            Write-Host "Invalid Option selected. Please try again..." -ForegroundColor Red
            $oops = $true
        }
        Else {
            $oops = $false
        }
    }
    while ($oops -eq $true)

    switch ($mainMenu) {

        1 { usOptions }
        2 { caOptions }
        3 { gasBuyingOptions }
        4 { 
            LogIt -Message "User selected option to exit the application. Closing app." -Severity Information
            exit
        }
    }
}
while ($appRun -eq $true)

