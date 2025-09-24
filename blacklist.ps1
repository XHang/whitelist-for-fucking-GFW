# 获取当前脚本执行目录
$currentDir = Get-Location

# 下载 GFWList 并解码
$gfwlistUrl = "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
$encodedContent = Invoke-WebRequest -Uri $gfwlistUrl -UseBasicParsing
$decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedContent.Content))

# 创建输出规则列表，添加 YAML 头部
$rules = @("rules:")

# 提取域名
function Extract-Domain($url) {
    if ($url -match "^(?:https?:\/\/)?([^\/]+)") {
        return $matches[1]
    } else {
        return $url
    }
}

# 解码 URL 编码
function Decode-Url($text) {
    return [System.Uri]::UnescapeDataString($text)
}

# 判断是否为 IP 地址
function Is-IpAddress($text) {
    return $text -match "^(\d{1,3}\.){3}\d{1,3}$"
}

# 判断是否为 IP:端口
function Is-IpWithPort($text) {
    return $text -match "^(\d{1,3}\.){3}\d{1,3}:\d+$"
}

# 判断是否为合法域名
function Is-Domain($text) {
    return $text -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
}

# 清理前导句点和通配符
function Clean-Domain($text) {
    return $text.TrimStart(".").Replace("*", "")
}

# 处理每一行
foreach ($line in $decodedContent -split "`n") {
    $line = $line.Trim()
    if ($line -eq "" -or $line.StartsWith("!") -or $line.StartsWith("[") -or $line.StartsWith("@@")) {
        continue
    }

    $decodedLine = Decode-Url($line)
    if ([string]::IsNullOrWhiteSpace($decodedLine)) {
        continue
    }

    # 通配符规则 → 提取主域名并使用 DOMAIN-SUFFIX
    if ($decodedLine -match "\*") {
        $domain = $decodedLine.Replace("*", "")
        $domain = Extract-Domain($domain)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain)) {
            $rules += "  - DOMAIN-SUFFIX,$domain,Proxy"
        }
        continue
    }

    # 包含路径 → 提取域名并使用 DOMAIN
    if ($decodedLine -match "/") {
        $domain = Extract-Domain($decodedLine)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain) -or Is-IpAddress($domain)) {
            $rules += "  - DOMAIN,$domain,Proxy"
        }
        continue
    }

    # || 开头 → DOMAIN-SUFFIX
    if ($decodedLine.StartsWith("||")) {
        $domain = $decodedLine.Substring(2)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain)) {
            $rules += "  - DOMAIN-SUFFIX,$domain,Proxy"
        }
        continue
    }

    # | 开头 → DOMAIN（需验证）
    if ($decodedLine.StartsWith("|")) {
        $url = $decodedLine.Substring(1)
        $domain = Extract-Domain($url)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain) -or Is-IpAddress($domain)) {
            $rules += "  - DOMAIN,$domain,Proxy"
        }
        continue
    }

    # . 开头 → DOMAIN-SUFFIX（去掉前导点和通配符）
    if ($decodedLine.StartsWith(".")) {
        $domain = Clean-Domain($decodedLine)
        if (Is-Domain($domain)) {
            $rules += "  - DOMAIN-SUFFIX,$domain,Proxy"
        }
        continue
    }

    # 普通域名 → DOMAIN-SUFFIX
    if (Is-Domain($decodedLine)) {
        $rules += "  - DOMAIN-SUFFIX,$decodedLine,Proxy"
        continue
    }

    # IP 地址或 IP:端口 → DOMAIN
    if (Is-IpAddress($decodedLine) -or Is-IpWithPort($decodedLine)) {
        $rules += "  - DOMAIN,$decodedLine,Proxy"
        continue
    }

    # 关键词（排除路径、IP、IP:端口、通配符）
    if ($decodedLine -match "\." -and $decodedLine -notmatch "/" -and -not (Is-IpAddress($decodedLine)) -and -not (Is-IpWithPort($decodedLine)) -and $decodedLine -notmatch "\*") {
        $rules += "  - KEYWORD,$decodedLine,Proxy"
    }
}

# 添加兜底规则
$rules += "  - MATCH,DIRECT"

# 输出文件路径
$outputPath = Join-Path $currentDir "gfwlist_clash_rules.yaml"
$rules | Set-Content -Encoding UTF8 -Path $outputPath

Write-Host "? Clash Verge 规则文件已生成：" $outputPath
