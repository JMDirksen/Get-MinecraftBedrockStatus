function Get-MinecraftBedrockStatus {
    param (
        [string]$Server = "255.255.255.255",
        [int]$Port = 19132,
        [int]$Timeout = 5000
    )

    if ($Server -like "*:*") {
        $split = $Server -split ":"
        $Server = $split[0]
        $Port = [int]$split[1]
    }

    $ip = Get-IPv4 $Server
    $addr = [System.Net.IPAddress]::Parse($ip)
    try { $endpoint = New-Object System.Net.IPEndPoint($addr, $Port) }
    catch { throw "Incorrect port number" }
    
    [byte[]]$id = 0x01
    [byte[]]$time = 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
    [byte[]]$magic = 0x00, 0xFF, 0xFF, 0x00, 0xFE, 0xFE, 0xFE, 0xFE, 0xFD, 0xFD, 0xFD, 0xFD, 0x12, 0x34, 0x56, 0x78
    [byte[]]$guid = 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02
    [byte[]]$msg = $id + $time + $magic + $guid

    try {
        $socket = New-Object System.Net.Sockets.UDPClient
        $socket.Client.SendTimeout = $Timeout
        $socket.Client.ReceiveTimeout = $Timeout
        $socket.Send($msg, $msg.Count, $endpoint) | Out-Null
        $response = $socket.Receive([ref]$endpoint)
    }
    catch { throw "No response" }
    finally { $socket.Close() }
    
    $fields = [Text.Encoding]::UTF8.GetString($response[35..$response.Length]).Split(";")

    [PSCustomObject]@{
        "Server"          = $Server
        "Port"            = $Port
        "IP"              = $ip
        "Edition"         = $fields[0]
        "ServerName"      = $fields[1]
        "ProtocolVersion" = [int]$fields[2]
        "VersionName"     = $fields[3]
        "PlayerCount"     = [int]$fields[4]
        "MaxPlayerCount"  = [int]$fields[5]
        "ServerUniqueID"  = $fields[6]
        "LevelName"       = $fields[7]
        "Gamemode"        = $fields[8]
        "GamemodeID"      = [int]$fields[9]
        "PortIPv4"        = [int]$fields[10]
        "PortIPv6"        = [int]$fields[11]
        "Unidentified"    = $fields[12..99] -join " "
    }
}

function Get-IPv4 ([string]$HostnameOrIp) {
    $ipv4 = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    if ($HostnameOrIp -match $ipv4) { return $HostnameOrIp }
    try { $resolve = Resolve-DnsName $HostnameOrIp -Type A -ErrorAction Stop }
    catch { throw "Unable to resolve server name" }
    $resolve = $resolve | Where-Object { $_.Type -eq "A" } | Select-Object -First 1
    return [string]$resolve.Address
}
