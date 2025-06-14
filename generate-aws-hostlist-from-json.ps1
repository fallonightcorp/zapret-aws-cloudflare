# Set UTF-8 output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Output path
$hostListPath = Join-Path $PSScriptRoot "lists\list-aws-amazon-hosts.txt"
$url = "https://ip-ranges.amazonaws.com/ip-ranges.json"

try {
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content) {
        $data = $response.Content | ConvertFrom-Json
        $hosts = @()

        foreach ($prefix in $data.prefixes) {
            if ($prefix.service -eq "AMAZON") {
                $region = $prefix.region
                $service = $prefix.service.ToLower()
                $hostname = "$service.$region.amazonaws.com"
                $hosts += $hostname
            }
        }

        $hosts = $hosts | Sort-Object -Unique
        $hosts | Out-File -FilePath $hostListPath -Encoding utf8

        Write-Host "[INFO] Hostlist generated: $($hosts.Count) hosts"
        Write-Host "Saved to: $hostListPath"
    }
    else {
        Write-Host "[ERROR] Failed to fetch AWS IP JSON. Status: $($response.StatusCode)"
        exit 1
    }
}
catch {
    Write-Host "[ERROR] Request failed. Timeout or other issue."
    exit 1
}
