# Prompt for PAC file path
$pacFile = Read-Host "Enter the full path to your PAC file (e.g., C:\Users\LISI\pac.js)"

# Validate file existence
if (-Not (Test-Path $pacFile)) {
    Write-Host "❌ File not found. Please check the path and try again." -ForegroundColor Red
    exit
}

# Get current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outputFile = Join-Path $scriptDir "clash_rules.txt"

# Read PAC file content
$pacContent = Get-Content $pacFile -Raw

# Extract white_domains block
$start = $pacContent.IndexOf("var white_domains =")
$end = $pacContent.IndexOf("};", $start)
$block = $pacContent.Substring($start, $end - $start + 2)

# Extract domain entries using regex
$pattern = '"?(\w+)"?\s*:\s*{\s*([^}]*)\s*}'
$matches = [regex]::Matches($block, $pattern)

$rules = @()

foreach ($match in $matches) {
    $entries = $match.Groups[2].Value

    $entryPattern = '"?([\w\-\.]*)"?\s*:\s*1'
    $entryMatches = [regex]::Matches($entries, $entryPattern)

    foreach ($entry in $entryMatches) {
        $sub = $entry.Groups[1].Value
        if ($sub -ne "") {
            $rules += "DOMAIN:$sub,DIRECT"
        }
    }
}

# Add fallback rule
$rules += "MATCH,PROXY"

# Save to output file
$rules | Sort-Object -Unique | Set-Content $outputFile -Encoding UTF8

Write-Host "`n✅ Clash rules generated with suffixes removed!"
Write-Host "📄 Saved to: $outputFile" -ForegroundColor Green
