param(
    [Parameter(Mandatory = $true)]
    [string[]]$Urls,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [switch]$GbTOnly
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$work = Join-Path $OutDir '.openstd_tmp'
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Get-TextFileOrUrl {
    param([string]$Source, [string]$Target)

    if (Test-Path -LiteralPath $Source) {
        return Get-Content -LiteralPath $Source -Raw -Encoding UTF8
    }

    & curl.exe -L -sS -A 'Mozilla/5.0' --connect-timeout 60 --max-time 180 $Source -o $Target
    if ($LASTEXITCODE -ne 0) { throw "curl failed for $Source" }
    return Get-Content -LiteralPath $Target -Raw -Encoding UTF8
}

function Convert-SourceViewHtml {
    param([string]$Html)

    $text = $Html -replace '<span class="html-[^"]+">', ''
    $text = $text -replace '</span>', ''
    $text = $text -replace '<a [^>]*>', ''
    $text = $text -replace '</a>', ''
    return [System.Net.WebUtility]::HtmlDecode($text)
}

function Strip-Html {
    param([string]$Html)
    $decoded = [System.Net.WebUtility]::HtmlDecode($Html)
    $plain = $decoded -replace '<[^>]+>', ' '
    return ($plain -replace '\s+', ' ').Trim()
}

function Match-First {
    param([string]$Text, [string[]]$Patterns)
    foreach ($pattern in $Patterns) {
        $m = [regex]::Match($Text, $pattern, 'Singleline')
        if ($m.Success) { return (Strip-Html $m.Groups[1].Value) }
    }
    return ''
}

function Safe-Name {
    param([string]$Name)
    return (($Name -replace '[\\/:*?"<>|]+', '_') -replace '\s+', ' ').Trim().TrimEnd('.')
}

function Get-Hcno {
    param([string]$Source, [string]$Html)

    $m = [regex]::Match($Source, 'hcno=([A-F0-9]{32})')
    if ($m.Success) { return $m.Groups[1].Value }

    $m = [regex]::Match($Html, 'newGbInfo\?hcno=([A-F0-9]{32})')
    if ($m.Success) { return $m.Groups[1].Value }

    $m = [regex]::Match($Html, 'data-value=["'']([A-F0-9]{32})')
    if ($m.Success) { return $m.Groups[1].Value }

    $m = [regex]::Match($Html, 'hcno=([A-F0-9]{32})')
    if ($m.Success) { return $m.Groups[1].Value }

    return ''
}

function Get-StandardMeta {
    param([string]$Source, [string]$Html)

    $html = Convert-SourceViewHtml $Html
    $plain = Strip-Html $html
    $stdNo = Match-First $html @(
        '<dt[^>]*>\s*标准号\s*</dt>\s*<dd[^>]*>(.*?)</dd>',
        '标准号：\s*([^<\r\n]+)',
        '<title>\s*国家标准\|([^<]+)</title>'
    )
    $name = Match-First $html @(
        '中文标准名称：\s*<b[^>]*>(.*?)</b>',
        '<h4[^>]*>(.*?)</h4>',
        '国家标准《([^》]+)》'
    )
    $date = Match-First $html @(
        '<dt[^>]*>\s*发布日期\s*</dt>\s*<dd[^>]*>(.*?)</dd>',
        '发布日期\s*</div>\s*<div[^>]*class="[^"]*content[^"]*"[^>]*>(.*?)</div>'
    )
    if (!$stdNo) { $stdNo = Match-First $plain @('标准号：\s*(GB/T\s*[\d\.\-]+)') }
    if (!$name) { $name = Match-First $plain @('中文标准名称：\s*(.*?)\s*英文标准名称') }
    if (!$date) { $date = Match-First $plain @('发布日期\s*(\d{4}-\d{2}-\d{2})') }
    $date = $date -replace '[^\d]', ''

    [pscustomobject]@{
        Source = $Source
        StandardNo = $stdNo
        Name = $name
        ReleaseDate = $date
        Hcno = Get-Hcno $Source $html
    }
}

function Save-OpenstdPdf {
    param([pscustomobject]$Meta)

    $file = Safe-Name "$($Meta.ReleaseDate)_$($Meta.Name)_$($Meta.StandardNo).pdf"
    $dest = Join-Path $OutDir $file
    $cookie = Join-Path $work "$($Meta.Hcno).cookie.txt"
    $downloadHtml = Join-Path $work "$($Meta.Hcno).download.html"
    $show = "https://openstd.samr.gov.cn/bzgk/std/showGb?type=download&hcno=$($Meta.Hcno)&request_locale=zh"
    $view = "https://openstd.samr.gov.cn/bzgk/std/viewGb?hcno=$($Meta.Hcno)"

    Remove-Item -LiteralPath $dest, $cookie, $downloadHtml -ErrorAction SilentlyContinue
    & curl.exe -L -sS -c $cookie -b $cookie -A 'Mozilla/5.0' -e "https://openstd.samr.gov.cn/bzgk/std/newGbInfo?hcno=$($Meta.Hcno)" --connect-timeout 60 --max-time 180 $show -o $downloadHtml
    if ($LASTEXITCODE -ne 0) { throw "showGb failed for $($Meta.StandardNo)" }

    & curl.exe -L -sS -b $cookie -A 'Mozilla/5.0' -e $show --connect-timeout 60 --max-time 300 $view -o $dest
    if ($LASTEXITCODE -ne 0) { throw "viewGb failed for $($Meta.StandardNo)" }

    if (!(Test-Path -LiteralPath $dest) -or (Get-Item -LiteralPath $dest).Length -lt 4) {
        Remove-Item -LiteralPath $dest -ErrorAction SilentlyContinue
        throw "empty PDF response for $($Meta.StandardNo)"
    }

    $bytes = [System.IO.File]::ReadAllBytes($dest)
    $head = [System.Text.Encoding]::ASCII.GetString($bytes[0..3])
    if ($head -ne '%PDF') {
        Remove-Item -LiteralPath $dest -ErrorAction SilentlyContinue
        throw "response is not a PDF for $($Meta.StandardNo)"
    }

    [pscustomobject]@{ Status = 'OK'; File = $dest; Bytes = $bytes.Length; StandardNo = $Meta.StandardNo }
}

foreach ($source in $Urls) {
    try {
        $pageFile = Join-Path $work (([guid]::NewGuid().ToString()) + '.html')
        $html = Get-TextFileOrUrl $source $pageFile
        $meta = Get-StandardMeta $source $html

        if ($GbTOnly -and !$meta.StandardNo.StartsWith('GB/T')) {
            [pscustomobject]@{ Status = 'SKIP'; Source = $source; Reason = "not GB/T: $($meta.StandardNo)" }
            continue
        }
        if (!$meta.Hcno) {
            [pscustomobject]@{ Status = 'SKIP'; Source = $source; Reason = 'no hcno found' }
            continue
        }
        if (!$meta.StandardNo -or !$meta.Name -or !$meta.ReleaseDate) {
            [pscustomobject]@{ Status = 'SKIP'; Source = $source; Reason = 'missing standard number, title, or release date' }
            continue
        }

        Save-OpenstdPdf $meta
    } catch {
        [pscustomobject]@{ Status = 'SKIP'; Source = $source; Reason = $_.Exception.Message }
    }
}

Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue


