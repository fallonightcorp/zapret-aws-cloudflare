# Set encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Path to save the list
$listPath = Join-Path -Path $PSScriptRoot -ChildPath "lists\list-aws-amazon.txt"

# AWS IP ranges URL
$url = "https://ip-ranges.amazonaws.com/ip-ranges.json"

# Try to fetch data
try {
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        $data = $response.Content | ConvertFrom-Json
        $ips = $data.prefixes | Where-Object { $_.service -eq "AMAZON" } | ForEach-Object { $_.ip_prefix }

        # Ensure directory exists
        $dir = Split-Path -Path $listPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }

        # Write IPs to file
        $ips | Out-File -FilePath $listPath -Encoding utf8

        Write-Host "[INFO] IP updated: $($ips.Count) IPs added."
    } else {
        Write-Host "[ERROR] Failed to fetch data. Error code: $($response.StatusCode)"
        exit 1
    }
}
catch {
    Write-Host "[ERROR] Request failed: Timeout or other error."
    Write-Host "[INFO] Using the current IP list."
    exit 1
}
