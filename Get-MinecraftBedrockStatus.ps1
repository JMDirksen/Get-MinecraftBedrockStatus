function Get-MinecraftBedrockStatus {
    param (
        $Server = "255.255.255.255",
        $Port = 19132,
        $Timeout = 3000
    )

    if ($Server -like "*:*") {
        $split = $Server -split ":"
        $Server = $split[0]
        $Port = $split[1]
    }

    $ip = Get-IPv4 $Server
    $addr = [System.Net.IPAddress]::Parse($ip)
    $endpoint = New-Object System.Net.IPEndPoint($addr, $Port)
    $socket = New-Object System.Net.Sockets.UDPClient
    $socket.Client.SendTimeout = $Timeout
    $socket.Client.ReceiveTimeout = $Timeout
    
    [byte[]]$id = 0x01
    [byte[]]$time = 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
    [byte[]]$magic = 0x00, 0xFF, 0xFF, 0x00, 0xFE, 0xFE, 0xFE, 0xFE, 0xFD, 0xFD, 0xFD, 0xFD, 0x12, 0x34, 0x56, 0x78
    [byte[]]$guid = 2
    [byte[]]$msg = $id + $time + $magic + $guid
    $socket.Send($msg, $msg.Count, $endpoint) | Out-Null
    $response = $null
    $response = $socket.Receive([ref]$endpoint)
    $socket.Close()
    
    $fields = [Text.Encoding]::ASCII.GetString($response[35..$response.Length]).Split(";")

    @{
        "Server" = $Server
        "Port" = $Port
        "IP" = $ip
        "Edition" = $fields[0]
        "ServerName" = $fields[1]
        "ProtocolVersion" = $fields[2]
        "VersionName" = $fields[3]
        "PlayerCount" = $fields[4]
        "MaxPlayerCount" = $fields[5]
        "ServerUniqueID" = $fields[6]
        "LevelName" = $fields[7]
        "Gamemode" = $fields[8]
        "GamemodeID" = $fields[9]
        "PortIPv4" = $fields[10]
        "PortIPv6" = $fields[11]
        "unidentified" = $fields[12..99] -join " "
    }
}

function Get-IPv4 ($HostnameOrIp) {
    $ipv4 = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    if ($HostnameOrIp -match $ipv4) {
        return $HostnameOrIp
    }
    return (Resolve-DnsName $HostnameOrIp -Type A)[0].IPAddress
}
