# 获取当前脚本执行目录
$currentDir = Get-Location
$outputPath = Join-Path $currentDir "gfwlist_clash_rules.yaml"

# 下载 GFWList 并解码
$gfwlistUrl = "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
$encodedContent = Invoke-WebRequest -Uri $gfwlistUrl -UseBasicParsing
$decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedContent.Content))

# 工具函数
function Extract-Domain($url) {
    if ($url -match "^(?:https?:\/\/)?([^\/]+)") { return $matches[1] } else { return $url }
}
function Decode-Url($text) { return [System.Uri]::UnescapeDataString($text) }
function Is-IpAddress($text) { return $text -match "^(\d{1,3}\.){3}\d{1,3}$" }
function Is-IpWithPort($text) { return $text -match "^(\d{1,3}\.){3}\d{1,3}:\d+$" }
function Is-Domain($text) { return $text -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" }
function Clean-Domain($text) { return $text.TrimStart(".").Replace("*", "") }

# 生成新规则
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

# 加载旧规则（如果存在），排除 MATCH,DIRECT
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

# 合并并去重：用户自定义规则优先，MATCH,DIRECT 最后
$finalRules = @("rules:")
$finalRules += ($preservedRules | Select-Object -Unique)
$finalRules += ($newRules | Select-Object -Unique)
$finalRules += "  - MATCH,DIRECT"

# 写入文件
$finalRules | Set-Content -Encoding UTF8 -Path $outputPath
Write-Host "? Clash Verge 规则文件已更新：" $outputPath
