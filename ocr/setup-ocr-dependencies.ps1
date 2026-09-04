<#
.SYNOPSIS
    Installe et verifie tout ce dont convert-pdf-to-text-ocr.ps1 a besoin.

.DESCRIPTION
    Run this once before using convert-pdf-to-text-ocr.ps1. It performs six
    checks, in order, and reports a pass/fail summary at the end:

      1. HOST          Windows 10/11 (build 10240+) and PowerShell 5.1+.
                       Required by the WinRT PDF rasteriser.
      2. WINRT PDF     Windows.Data.Pdf can be loaded and used. This is the
                       component that turns PDF pages into PNG images; there is
                       no fallback, so a failure here is blocking.
      3. SYSTEM.DRAWING  Needed only by -CleanImages (the inline C# image
                       filter). A failure downgrades that option, nothing else.
      4. TESSERACT     Present in PATH, or found in a known install location.
                       With -InstallTesseract it is installed through winget.
      5. LANGUAGE MODELS  This is the step that actually matters for output
                       quality. Tesseract ships three model families:
                         tessdata_fast   ~1-4 MB   quick, visibly less accurate
                         tessdata        ~4-5 MB   legacy + LSTM, the default
                         tessdata_best   ~13-23 MB slowest, clearly the best
                       On a degraded scan (old manual, halftone, fine serif) the
                       gap between 'fast' and 'best' is not marginal: it is the
                       difference between a usable transcription and one full of
                       garbage. This script installs 'best' for the requested
                       languages, backing up whatever was there before.
      6. SMOKE TEST    Renders a synthetic image, OCRs it, and checks the text
                       comes back. Proves the whole chain works end to end.

    The script never deletes an existing model: it renames it to
    <lang>.traineddata.bak-<timestamp> before writing the new one, and restores
    it if the download turns out to be corrupt.

.PARAMETER Language
    Langue(s) a installer, separees par '+' comme pour Tesseract.
    Defaut : 'eng+fra'.

.PARAMETER TesseractPath
    Repertoire d'installation de Tesseract, si l'auto-detection echoue
    (ex. 'C:\dev\tools\tesseract').

.PARAMETER InstallTesseract
    Installe Tesseract via winget s'il est absent. Sans ce commutateur, le
    script se contente de signaler l'absence et d'indiquer quoi faire.

.PARAMETER Force
    Retelecharge les modeles meme si un modele 'best' est deja en place.

.PARAMETER SkipModels
    Ne touche pas aux modeles de langue (verifications seules).

.PARAMETER SkipTest
    Saute le test de bout en bout (etape 6).

.EXAMPLE
    .\setup-ocr-dependencies.ps1

.EXAMPLE
    # Poste neuf, anglais seul, installation complete :
    .\setup-ocr-dependencies.ps1 -Language eng -InstallTesseract

.EXAMPLE
    # Verifier sans rien modifier :
    .\setup-ocr-dependencies.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Language = 'eng+fra',

    [string]$TesseractPath,

    [switch]$InstallTesseract,

    [switch]$Force,

    [switch]$SkipModels,

    [switch]$SkipTest
)

$ErrorActionPreference = 'Stop'

# Every check appends one entry here; the summary at the end reads from it.
$report = New-Object System.Collections.ArrayList
function Add-Result([string]$Step, [string]$State, [string]$Detail) {
    [void]$report.Add([pscustomobject]@{ Step = $Step; State = $State; Detail = $Detail })
    $color = 'Green'
    if ($State -eq 'ECHEC')   { $color = 'Red' }
    if ($State -eq 'ALERTE')  { $color = 'Yellow' }
    if ($State -eq 'IGNORE')  { $color = 'DarkGray' }
    Write-Host ("  [{0,-6}] {1,-22} {2}" -f $State, $Step, $Detail) -ForegroundColor $color
}

Write-Host ""
Write-Host "Verification des dependances OCR" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

# =========================================================================
# 1) Host: Windows version and PowerShell version
# =========================================================================
$osVersion = [System.Environment]::OSVersion.Version
$psVersion = $PSVersionTable.PSVersion
if ($osVersion.Major -lt 10) {
    Add-Result 'Windows' 'ECHEC' "Windows $osVersion - Windows 10 ou 11 requis (API WinRT PDF)."
}
else {
    Add-Result 'Windows' 'OK' "Windows $osVersion"
}
if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
    Add-Result 'PowerShell' 'ECHEC' "PowerShell $psVersion - 5.1 minimum requis."
}
else {
    # PowerShell 7 loads WinRT types differently and Add-Type -AssemblyName
    # System.Runtime.WindowsRuntime is unavailable there: warn rather than fail,
    # since the user may simply be probing from the wrong host.
    if ($psVersion.Major -ge 6) {
        Add-Result 'PowerShell' 'ALERTE' "PowerShell $psVersion - lancez les scripts depuis Windows PowerShell 5.1 (powershell.exe) : l'API WinRT n'est pas accessible en PS 7."
    }
    else {
        Add-Result 'PowerShell' 'OK' "PowerShell $psVersion"
    }
}

# =========================================================================
# 2) WinRT PDF rasteriser - the PDF -> PNG stage, no fallback exists
# =========================================================================
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    [Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]   | Out-Null
    Add-Result 'API PDF WinRT' 'OK' 'Windows.Data.Pdf disponible'
}
catch {
    Add-Result 'API PDF WinRT' 'ECHEC' "Windows.Data.Pdf inaccessible : $($_.Exception.Message)"
}

# =========================================================================
# 3) System.Drawing - required only by the -CleanImages pre-pass
# =========================================================================
try {
    Add-Type -AssemblyName System.Drawing
    $probe = New-Object System.Drawing.Bitmap 4, 4
    $probe.Dispose()
    Add-Result 'System.Drawing' 'OK' 'disponible (-CleanImages utilisable)'
}
catch {
    Add-Result 'System.Drawing' 'ALERTE' "indisponible : l'option -CleanImages ne fonctionnera pas ($($_.Exception.Message))"
}

# =========================================================================
# 4) Tesseract
# =========================================================================
function Find-Tesseract {
    param([string]$Hint)

    $cmd = Get-Command tesseract -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # Not in PATH: probe the usual install locations before giving up.
    $candidates = @()
    if ($Hint) { $candidates += (Join-Path $Hint 'tesseract.exe') }
    $candidates += 'C:\dev\tools\tesseract\tesseract.exe'
    $candidates += (Join-Path $env:ProgramFiles 'Tesseract-OCR\tesseract.exe')
    $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Tesseract-OCR\tesseract.exe')
    $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Tesseract-OCR\tesseract.exe')

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

$tessExe = Find-Tesseract -Hint $TesseractPath

if (-not $tessExe -and $InstallTesseract) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Add-Result 'Tesseract' 'ECHEC' "absent, et winget introuvable. Installez depuis https://github.com/UB-Mannheim/tesseract/wiki"
    }
    elseif ($PSCmdlet.ShouldProcess('UB-Mannheim.TesseractOCR', 'winget install')) {
        Write-Host "  Installation de Tesseract via winget..." -ForegroundColor DarkGray
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & winget install --id UB-Mannheim.TesseractOCR -e --accept-package-agreements --accept-source-agreements
        $ErrorActionPreference = $prevEap
        # winget updates the machine PATH, but not the PATH of this already
        # running process: re-read it so the rest of the script sees the exe.
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [Environment]::GetEnvironmentVariable('Path', 'User')
        $tessExe = Find-Tesseract -Hint $TesseractPath
    }
}

if (-not $tessExe) {
    Add-Result 'Tesseract' 'ECHEC' "introuvable. Relancez avec -InstallTesseract, ou passez -TesseractPath <dossier>."
}
else {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $verLine = (& $tessExe --version 2>&1 | Select-Object -First 1)
    $ErrorActionPreference = $prevEap
    Add-Result 'Tesseract' 'OK' "$verLine  ($tessExe)"

    # Found on disk but absent from PATH: the converter calls `tesseract`
    # bare, so offer to make that work permanently.
    if (-not (Get-Command tesseract -ErrorAction SilentlyContinue)) {
        $tessDir = Split-Path $tessExe -Parent
        if ($PSCmdlet.ShouldProcess("PATH utilisateur", "ajouter $tessDir")) {
            $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            if ($userPath -notlike "*$tessDir*") {
                [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $tessDir), 'User')
                Add-Result 'PATH' 'OK' "$tessDir ajoute au PATH utilisateur (rouvrez le terminal)"
            }
            $env:Path = $env:Path.TrimEnd(';') + ';' + $tessDir
        }
    }
}

# =========================================================================
# 5) Language models (tessdata_best)
# =========================================================================
$langs = @($Language -split '\+' | Where-Object { $_ } | ForEach-Object { $_.Trim() })

if ($SkipModels) {
    Add-Result 'Modeles' 'IGNORE' '-SkipModels'
}
elseif (-not $tessExe) {
    Add-Result 'Modeles' 'IGNORE' 'Tesseract absent'
}
else {
    # Resolve tessdata. TESSDATA_PREFIX has meant both "the tessdata folder"
    # and "its parent" across Tesseract versions, so accept either shape.
    $tessData = $env:TESSDATA_PREFIX
    if (-not $tessData) { $tessData = Join-Path (Split-Path $tessExe -Parent) 'tessdata' }
    if (-not (Test-Path -LiteralPath (Join-Path $tessData '*.traineddata'))) {
        $alt = Join-Path $tessData 'tessdata'
        if (Test-Path -LiteralPath (Join-Path $alt '*.traineddata')) { $tessData = $alt }
    }
    if (-not (Test-Path -LiteralPath $tessData)) {
        New-Item -ItemType Directory -Force -Path $tessData | Out-Null
    }
    Write-Host "  tessdata : $tessData" -ForegroundColor DarkGray

    # A 'best' model is 13-23 MB (eng 22.4, fra 13.6); 'fast' and legacy sit at
    # 1-5 MB. The size is a reliable discriminator and costs nothing to check.
    $bestMinBytes = 6MB
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $prevProgress = $ProgressPreference

    foreach ($lang in $langs) {
        $dest = Join-Path $tessData "$lang.traineddata"
        $sizeMb = 0
        if (Test-Path -LiteralPath $dest) {
            $sizeMb = [math]::Round((Get-Item -LiteralPath $dest).Length / 1MB, 1)
        }

        if ($sizeMb -ge ($bestMinBytes / 1MB) -and -not $Force) {
            Add-Result "Modele $lang" 'OK' "$sizeMb Mo - modele 'best' deja en place"
            continue
        }

        $why = 'absent'
        if ($sizeMb -gt 0) { $why = "$sizeMb Mo = modele 'fast'/legacy" }
        $url = "https://github.com/tesseract-ocr/tessdata_best/raw/main/$lang.traineddata"

        if (-not $PSCmdlet.ShouldProcess($dest, "telecharger tessdata_best/$lang ($why)")) {
            Add-Result "Modele $lang" 'IGNORE' "$why - telechargement non confirme"
            continue
        }

        # Move the old file aside rather than overwriting: if the download is
        # truncated or the URL 404s, we can put it straight back.
        $backup = $null
        if (Test-Path -LiteralPath $dest) {
            $backup = "$dest.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
            Move-Item -LiteralPath $dest -Destination $backup -Force
        }

        $tmp = "$dest.download"
        try {
            Write-Host "  Telechargement de $lang.traineddata (tessdata_best, 13-23 Mo)..." -ForegroundColor DarkGray
            $ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is ~10x faster without the bar
            Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
            $ProgressPreference = $prevProgress

            $dl = (Get-Item -LiteralPath $tmp).Length
            if ($dl -lt $bestMinBytes) {
                throw "fichier recu trop petit ($([math]::Round($dl/1MB,1)) Mo) - telechargement incomplet ou langue inexistante."
            }
            Move-Item -LiteralPath $tmp -Destination $dest -Force
            Add-Result "Modele $lang" 'OK' ("tessdata_best installe ({0} Mo)" -f [math]::Round($dl / 1MB, 1))
            if ($backup) { Write-Host "    ancien modele conserve : $backup" -ForegroundColor DarkGray }
        }
        catch {
            $ProgressPreference = $prevProgress
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            if ($backup) { Move-Item -LiteralPath $backup -Destination $dest -Force }   # rollback
            Add-Result "Modele $lang" 'ECHEC' "$($_.Exception.Message) (ancien modele restaure)"
        }
    }
}

# =========================================================================
# 6) End-to-end smoke test: synthetic image -> Tesseract -> text
# =========================================================================
if ($SkipTest) {
    Add-Result 'Test OCR' 'IGNORE' '-SkipTest'
}
elseif (-not $tessExe) {
    Add-Result 'Test OCR' 'IGNORE' 'Tesseract absent'
}
else {
    # -WhatIf:$false throughout: this is a scratch directory, not a change the
    # user is being asked to approve. Without it, -WhatIf skips the mkdir and
    # the test then fails on a missing path rather than reporting anything.
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ('ocrsetup_' + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $tmpDir -WhatIf:$false | Out-Null
    try {
        Add-Type -AssemblyName System.Drawing
        $png = Join-Path $tmpDir 'probe.png'
        $expected = 'OCR TEST 1984'

        # Black serif on white at 300 dpi: representative of what the converter
        # feeds Tesseract, and unambiguous to recognise.
        # The canvas is measured rather than hard-coded: a font size is given in
        # points, so its pixel height follows the bitmap DPI (24 pt at 300 dpi =
        # 100 px). A fixed canvas would clip the text and make the test lie.
        $font = New-Object System.Drawing.Font 'Times New Roman', 24
        $probeBmp = New-Object System.Drawing.Bitmap 1, 1
        $probeBmp.SetResolution(300, 300)
        $probeGfx = [System.Drawing.Graphics]::FromImage($probeBmp)
        $size = $probeGfx.MeasureString($expected, $font)
        $probeGfx.Dispose(); $probeBmp.Dispose()

        $margin = 40
        $bmp = New-Object System.Drawing.Bitmap ([int][math]::Ceiling($size.Width) + 2 * $margin), `
                                                ([int][math]::Ceiling($size.Height) + 2 * $margin)
        $bmp.SetResolution(300, 300)
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.Clear([System.Drawing.Color]::White)
        $gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $gfx.DrawString($expected, $font, [System.Drawing.Brushes]::Black, $margin, $margin)
        $gfx.Dispose(); $font.Dispose()
        $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()

        $outBase = Join-Path $tmpDir 'probe'
        $testLang = $langs[0]
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $tessExe $png $outBase -l $testLang --oem 1 --psm 7 --dpi 300 2>$null
        $code = $LASTEXITCODE
        $ErrorActionPreference = $prevEap

        if ($code -ne 0) {
            Add-Result 'Test OCR' 'ECHEC' "tesseract a retourne le code $code"
        }
        else {
            $got = (Get-Content -LiteralPath "$outBase.txt" -Raw).Trim()
            if ($got -replace '\s+', ' ' -eq $expected) {
                Add-Result 'Test OCR' 'OK' "'$got' (langue $testLang)"
            }
            else {
                Add-Result 'Test OCR' 'ALERTE' "attendu '$expected', obtenu '$got' - chaine fonctionnelle mais precision douteuse"
            }
        }
    }
    catch {
        Add-Result 'Test OCR' 'ECHEC' $_.Exception.Message
    }
    finally {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue -WhatIf:$false
    }
}

# =========================================================================
# Summary
# =========================================================================
$fail  = @($report | Where-Object { $_.State -eq 'ECHEC' }).Count
$warn  = @($report | Where-Object { $_.State -eq 'ALERTE' }).Count

Write-Host ""
if ($fail -gt 0) {
    Write-Host "$fail echec(s), $warn alerte(s). Corrigez les points en rouge avant de lancer l'OCR." -ForegroundColor Red
    exit 1
}
if ($warn -gt 0) {
    Write-Host "Pret, avec $warn alerte(s)." -ForegroundColor Yellow
}
else {
    Write-Host "Toutes les dependances sont en place." -ForegroundColor Green
}

Write-Host ""
Write-Host "Exemple d'utilisation :" -ForegroundColor Cyan
Write-Host "  .\convert-pdf-to-text-ocr.ps1 -Path mon.pdf -Language $($langs[0]) -Dpi 400 -CleanImages -OutputPath mon.md"
