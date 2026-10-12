[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [string]$OutputPath,
    [string]$Sheet,
    [ValidateSet('Auto', 'Portrait', 'Landscape')]
    [string]$Orientation = 'Auto',
    [ValidateSet('OnePage', 'OnePageWide', 'Existing')]
    [string]$PageMode = 'OnePage',
    [bool]$CenterHorizontally = $true,
    [bool]$CenterVertically = $true,
    [double]$MarginMm = 8,
    [string[]]$RowHeight = @(),
    [string[]]$WrapRange = @(),
    [string[]]$RequiredText = @(),
    [int]$ExpectedPages = 0,
    [string]$PreviewDir,
    [switch]$NoBackup,
    [switch]$SkipA4Normalize,
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$PathValue) {
    if ([IO.Path]::IsPathRooted($PathValue)) { return [IO.Path]::GetFullPath($PathValue) }
    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $PathValue))
}

function Get-PythonCommand {
    foreach ($candidate in @('python', 'py')) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw 'Python was not found on PATH.'
}

$inputFull = Resolve-FullPath $InputPath
if (-not (Test-Path -LiteralPath $inputFull -PathType Leaf)) { throw "Input workbook not found: $inputFull" }
if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($inputFull, '.pdf') }
$outputFull = Resolve-FullPath $OutputPath
$outputDir = Split-Path -Parent $outputFull
if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

$backupPath = $null
if ((Test-Path -LiteralPath $outputFull -PathType Leaf) -and -not $NoBackup) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = Join-Path $outputDir ("{0}_backup_{1}{2}" -f [IO.Path]::GetFileNameWithoutExtension($outputFull), $stamp, [IO.Path]::GetExtension($outputFull))
    Copy-Item -LiteralPath $outputFull -Destination $backupPath
}

$excel = $null
$workbook = $null
$worksheetName = $null
$selectedOrientation = $null
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $workbook = $excel.Workbooks.Open($inputFull, 0, $true)
    $worksheet = if ($Sheet) { $workbook.Worksheets.Item($Sheet) } else { $workbook.ActiveSheet }
    $worksheetName = $worksheet.Name

    foreach ($entry in $RowHeight) {
        if ($entry -notmatch '^\s*(\d+)\s*=\s*(\d+(?:\.\d+)?)\s*$') {
            throw "Invalid -RowHeight value '$entry'. Use ROW=POINTS, for example 4=105."
        }
        $worksheet.Rows.Item([int]$Matches[1]).RowHeight = [double]$Matches[2]
    }
    foreach ($address in $WrapRange) { $worksheet.Range($address).WrapText = $true }

    $used = $worksheet.UsedRange
    $worksheet.PageSetup.PrintArea = $used.Address()
    $worksheet.PageSetup.PaperSize = 9
    $selectedOrientation = $Orientation
    if ($selectedOrientation -eq 'Auto') {
        $selectedOrientation = if ($used.Columns.Count -ge 7) { 'Landscape' } else { 'Portrait' }
    }
    $worksheet.PageSetup.Orientation = if ($selectedOrientation -eq 'Landscape') { 2 } else { 1 }

    if ($PageMode -ne 'Existing') {
        $worksheet.PageSetup.Zoom = $false
        $worksheet.PageSetup.FitToPagesWide = 1
        $worksheet.PageSetup.FitToPagesTall = if ($PageMode -eq 'OnePage') { 1 } else { $false }
    }

    $worksheet.PageSetup.CenterHorizontally = $CenterHorizontally
    $worksheet.PageSetup.CenterVertically = $CenterVertically
    $marginInches = $MarginMm / 25.4
    $worksheet.PageSetup.LeftMargin = $excel.InchesToPoints($marginInches)
    $worksheet.PageSetup.RightMargin = $excel.InchesToPoints($marginInches)
    $worksheet.PageSetup.TopMargin = $excel.InchesToPoints($marginInches)
    $worksheet.PageSetup.BottomMargin = $excel.InchesToPoints($marginInches)
    $worksheet.ExportAsFixedFormat(0, $outputFull, 0, $true, $false)
}
finally {
    if ($workbook) { $workbook.Close($false) }
    if ($excel) { $excel.Quit() }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

if (-not (Test-Path -LiteralPath $outputFull -PathType Leaf)) { throw "Excel did not create the expected PDF: $outputFull" }

$python = $null
if (-not $SkipA4Normalize -or -not $SkipVerify) {
    $python = Get-PythonCommand
}
$skillRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $skillRoot

if (-not $SkipA4Normalize) {
    $normalizer = Join-Path $repoRoot 'pdf-a4-normalizer\scripts\normalize_pdf_a4.py'
    if (Test-Path -LiteralPath $normalizer -PathType Leaf) {
        $tempDir = Join-Path ([IO.Path]::GetTempPath()) ("excel-to-pdf-a4-{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        try {
            & $python $normalizer $outputFull --mode normalize --output-dir $tempDir --force-all --orientation preserve | Write-Verbose
            if ($LASTEXITCODE -ne 0) { throw "A4 normalizer failed with exit code $LASTEXITCODE." }
            $normalized = Join-Path $tempDir ([IO.Path]::GetFileName($outputFull))
            if (-not (Test-Path -LiteralPath $normalized -PathType Leaf)) { throw "A4 normalizer did not create: $normalized" }
            Copy-Item -LiteralPath $normalized -Destination $outputFull -Force
        }
        finally {
            if (Test-Path -LiteralPath $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force }
        }
    } else {
        Write-Warning 'Sibling pdf-a4-normalizer was not found; exported page dimensions were not normalized.'
    }
}

if (-not $SkipVerify) {
    $verifier = Join-Path $PSScriptRoot 'verify_excel_pdf.py'
    if (-not (Test-Path -LiteralPath $verifier -PathType Leaf)) { throw "Verifier not found: $verifier" }
    $verifyArgs = @($verifier, $outputFull)
    if ($ExpectedPages -gt 0) { $verifyArgs += @('--expected-pages', "$ExpectedPages") }
    foreach ($text in $RequiredText) { $verifyArgs += @('--required-text', $text) }
    if ($PreviewDir) { $verifyArgs += @('--preview-dir', (Resolve-FullPath $PreviewDir)) }
    & $python @verifyArgs
    if ($LASTEXITCODE -ne 0) { throw "PDF verification failed with exit code $LASTEXITCODE." }
}

[pscustomobject]@{
    Input = $inputFull
    Output = $outputFull
    Backup = $backupPath
    Sheet = $worksheetName
    Orientation = $selectedOrientation
    PageMode = $PageMode
}
