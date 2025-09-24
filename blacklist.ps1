# ��ȡ��ǰ�ű�ִ��Ŀ¼
$currentDir = Get-Location

# ���� GFWList ������
$gfwlistUrl = "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
$encodedContent = Invoke-WebRequest -Uri $gfwlistUrl -UseBasicParsing
$decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedContent.Content))

# ������������б���� YAML ͷ��
$rules = @("rules:")

# ��ȡ����
function Extract-Domain($url) {
    if ($url -match "^(?:https?:\/\/)?([^\/]+)") {
        return $matches[1]
    } else {
        return $url
    }
}

# ���� URL ����
function Decode-Url($text) {
    return [System.Uri]::UnescapeDataString($text)
}

# �ж��Ƿ�Ϊ IP ��ַ
function Is-IpAddress($text) {
    return $text -match "^(\d{1,3}\.){3}\d{1,3}$"
}

# �ж��Ƿ�Ϊ IP:�˿�
function Is-IpWithPort($text) {
    return $text -match "^(\d{1,3}\.){3}\d{1,3}:\d+$"
}

# �ж��Ƿ�Ϊ�Ϸ�����
function Is-Domain($text) {
    return $text -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
}

# ����ǰ������ͨ���
function Clean-Domain($text) {
    return $text.TrimStart(".").Replace("*", "")
}

# ����ÿһ��
foreach ($line in $decodedContent -split "`n") {
    $line = $line.Trim()
    if ($line -eq "" -or $line.StartsWith("!") -or $line.StartsWith("[") -or $line.StartsWith("@@")) {
        continue
    }

    $decodedLine = Decode-Url($line)
    if ([string]::IsNullOrWhiteSpace($decodedLine)) {
        continue
    }

    # ͨ������� �� ��ȡ��������ʹ�� DOMAIN-SUFFIX
    if ($decodedLine -match "\*") {
        $domain = $decodedLine.Replace("*", "")
        $domain = Extract-Domain($domain)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain)) {
            $rules += "  - DOMAIN-SUFFIX,$domain,Proxy"
        }
        continue
    }

    # ����·�� �� ��ȡ������ʹ�� DOMAIN
    if ($decodedLine -match "/") {
        $domain = Extract-Domain($decodedLine)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain) -or Is-IpAddress($domain)) {
            $rules += "  - DOMAIN,$domain,Proxy"
        }
        continue
    }

    # || ��ͷ �� DOMAIN-SUFFIX
    if ($decodedLine.StartsWith("||")) {
        $domain = $decodedLine.Substring(2)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain)) {
            $rules += "  - DOMAIN-SUFFIX,$domain,Proxy"
        }
        continue
    }

    # | ��ͷ �� DOMAIN������֤��
    if ($decodedLine.StartsWith("|")) {
        $url = $decodedLine.Substring(1)
        $domain = Extract-Domain($url)
        $domain = Clean-Domain($domain)
        if (Is-Domain($domain) -or Is-IpAddress($domain)) {
            $rules += "  - DOMAIN,$domain,Proxy"
        }
        continue
    }

    # . ��ͷ �� DOMAIN-SUFFIX��ȥ��ǰ�����ͨ�����
    if ($decodedLine.StartsWith(".")) {
        $domain = Clean-Domain($decodedLine)
        if (Is-Domain($domain)) {
            $rules += "  - DOMAIN-SUFFIX,$domain,Proxy"
        }
        continue
    }

    # ��ͨ���� �� DOMAIN-SUFFIX
    if (Is-Domain($decodedLine)) {
        $rules += "  - DOMAIN-SUFFIX,$decodedLine,Proxy"
        continue
    }

    # IP ��ַ�� IP:�˿� �� DOMAIN
    if (Is-IpAddress($decodedLine) -or Is-IpWithPort($decodedLine)) {
        $rules += "  - DOMAIN,$decodedLine,Proxy"
        continue
    }

    # �ؼ��ʣ��ų�·����IP��IP:�˿ڡ�ͨ�����
    if ($decodedLine -match "\." -and $decodedLine -notmatch "/" -and -not (Is-IpAddress($decodedLine)) -and -not (Is-IpWithPort($decodedLine)) -and $decodedLine -notmatch "\*") {
        $rules += "  - KEYWORD,$decodedLine,Proxy"
    }
}

# ��Ӷ��׹���
$rules += "  - MATCH,DIRECT"

# ����ļ�·��
$outputPath = Join-Path $currentDir "gfwlist_clash_rules.yaml"
$rules | Set-Content -Encoding UTF8 -Path $outputPath

Write-Host "? Clash Verge �����ļ������ɣ�" $outputPath
