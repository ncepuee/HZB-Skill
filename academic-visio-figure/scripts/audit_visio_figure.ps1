[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$VsdxPath,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ProfilePath,

    [Nullable[double]]$ExpectedPageWidthCm,
    [Nullable[double]]$ExpectedLineWeightPt,
    [Nullable[int]]$ExpectedArrowType,
    [double[]]$AllowedFontSizePt,
    [switch]$RequireNoMedia,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$resolvedPath = (Resolve-Path -LiteralPath $VsdxPath).Path
$profileName = $null
$profileNotes = @()
$requireNoMediaEffective = $RequireNoMedia.IsPresent

if ($ProfilePath) {
    $profile = Get-Content -LiteralPath $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $profileName = [string]$profile.name
    if ($profile.notes) { $profileNotes = @($profile.notes | ForEach-Object { [string]$_ }) }

    if (-not $PSBoundParameters.ContainsKey('ExpectedPageWidthCm') -and $null -ne $profile.expectedPageWidthCm) {
        $ExpectedPageWidthCm = [double]$profile.expectedPageWidthCm
    }
    if (-not $PSBoundParameters.ContainsKey('ExpectedLineWeightPt') -and $null -ne $profile.expectedLineWeightPt) {
        $ExpectedLineWeightPt = [double]$profile.expectedLineWeightPt
    }
    if (-not $PSBoundParameters.ContainsKey('ExpectedArrowType') -and $null -ne $profile.expectedArrowType) {
        $ExpectedArrowType = [int]$profile.expectedArrowType
    }
    if (-not $PSBoundParameters.ContainsKey('AllowedFontSizePt') -and $profile.allowedFontSizesPt) {
        $AllowedFontSizePt = @($profile.allowedFontSizesPt | ForEach-Object { [double]$_ })
    }
    if (-not $PSBoundParameters.ContainsKey('RequireNoMedia') -and $null -ne $profile.requireNoMedia) {
        $requireNoMediaEffective = [bool]$profile.requireNoMedia
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedPath)
try {
    $media = @(
        $archive.Entries |
            Where-Object { $_.FullName -like 'visio/media/*' -and $_.Name } |
            ForEach-Object { $_.FullName }
    )
}
finally {
    $archive.Dispose()
}

$totals = [ordered]@{
    recursive_shapes = 0
    group_shapes     = 0
    one_d_shapes     = 0
    text_shapes      = 0
    visible_strokes  = 0
    visible_fills    = 0
}
$dist = [ordered]@{
    line_weight_pt   = @{}
    begin_arrow      = @{}
    end_arrow        = @{}
    begin_arrow_size = @{}
    end_arrow_size   = @{}
    line_color       = @{}
    fill_color       = @{}
    character_size_pt = @{}
}
$unicode = [ordered]@{
    text_with_combining_marks_count = 0
    samples = @()
}
$pages = @()
$warnings = @()

function Add-Count {
    param([hashtable]$Table, [string]$Key)
    if ($Table.ContainsKey($Key)) { $Table[$Key]++ } else { $Table[$Key] = 1 }
}

function Get-CellResult {
    param($Shape, [string]$CellName)
    try { return [double]$Shape.CellsU($CellName).ResultIU } catch { return $null }
}

function Visit-Shape {
    param($Shape, [string]$PageName)

    $script:totals.recursive_shapes++
    try { if ([int]$Shape.Type -eq 2) { $script:totals.group_shapes++ } } catch {}
    try { if ([int]$Shape.OneD -ne 0) { $script:totals.one_d_shapes++ } } catch {}

    $text = ''
    try { $text = ([string]$Shape.Text).Trim() } catch {}
    if ($text) {
        $script:totals.text_shapes++
        if ($text -match '\p{M}') {
            $script:unicode.text_with_combining_marks_count++
            if ($script:unicode.samples.Count -lt 20) {
                $script:unicode.samples += [ordered]@{
                    page = $PageName; shape_id = [int]$Shape.ID; text = $text
                }
            }
        }

        try {
            if ([int]$Shape.SectionExists(3, 0) -ne 0) {
                $rows = [int]$Shape.RowCount(3)
                for ($row = 0; $row -lt $rows; $row++) {
                    $size = [double]$Shape.CellsSRC(3, $row, 7).ResultIU
                    Add-Count $script:dist.character_size_pt ([string][math]::Round($size * 72, 3))
                }
            }
        }
        catch {}
    }

    $linePattern = Get-CellResult $Shape 'LinePattern'
    if ($null -ne $linePattern -and $linePattern -ne 0) {
        $script:totals.visible_strokes++
        $weight = Get-CellResult $Shape 'LineWeight'
        if ($null -ne $weight) {
            Add-Count $script:dist.line_weight_pt ([string][math]::Round($weight * 72, 3))
        }
        try { Add-Count $script:dist.line_color ([string]$Shape.CellsU('LineColor').FormulaU) } catch {}

        foreach ($mapping in @(
            @('BeginArrow', 'begin_arrow'),
            @('EndArrow', 'end_arrow'),
            @('BeginArrowSize', 'begin_arrow_size'),
            @('EndArrowSize', 'end_arrow_size')
        )) {
            $value = Get-CellResult $Shape $mapping[0]
            if ($null -ne $value) {
                Add-Count $script:dist[$mapping[1]] ([string][int][math]::Round($value))
            }
        }
    }

    $fillPattern = Get-CellResult $Shape 'FillPattern'
    if ($null -ne $fillPattern -and $fillPattern -ne 0) {
        $script:totals.visible_fills++
        try { Add-Count $script:dist.fill_color ([string]$Shape.CellsU('FillForegnd').FormulaU) } catch {}
    }

    try { foreach ($child in @($Shape.Shapes)) { Visit-Shape $child $PageName } } catch {}
}

$visio = New-Object -ComObject Visio.Application
$visio.Visible = $false
$doc = $null
try {
    $doc = $visio.Documents.Open($resolvedPath)
    foreach ($page in @($doc.Pages)) {
        $width = [double]$page.PageSheet.CellsU('PageWidth').ResultIU
        $height = [double]$page.PageSheet.CellsU('PageHeight').ResultIU
        $pages += [ordered]@{
            name             = [string]$page.Name
            width_cm         = [math]::Round($width * 2.54, 3)
            height_cm        = [math]::Round($height * 2.54, 3)
            top_level_shapes = [int]$page.Shapes.Count
        }
        foreach ($shape in @($page.Shapes)) { Visit-Shape $shape ([string]$page.Name) }
    }
}
finally {
    if ($null -ne $doc) { $doc.Close() }
    $visio.Quit()
    if ($null -ne $doc) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc) }
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($visio)
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
}

if ($requireNoMediaEffective -and $media.Count -gt 0) {
    $warnings += "Expected no embedded media, found $($media.Count)."
}
if ($null -ne $ExpectedPageWidthCm) {
    foreach ($page in $pages) {
        if ([math]::Abs(([double]$page.width_cm) - $ExpectedPageWidthCm.Value) -gt 0.01) {
            $warnings += "Page '$($page.name)' width is $($page.width_cm) cm; expected $($ExpectedPageWidthCm.Value) cm."
        }
    }
}
if ($null -ne $ExpectedLineWeightPt) {
    $mismatch = 0
    foreach ($entry in $dist.line_weight_pt.GetEnumerator()) {
        if ([math]::Abs(([double]$entry.Key) - $ExpectedLineWeightPt.Value) -gt 0.001) {
            $mismatch += [int]$entry.Value
        }
    }
    if ($mismatch -gt 0) {
        $warnings += "$mismatch visible strokes do not use the expected $($ExpectedLineWeightPt.Value) pt weight."
    }
}
if ($null -ne $ExpectedArrowType) {
    $mismatch = 0
    foreach ($key in @('begin_arrow', 'end_arrow')) {
        foreach ($entry in $dist[$key].GetEnumerator()) {
            $arrow = [int]$entry.Key
            if ($arrow -ne 0 -and $arrow -ne $ExpectedArrowType.Value) {
                $mismatch += [int]$entry.Value
            }
        }
    }
    if ($mismatch -gt 0) {
        $warnings += "$mismatch nonzero arrow endpoints do not use expected Visio arrow type $($ExpectedArrowType.Value)."
    }
}
if ($AllowedFontSizePt.Count -gt 0) {
    $mismatch = 0
    foreach ($entry in $dist.character_size_pt.GetEnumerator()) {
        $size = [double]$entry.Key
        $allowed = @($AllowedFontSizePt | Where-Object { [math]::Abs($_ - $size) -le 0.001 }).Count -gt 0
        if (-not $allowed) { $mismatch += [int]$entry.Value }
    }
    if ($mismatch -gt 0) {
        $warnings += "$mismatch character rows use sizes outside the allowed set: $($AllowedFontSizePt -join ', ') pt."
    }
}

$report = [ordered]@{
    file = $resolvedPath
    profile = [ordered]@{ name = $profileName; notes = $profileNotes }
    expectations = [ordered]@{
        page_width_cm = $ExpectedPageWidthCm
        line_weight_pt = $ExpectedLineWeightPt
        arrow_type = $ExpectedArrowType
        allowed_font_sizes_pt = $AllowedFontSizePt
        require_no_media = $requireNoMediaEffective
    }
    pages = $pages
    totals = $totals
    distributions = $dist
    unicode = $unicode
    media = $media
    warnings = $warnings
}
$json = $report | ConvertTo-Json -Depth 10
$json
if ($OutputPath) {
    [IO.File]::WriteAllText($OutputPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}
