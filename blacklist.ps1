# ��ȡ��ǰ�ű�ִ��Ŀ¼
$currentDir = Get-Location
$outputPath = Join-Path $currentDir "gfwlist_clash_rules.yaml"

# ���� GFWList ������
$gfwlistUrl = "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
$encodedContent = Invoke-WebRequest -Uri $gfwlistUrl -UseBasicParsing
$decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedContent.Content))

# ���ߺ���
function Extract-Domain($url) {
    if ($url -match "^(?:https?:\/\/)?([^\/]+)") { return $matches[1] } else { return $url }
}
function Decode-Url($text) { return [System.Uri]::UnescapeDataString($text) }
function Is-IpAddress($text) { return $text -match "^(\d{1,3}\.){3}\d{1,3}$" }
function Is-IpWithPort($text) { return $text -match "^(\d{1,3}\.){3}\d{1,3}:\d+$" }
function Is-Domain($text) { return $text -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" }
function Clean-Domain($text) { return $text.TrimStart(".").Replace("*", "") }

# �����¹���
$newRules = @()
foreach ($line in $decodedContent -split "`n") {
    $line = $line.Trim()
    if ($line -eq "" -or $line.StartsWith("!") -or $line.StartsWith("[") -or $line.StartsWith("@@")) { continue }

    $decodedLine = Decode-Url($line)
    if ([string]::IsNullOrWhiteSpace($decodedLine)) { continue }

    if ($decodedLine -match "\*") {
        $domain = Extract-Domain($decodedLine.Replace("*", ""))
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain)) { $newRules += "  - DOMAIN-SUFFIX,$domain,Proxy" }
        continue
    }

    if ($decodedLine -match "/") {
        $domain = Extract-Domain($decodedLine)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain) -or Is-IpAddress($domain)) { $newRules += "  - DOMAIN,$domain,Proxy" }
        continue
    }

    if ($decodedLine.StartsWith("||")) {
        $domain = Clean-Domain($decodedLine.Substring(2))
        if (Is-Domain($domain)) { $newRules += "  - DOMAIN-SUFFIX,$domain,Proxy" }
        continue
    }

    if ($decodedLine.StartsWith("|")) {
        $domain = Extract-Domain($decodedLine.Substring(1))
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain) -or Is-IpAddress($domain)) { $newRules += "  - DOMAIN,$domain,Proxy" }
        continue
    }

    if ($decodedLine.StartsWith(".")) {
        $domain = Clean-Domain($decodedLine)
        if (Is-Domain($domain)) { $newRules += "  - DOMAIN-SUFFIX,$domain,Proxy" }
        continue
    }

    if (Is-Domain($decodedLine)) {
        $newRules += "  - DOMAIN-SUFFIX,$decodedLine,Proxy"
        continue
    }

    if (Is-IpAddress($decodedLine) -or Is-IpWithPort($decodedLine)) {
        $newRules += "  - DOMAIN,$decodedLine,Proxy"
        continue
    }

    if ($decodedLine -match "\." -and $decodedLine -notmatch "/" -and -not (Is-IpAddress($decodedLine)) -and -not (Is-IpWithPort($decodedLine)) -and $decodedLine -notmatch "\*") {
        $newRules += "  - KEYWORD,$decodedLine,Proxy"
    }
}

# ���ؾɹ���������ڣ����ų� MATCH,DIRECT
$preservedRules = @()
if (Test-Path $outputPath) {
    $oldContent = Get-Content $outputPath | Where-Object {
        $_.Trim().StartsWith("-") -and $_.Trim().ToUpper() -ne "- MATCH,DIRECT" -and $_.Trim().ToUpper() -ne "  - MATCH,DIRECT"
    }
    foreach ($oldRule in $oldContent) {
        if (-not ($newRules -contains $oldRule)) {
            $preservedRules += $oldRule
        }
    }
}

# �ϲ���ȥ�أ��û��Զ���������ȣ�MATCH,DIRECT ���
$finalRules = @("rules:")
$finalRules += ($preservedRules | Select-Object -Unique)
$finalRules += ($newRules | Select-Object -Unique)
$finalRules += "  - MATCH,DIRECT"

# д���ļ�
$finalRules | Set-Content -Encoding UTF8 -Path $outputPath
Write-Host "? Clash Verge �����ļ��Ѹ��£�" $outputPath
