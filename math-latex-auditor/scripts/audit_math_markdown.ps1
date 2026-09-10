[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$AllowUntagged,
    [switch]$Json
)

$resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
$text = [IO.File]::ReadAllText($resolved, [Text.Encoding]::UTF8)
$lines = [IO.File]::ReadAllLines($resolved, [Text.Encoding]::UTF8)
$issues = [Collections.Generic.List[object]]::new()

function Add-Issue([string]$Severity, [int]$Line, [string]$Rule, [string]$Message) {
    $issues.Add([pscustomobject]@{ severity = $Severity; line = $Line; rule = $Rule; message = $Message })
}

$inFence = $false
$inFrontmatter = $false
$frontmatterClosed = $false
$inDisplay = $false
$displayStart = 0
$displayLines = [Collections.Generic.List[string]]::new()
$tags = [Collections.Generic.List[object]]::new()
$activeLines = [Collections.Generic.List[object]]::new()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $lineNo = $i + 1
    $line = $lines[$i]
    if ($i -eq 0 -and $line.Trim() -eq '---') { $inFrontmatter = $true; continue }
    if ($inFrontmatter) {
        if ($line.Trim() -eq '---') { $inFrontmatter = $false; $frontmatterClosed = $true }
        continue
    }
    if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
    if ($inFence) { continue }

    $activeLines.Add([pscustomobject]@{ number = $lineNo; text = $line })
    if ($line.Trim() -eq '$$') {
        if (-not $inDisplay) {
            $inDisplay = $true
            $displayStart = $lineNo
            $displayLines.Clear()
        } else {
            $block = $displayLines -join "`n"
            $blockTags = [regex]::Matches($block, '\\tag\{([^{}]+)\}')
            if (-not $AllowUntagged -and $blockTags.Count -ne 1) { Add-Issue 'ERROR' $displayStart 'display-tag' "Display block must contain exactly one \\tag{...}; found $($blockTags.Count)." }
            if ($AllowUntagged -and $blockTags.Count -gt 1) { Add-Issue 'ERROR' $displayStart 'display-tag' "Display block contains multiple tags; found $($blockTags.Count)." }
            foreach ($match in $blockTags) { $tags.Add([pscustomobject]@{ value = $match.Groups[1].Value; line = $displayStart }) }
            $inDisplay = $false
        }
        continue
    }
    if ($inDisplay) { $displayLines.Add($line) }
}

if ($inFence) { Add-Issue 'ERROR' $lines.Count 'code-fence' 'Unclosed fenced code block.' }
if ($inFrontmatter -and -not $frontmatterClosed) { Add-Issue 'ERROR' 1 'frontmatter' 'Unclosed YAML frontmatter.' }
if ($inDisplay) { Add-Issue 'ERROR' $displayStart 'display-delimiter' 'Unclosed display-math block.' }

foreach ($entry in $activeLines) {
    $line = $entry.text
    $lineNo = $entry.number
    if ($line -match '\\\(|\\\)') { Add-Issue 'ERROR' $lineNo 'inline-delimiter' 'Use $...$ instead of \(...\).' }
    if ($line.Trim() -ne '$$') {
        $withoutEscaped = $line -replace '\\\$', ''
        $singleDollarCount = ([regex]::Matches(($withoutEscaped -replace '\$\$', ''), '(?<!\$)\$(?!\$)')).Count
        if (($singleDollarCount % 2) -ne 0) { Add-Issue 'ERROR' $lineNo 'inline-delimiter' 'Odd number of inline $ delimiters on this line.' }
    }
    if ($line -match '\^_') { Add-Issue 'ERROR' $lineNo 'superscript-subscript' 'Malformed ^_ sequence.' }
    if ($line -match '_\{\\mathrm\{[^{}]+\}\}') { Add-Issue 'WARNING' $lineNo 'textual-subscript' 'Descriptive subscripts should normally use \\text{...}, not \\mathrm{...}.' }
    if ($line -match '_\{[A-Za-z][A-Za-z][A-Za-z0-9 .,/+-]*\}' -and $line -notmatch '_\{\\text\{') { Add-Issue 'WARNING' $lineNo 'textual-subscript' 'Possible descriptive subscript is not wrapped in \\text{...}; confirm that it is not a mathematical index.' }
    if ($line -match '(?<!\\mathrm\{)j\s*(\\omega|2\\pi|[0-9])') { Add-Issue 'WARNING' $lineNo 'imaginary-unit' 'Possible imaginary unit should be written as \\mathrm{j}.' }
}

$activeText = ($activeLines.text -join "`n")
if ([regex]::Matches($activeText, '\{').Count -ne [regex]::Matches($activeText, '\}').Count) { Add-Issue 'ERROR' 0 'brace-balance' 'Opening and closing brace counts differ outside protected regions.' }
foreach ($env in @('bmatrix', 'pmatrix', 'matrix', 'aligned', 'cases')) {
    $begins = [regex]::Matches($activeText, "\\begin\{$env\}").Count
    $ends = [regex]::Matches($activeText, "\\end\{$env\}").Count
    if ($begins -ne $ends) { Add-Issue 'ERROR' 0 'environment-balance' "Environment $env is unbalanced: begin=$begins, end=$ends." }
}
$leftCount = [regex]::Matches($activeText, '\\left(?:\.|\s|[\(\[\{\|])').Count
$rightCount = [regex]::Matches($activeText, '\\right(?:\.|\s|[\)\]\}\|])').Count
if ($leftCount -ne $rightCount) { Add-Issue 'ERROR' 0 'delimiter-balance' "\\left and \\right counts differ: left=$leftCount, right=$rightCount." }

foreach ($group in ($tags | Group-Object value | Where-Object Count -gt 1)) {
    $firstLine = ($group.Group | Select-Object -First 1).line
    Add-Issue 'ERROR' $firstLine 'duplicate-tag' "Duplicate equation tag '$($group.Name)'."
}
if ($tags.Count -gt 1) {
    $parsed = foreach ($tag in $tags) {
        if ($tag.value -match '^(.*?)(\d+)$') { [pscustomobject]@{ prefix = $matches[1]; number = [int]$matches[2]; line = $tag.line; value = $tag.value } }
    }
    foreach ($group in ($parsed | Group-Object prefix)) {
        $numbers = @($group.Group.number)
        for ($i = 1; $i -lt $numbers.Count; $i++) {
            if ($numbers[$i] -ne $numbers[$i - 1] + 1) { Add-Issue 'WARNING' $group.Group[$i].line 'tag-sequence' "Equation-tag sequence is not continuous near '$($group.Group[$i].value)'."; break }
        }
    }
}

for ($i = 0; $i -lt $text.Length; $i++) {
    $code = [int][char]$text[$i]
    if (($code -lt 32 -and $code -notin 9, 10, 13) -or $code -eq 0xFFFD) { Add-Issue 'ERROR' 0 'encoding' ('Control or replacement character detected at character offset {0}.' -f $i); break }
}

$errors = @($issues | Where-Object severity -eq 'ERROR').Count
$warnings = @($issues | Where-Object severity -eq 'WARNING').Count
$status = if ($errors -gt 0) { 'NEEDS FIX' } elseif ($warnings -gt 0) { 'PASS WITH WARNINGS' } else { 'PASS' }
$result = [pscustomobject]@{ path = $resolved; status = $status; errors = $errors; warnings = $warnings; display_blocks = [int]([regex]::Matches($activeText, '(?m)^\s*\$\$\s*$').Count / 2); tags = $tags.Count; issues = $issues }

if ($Json) { $result | ConvertTo-Json -Depth 5 } else {
    Write-Output "[$status] $resolved"
    Write-Output "display_blocks=$($result.display_blocks), tags=$($result.tags), errors=$errors, warnings=$warnings"
    foreach ($issue in $issues) { Write-Output ("{0} line {1} [{2}] {3}" -f $issue.severity, $issue.line, $issue.rule, $issue.message) }
}
if ($errors -gt 0) { exit 1 }
