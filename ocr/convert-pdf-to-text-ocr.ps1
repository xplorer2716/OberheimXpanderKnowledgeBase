<#
.SYNOPSIS
    Converts one or more PDFs to text file(s) via OCR (Tesseract).

.DESCRIPTION
    Tesseract cannot read PDFs: every page is first rasterised to a PNG image
    through the native Windows API (Windows.Data.Pdf), then handed to Tesseract.
    No dependency beyond Tesseract itself (no Poppler, no Ghostscript, no
    ImageMagick, no Python). Runs on Windows 10 / 11.
    Run .\setup-ocr-dependencies.ps1 once beforehand to install everything.

    -Path accepts:
      - a PDF file       -> converts that single file;
      - a directory      -> converts every *.pdf found, recursively.

    OUTPUT QUALITY
    Tesseract is asked for hOCR output rather than plain text: hOCR carries the
    confidence of every word, the font height of every line and the paragraph
    segmentation. That enables two treatments which are impossible with .txt
    output:

      1. NOISE FILTERING (-MinConfidence): on an old scan, Tesseract happily
         "reads" separator rules, frames and figures, and emits lines of
         gibberish ("~ ~~ -* oF >", "hl fh 2 hat j h j e"). Such lines are
         rejected on three cumulative criteria (mean confidence, ratio of
         alphanumeric characters, presence of at least one real word).

      2. STRUCTURE RECOVERY (-Structure): the font height of each line, taken
         relative to the page median, identifies headings (rendered as Markdown
         #, ##, ###); lines belonging to the same paragraph are merged back
         together (with hyphenation re-joined) instead of being split at
         arbitrary points.

    An optional image cleaning pre-pass (-CleanImages) removes the very source
    of the noise before OCR: deskew, Sauvola adaptive binarisation, erasure of
    rules/frames and of non-textual components (figures, halftones, specks).

    PARALLELISM
    Tesseract's own multithreading (OpenMP, driven by OMP_THREAD_LIMIT) scales
    poorly - roughly 1.2x whatever the core count - and upstream recommends
    pinning it to one thread as soon as several instances run side by side.
    So the work is parallelised at the page level instead: pages are rasterised
    serially (the WinRT PDF API is not thread-safe), then cleaned by a C#
    Parallel.For, then OCRed by a pool of -Threads concurrent tesseract
    processes, each pinned to a single OpenMP thread. That scales close to
    linearly with the core count.

.PARAMETER Path
    Path to a PDF file, or a directory containing PDFs.

.PARAMETER OutputPath
    Output text file. Ignored in directory mode (each PDF produces a .txt
    next to it). Default: same name as the PDF, with a .txt extension.
    Use a .md extension if you want to exploit the Markdown headings.

.PARAMETER Language
    Tesseract language(s) (e.g. 'fra', 'eng', 'fra+eng'). Default: 'fra'.

.PARAMETER Dpi
    Rasterisation resolution. Higher = better OCR but slower.
    Default: 300. On an old scan set in fine serif, 400 brings a clear gain.

.PARAMETER MinConfidence
    Minimum mean confidence (0-100) for an OCR line to be kept. Default: 65.
    Set to 0 to disable filtering entirely (raw behaviour).

.PARAMETER Structure
    Rebuilds headings and paragraphs from the hOCR (Markdown output).
    On by default; -Structure:$false emits one OCR line per output line.

.PARAMETER FigurePageThreshold
    Minimum percentage of confident words (confidence >= 70) on a page for it to
    count as text. Below that the page is declared a "figure" and its content is
    not written out (avoids whole pages of gibberish). Default: 15.
    Set to 0 to never discard a page.

.PARAMETER CleanImages
    Enables the image cleaning pre-pass before OCR (deskew, Sauvola
    binarisation, removal of rules and non-textual blobs). Noticeably slower
    (~1 s/page) but it is the only treatment that eliminates the noise at its
    source rather than filtering it out afterwards.

.PARAMETER Threads
    Number of pages OCRed concurrently (one tesseract process per page).
    Default: logical cores / 3 (integer division), a conservative default
    that leaves headroom for other work on the machine; raise it explicitly
    (e.g. -Threads <cores - 1>) once you know the machine can take it. Set to
    1 for a strictly serial run (useful when diagnosing a failure). Beyond
    the physical core count the gain flattens while memory use keeps
    climbing (~150-300 MB per concurrent tesseract process at 400 dpi).
    Image cleaning (-CleanImages) is separately capped at cores/3 pages
    concurrently (never above this value): it runs in-process via GDI+,
    which has its own, much lower resource ceiling than spawning OCR child
    processes does.

.PARAMETER KeepImages
    Keeps the intermediate PNG images (and .hocr files) instead of deleting
    them. Useful for tuning the -CleanImages thresholds.

.PARAMETER IncludeSourceName
    Adds a line at the top of the text file giving the name of the source PDF
    the OCR was run on (traceability: lets e.g. an AI know the original file
    and re-run a targeted OCR if a detail seems missing).
    On by default; use -IncludeSourceName:$false to disable it.

.EXAMPLE
    .\convert-pdf-to-text-ocr.ps1 -Path .\test\test.pdf

.EXAMPLE
    .\convert-pdf-to-text-ocr.ps1 -Path .\manuals

.EXAMPLE
    # Old scan, maximum quality:
    .\convert-pdf-to-text-ocr.ps1 -Path manuel.pdf -Language eng -Dpi 400 -CleanImages -OutputPath manuel.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Alias('PdfPath')]
    [string]$Path,

    [string]$OutputPath,

    [string]$Language = 'fra',

    [ValidateRange(72, 1200)]
    [int]$Dpi = 300,

    [ValidateRange(0, 100)]
    [int]$MinConfidence = 65,

    [bool]$Structure = $true,

    [ValidateRange(0, 100)]
    [int]$FigurePageThreshold = 15,

    [switch]$CleanImages,

    [ValidateRange(1, 64)]
    [int]$Threads = [math]::Max(1, [int]([Environment]::ProcessorCount / 3)),

    [switch]$KeepImages,

    [bool]$IncludeSourceName = $true
)

$ErrorActionPreference = 'Stop'

# --- Preliminary checks ----------------------------------------------------
$tessCmd = Get-Command tesseract -ErrorAction SilentlyContinue
if (-not $tessCmd) {
    throw "Tesseract was not found in PATH. Run .\setup-ocr-dependencies.ps1 then try again."
}
# Full path, because the OCR pool uses Start-Process, which does not resolve
# a bare command name the way the call operator does.
$script:TesseractExe = $tessCmd.Source

$item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
if (-not $item) { throw "Path not found: $Path" }

# Build the list of PDFs to process (single file, or recursive directory scan)
$isDirectory = $item.PSIsContainer
if ($isDirectory) {
    $pdfFiles = @(Get-ChildItem -LiteralPath $item.FullName -Filter *.pdf -File -Recurse |
        Sort-Object FullName)
    if ($pdfFiles.Count -eq 0) { Write-Host "No PDF found in: $($item.FullName)"; exit 0 }
    if ($OutputPath) { Write-Warning "-OutputPath is ignored in directory mode." }
}
else {
    if ($item.Extension -ne '.pdf') { Write-Warning "File does not have a .pdf extension: $($item.Name)" }
    $pdfFiles = @($item)
}

# Check that the requested language(s) are installed.
# (--list-langs may write to stderr: neutralise EAP for the duration of the call)
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$installed = & tesseract --list-langs 2>$null | Select-Object -Skip 1
$ErrorActionPreference = $prevEap

# Locate the tessdata directory so we can inspect the models actually in use
$tessData = $env:TESSDATA_PREFIX
if (-not $tessData) { $tessData = Join-Path (Split-Path $tessCmd.Source -Parent) 'tessdata' }
if (-not (Test-Path -LiteralPath (Join-Path $tessData '*.traineddata'))) {
    $alt = Join-Path $tessData 'tessdata'
    if (Test-Path -LiteralPath (Join-Path $alt '*.traineddata')) { $tessData = $alt }
}

foreach ($lang in ($Language -split '\+')) {
    if ($installed -notcontains $lang) {
        Write-Warning "Tesseract language '$lang' is missing. Available languages: $($installed -join ', ')"
        continue
    }
    # The 'fast'/legacy model (~1-4 MB) is markedly less accurate than 'best'
    # (~12-15 MB) on old scans: it is often THE cause of a noisy transcription.
    $td = Join-Path $tessData "$lang.traineddata"
    if (Test-Path -LiteralPath $td) {
        $mb = [math]::Round((Get-Item -LiteralPath $td).Length / 1MB, 1)
        if ($mb -lt 6) {
            Write-Warning ("Model '$lang' = $mb MB -> this is the 'fast'/legacy model. " +
                "Run .\setup-ocr-dependencies.ps1 -Language $lang to install the 'best' model: " +
                "the accuracy gain is substantial on an old scan.")
        }
    }
}

# --- Load the WinRT APIs (once) --------------------------------------------
Write-Host "Loading the Windows PDF API..." -ForegroundColor DarkGray
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime]                   | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]                     | Out-Null
[Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

$rtExt = [System.WindowsRuntimeSystemExtensions]
$asTaskOp = ($rtExt.GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
$asTaskAct = ($rtExt.GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]

function Wait-Op($op, $type) {
    $t = $asTaskOp.MakeGenericMethod($type).Invoke($null, @($op))
    $t.Wait(-1) | Out-Null
    $t.Result
}
function Wait-Act($act) {
    $t = $asTaskAct.Invoke($null, @($act))
    $t.Wait(-1) | Out-Null
}

$utf8 = New-Object System.Text.UTF8Encoding($false)  # no BOM

# --- Image cleaning pre-pass (inline C#, compiled on demand) ----------------
# Written in C# rather than PowerShell: we walk 8 to 15 million pixels per page,
# which is far out of reach for an interpreted script.
if ($CleanImages -and -not ([System.Management.Automation.PSTypeName]'OcrClean').Type) {
    Write-Host "Compiling the image filter..." -ForegroundColor DarkGray
    Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

public static class OcrClean
{
    // Runs ProcessBatch on a background thread so the PowerShell caller can
    // poll progress (via the *-clean.png files appearing on disk) instead of
    // blocking on this call. Kept in C# rather than wrapped from PowerShell
    // with Task.Run + a scriptblock: a scriptblock needs a runspace bound to
    // whatever thread runs it, which a raw ThreadPool thread does not have.
    public static Task<string[]> ProcessBatchAsync(string[] inPaths, string[] outPaths, double dpi, int threads)
    {
        return Task.Run(delegate { return ProcessBatch(inPaths, outPaths, dpi, threads); });
    }

    // Cleans a whole batch of pages, one page per worker thread. Every buffer
    // Process() allocates is local, and GDI+ tolerates concurrent Bitmaps on
    // distinct files, so pages are embarrassingly parallel.
    // A page that throws yields "ERR|<message>" instead of aborting the batch.
    public static string[] ProcessBatch(string[] inPaths, string[] outPaths, double dpi, int threads)
    {
        string[] res = new string[inPaths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = Math.Max(1, threads);
        List<int> failed = new List<int>();
        object failedLock = new object();
        Parallel.For(0, inPaths.Length, po, delegate(int i)
        {
            try { res[i] = Process(inPaths[i], outPaths[i], dpi); }
            catch (Exception) { lock (failedLock) { failed.Add(i); } }
        });
        // GDI+ (System.Drawing) throws spurious "Insufficient memory" /
        // "Parameter is not valid" errors under heavy concurrent Bitmap use
        // rather than genuine resource exhaustion - on a long manual at a
        // high thread count this can hit a double-digit page count. Retrying
        // serially, once the rest of the batch is done and no longer
        // contending for the same GDI+ resources, recovers most of them
        // before falling back to the raw image.
        foreach (int i in failed)
        {
            try { res[i] = Process(inPaths[i], outPaths[i], dpi); }
            catch (Exception ex) { res[i] = "ERR|" + ex.Message; }
        }
        return res;
    }

    // Returns "angle|removedBlobs"
    public static string Process(string inPath, string outPath, double dpi)
    {
        int W = 0, H = 0;
        byte[] gray;
        double angle = 0.0;

        using (Bitmap src = new Bitmap(inPath))
        {
            gray = ToGray(src, out W, out H);
            angle = EstimateSkew(gray, W, H);
            if (Math.Abs(angle) >= 0.15)
            {
                using (Bitmap rot = Rotate(src, -angle))
                {
                    gray = ToGray(rot, out W, out H);
                }
            }
            else { angle = 0.0; }
        }

        bool[] ink = Sauvola(gray, W, H, 0.34);
        RemoveLongRuns(ink, W, H, 0.05, 0.05);
        int removed = RemoveBlobs(ink, W, H);
        WritePng(ink, W, H, outPath, dpi);
        return string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0:F2}|{1}", angle, removed);
    }

    // ---- Acquisition ------------------------------------------------------
    static byte[] ToGray(Bitmap bmp, out int W, out int H)
    {
        W = bmp.Width; H = bmp.Height;
        byte[] g = new byte[W * H];
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            byte[] row = new byte[bd.Stride];
            for (int y = 0; y < H; y++)
            {
                Marshal.Copy((IntPtr)(bd.Scan0.ToInt64() + (long)y * bd.Stride), row, 0, bd.Stride);
                int b = y * W;
                for (int x = 0; x < W; x++)
                {
                    int o = x * 4;
                    g[b + x] = (byte)((row[o + 2] * 299 + row[o + 1] * 587 + row[o] * 114) / 1000);
                }
            }
        }
        finally { bmp.UnlockBits(bd); }
        return g;
    }

    static Bitmap Rotate(Bitmap src, double deg)
    {
        Bitmap dst = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        dst.SetResolution(src.HorizontalResolution, src.VerticalResolution);
        using (Graphics g = Graphics.FromImage(dst))
        {
            g.Clear(Color.White);
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            g.TranslateTransform(src.Width / 2f, src.Height / 2f);
            g.RotateTransform((float)deg);
            g.TranslateTransform(-src.Width / 2f, -src.Height / 2f);
            g.DrawImage(src, 0, 0);
        }
        return dst;
    }

    // ---- Deskew: maximise the variance of the projection profile ----------
    // A page whose text lines are horizontal produces a spiky row-ink
    // histogram; a tilted one produces a flat histogram. We shear over
    // -2..+2 degrees and keep the angle with the spikiest profile.
    static double EstimateSkew(byte[] gray, int W, int H)
    {
        int f = 4;
        int dw = W / f, dh = H / f;
        if (dw < 60 || dh < 60) return 0.0;

        byte[] small = new byte[dw * dh];
        for (int y = 0; y < dh; y++)
            for (int x = 0; x < dw; x++)
                small[y * dw + x] = gray[(y * f) * W + (x * f)];

        int th = Otsu(small);
        bool[] ink = new bool[dw * dh];
        for (int i = 0; i < small.Length; i++) ink[i] = small[i] < th;

        int pad = (int)(dw * Math.Tan(2.5 * Math.PI / 180.0)) + 2;
        int[] hist = new int[dh + 2 * pad + 2];
        double best = -1.0, bestA = 0.0;

        for (int step = -20; step <= 20; step++)
        {
            double a = step * 0.1;
            Array.Clear(hist, 0, hist.Length);
            double t = Math.Tan(a * Math.PI / 180.0);
            for (int y = 0; y < dh; y++)
            {
                int rb = y * dw;
                for (int x = 0; x < dw; x++)
                {
                    if (!ink[rb + x]) continue;
                    int r = y + pad - (int)(x * t);
                    if (r >= 0 && r < hist.Length) hist[r]++;
                }
            }
            double s = 0.0;
            for (int i = 0; i < hist.Length; i++) { double v = hist[i]; s += v * v; }
            if (s > best) { best = s; bestA = a; }
        }
        return bestA;
    }

    static int Otsu(byte[] d)
    {
        int[] h = new int[256];
        for (int i = 0; i < d.Length; i++) h[d[i]]++;
        int total = d.Length;
        double sum = 0.0;
        for (int i = 0; i < 256; i++) sum += (double)i * h[i];
        double sumB = 0.0; int wB = 0; double best = -1.0; int th = 128;
        for (int i = 0; i < 256; i++)
        {
            wB += h[i]; if (wB == 0) continue;
            int wF = total - wB; if (wF == 0) break;
            sumB += (double)i * h[i];
            double mB = sumB / wB, mF = (sum - sumB) / wF;
            double v = (double)wB * wF * (mB - mF) * (mB - mF);
            if (v > best) { best = v; th = i; }
        }
        return th;
    }

    // ---- Sauvola adaptive binarisation ------------------------------------
    // Better than a global Otsu on a scan with uneven background, and above
    // all: inside a low-variance area (flat grey, figure halftone) the local
    // threshold drops, which naturally erases those areas instead of letting
    // the OCR engine "read" them.
    static bool[] Sauvola(byte[] g, int W, int H, double k)
    {
        int w1 = W + 1;
        int win = Math.Max(15, W / 40); if ((win & 1) == 0) win++;
        int r = win / 2;
        bool[] ink = new bool[W * H];

        // Worked in horizontal bands rather than over the whole page: a full
        // page integral image costs 16 bytes per pixel (~240 MB at 400 dpi on
        // A4), which would rule out cleaning several pages in parallel. A band
        // of 256 rows plus the window margin costs ~20 MB and is also far
        // friendlier to the CPU cache.
        int band = Math.Max(256, 4 * r);

        for (int by = 0; by < H; by += band)
        {
            int bEnd = Math.Min(H, by + band);
            int sy = Math.Max(0, by - r);        // extra rows the window reaches into
            int ey = Math.Min(H, bEnd + r);
            int rows = ey - sy;

            // Integral images of the values and of their squares -> O(1) local
            // mean and standard deviation whatever the window size.
            long[] I1 = new long[(long)w1 * (rows + 1)];
            double[] I2 = new double[(long)w1 * (rows + 1)];
            for (int y = 1; y <= rows; y++)
            {
                long rs = 0; double rs2 = 0.0;
                int gb = (sy + y - 1) * W, ib = y * w1, pb = (y - 1) * w1;
                for (int x = 1; x <= W; x++)
                {
                    int v = g[gb + x - 1];
                    rs += v; rs2 += (double)v * v;
                    I1[ib + x] = I1[pb + x] + rs;
                    I2[ib + x] = I2[pb + x] + rs2;
                }
            }

            for (int y = by; y < bEnd; y++)
            {
                int y0 = Math.Max(sy, y - r), y1 = Math.Min(ey - 1, y + r);
                int a0 = (y0 - sy) * w1, a1 = (y1 - sy + 1) * w1;
                int gb = y * W;
                for (int x = 0; x < W; x++)
                {
                    int x0 = Math.Max(0, x - r), x1 = Math.Min(W - 1, x + r);
                    int n = (x1 - x0 + 1) * (y1 - y0 + 1);
                    long s = I1[a1 + x1 + 1] - I1[a0 + x1 + 1] - I1[a1 + x0] + I1[a0 + x0];
                    double s2 = I2[a1 + x1 + 1] - I2[a0 + x1 + 1] - I2[a1 + x0] + I2[a0 + x0];
                    double m = (double)s / n;
                    double var = s2 / n - m * m; if (var < 0.0) var = 0.0;
                    double sd = Math.Sqrt(var);
                    double t = m * (1.0 + k * (sd / 128.0 - 1.0));
                    ink[gb + x] = g[gb + x] < t;
                }
            }
        }
        return ink;
    }

    // ---- Erase rules, frames and staves -----------------------------------
    // A rule is a very long continuous run of ink; no glyph produces a
    // horizontal run spanning 5% of the page width, nor a vertical one
    // spanning 5% of its height. Equivalent to a morphological opening with a
    // 1-D structuring element, but a single pass and no extra buffer.
    static void RemoveLongRuns(bool[] ink, int W, int H, double hFrac, double vFrac)
    {
        int hLen = Math.Max(20, (int)(W * hFrac));
        int vLen = Math.Max(20, (int)(H * vFrac));

        for (int y = 0; y < H; y++)
        {
            int b = y * W, start = -1;
            for (int x = 0; x <= W; x++)
            {
                bool on = (x < W) && ink[b + x];
                if (on) { if (start < 0) start = x; }
                else if (start >= 0)
                {
                    if (x - start >= hLen)
                        for (int i = start; i < x; i++) ink[b + i] = false;
                    start = -1;
                }
            }
        }
        for (int x = 0; x < W; x++)
        {
            int start = -1;
            for (int y = 0; y <= H; y++)
            {
                bool on = (y < H) && ink[y * W + x];
                if (on) { if (start < 0) start = y; }
                else if (start >= 0)
                {
                    if (y - start >= vLen)
                        for (int i = start; i < y; i++) ink[i * W + x] = false;
                    start = -1;
                }
            }
        }
    }

    // ---- Remove non-textual connected components ---------------------------
    // 8-connected labelling, then a geometric verdict per component. The
    // thresholds are deliberately conservative: a wrongly deleted glyph costs
    // more than a surviving speck, which the confidence filter catches later.
    static int RemoveBlobs(bool[] ink, int W, int H)
    {
        int[] lab = new int[W * H];
        List<int> minx = new List<int>(); List<int> maxx = new List<int>();
        List<int> miny = new List<int>(); List<int> maxy = new List<int>();
        List<int> area = new List<int>();
        minx.Add(0); maxx.Add(0); miny.Add(0); maxy.Add(0); area.Add(0); // index 0 unused

        Stack<int> st = new Stack<int>();
        int cur = 0;

        for (int i = 0; i < ink.Length; i++)
        {
            if (!ink[i] || lab[i] != 0) continue;
            cur++;
            int x0 = i % W, x1 = x0, y0 = i / W, y1 = y0, a = 0;
            lab[i] = cur; st.Push(i);
            while (st.Count > 0)
            {
                int p = st.Pop(); a++;
                int px = p % W, py = p / W;
                if (px < x0) x0 = px; if (px > x1) x1 = px;
                if (py < y0) y0 = py; if (py > y1) y1 = py;
                for (int dy = -1; dy <= 1; dy++)
                {
                    int ny = py + dy; if (ny < 0 || ny >= H) continue;
                    int nb = ny * W;
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int nx = px + dx; if (nx < 0 || nx >= W) continue;
                        int q = nb + nx;
                        if (ink[q] && lab[q] == 0) { lab[q] = cur; st.Push(q); }
                    }
                }
            }
            minx.Add(x0); maxx.Add(x1); miny.Add(y0); maxy.Add(y1); area.Add(a);
        }

        bool[] bad = new bool[cur + 1];
        int removed = 0;
        for (int c = 1; c <= cur; c++)
        {
            int bw = maxx[c] - minx[c] + 1;
            int bh = maxy[c] - miny[c] + 1;
            int a = area[c];
            int box = bw * bh;
            double dens = (double)a / box;
            bool kill = false;

            if (a < 6) kill = true;                              // dust / salt noise
            else if (bh > H * 0.06) kill = true;                 // too tall to be a glyph
            else if (bw > W * 0.5) kill = true;                  // leftover rule
            else if (box > 2000 && dens < 0.12) kill = true;     // line art / dotted graphic
            else if (box > 3000 && dens > 0.92) kill = true;     // solid black area

            if (kill) { bad[c] = true; removed++; }
        }
        for (int i = 0; i < ink.Length; i++) if (ink[i] && bad[lab[i]]) ink[i] = false;
        return removed;
    }

    static void WritePng(bool[] ink, int W, int H, string path, double dpi)
    {
        using (Bitmap bmp = new Bitmap(W, H, PixelFormat.Format32bppArgb))
        {
            bmp.SetResolution((float)dpi, (float)dpi);
            BitmapData bd = bmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            try
            {
                byte[] row = new byte[bd.Stride];
                for (int y = 0; y < H; y++)
                {
                    int b = y * W;
                    for (int x = 0; x < W; x++)
                    {
                        byte v = ink[b + x] ? (byte)0 : (byte)255;
                        int o = x * 4;
                        row[o] = v; row[o + 1] = v; row[o + 2] = v; row[o + 3] = 255;
                    }
                    Marshal.Copy(row, 0, (IntPtr)(bd.Scan0.ToInt64() + (long)y * bd.Stride), bd.Stride);
                }
            }
            finally { bmp.UnlockBits(bd); }
            bmp.Save(path, ImageFormat.Png);
        }
    }
}
'@
}

# --- hOCR parsing -----------------------------------------------------------
# A single regex sweep, in document order, over three tokens:
#   - paragraph opening  <p class='ocr_par'
#   - line opening       <span class='ocr_line' ... x_size N
#   - word + confidence  <span class='ocrx_word' ... x_wconf N>text</span>
# (Tesseract's hOCR carries a DOCTYPE with an external DTD, which an XML parser
#  would try to download. The regex sweep is both safer and faster here.)
$script:HocrRx = [regex]::new(
    "(?s)<span\s+class='ocrx_word'[^>]*?x_wconf\s+([\d.]+)[^>]*>(.*?)</span>" +
    "|<p\s+class='ocr_par'" +
    "|<span\s+class='ocr_(?:line|header|textfloat|caption)'[^>]*>")
$script:XSizeRx = [regex]::new("x_size\s+([\d.]+)")
$script:TagRx   = [regex]::new("<[^>]+>")   # strips the <strong>/<em> Tesseract wraps bold/italic words in

function Convert-HtmlEntity([string]$s) {
    # &amp; must be substituted last, otherwise "&amp;lt;" would decode twice
    $s.Replace('&lt;', '<').Replace('&gt;', '>').Replace('&quot;', '"').
       Replace('&#39;', "'").Replace('&apos;', "'").Replace('&amp;', '&')
}

function Get-Median([double[]]$values) {
    if (-not $values -or $values.Count -eq 0) { return 0.0 }
    $s = @($values | Sort-Object)
    $n = $s.Count
    if ($n % 2 -eq 1) { return [double]$s[[int](($n - 1) / 2)] }
    return ([double]$s[($n / 2) - 1] + [double]$s[$n / 2]) / 2.0
}

function ConvertFrom-Hocr {
    param([string]$HocrPath, [int]$MinConf, [bool]$WithStructure)

    $hocr = [System.IO.File]::ReadAllText($HocrPath, $utf8)

    # --- 1) Extract lines and words ----------------------------------------
    $lines = New-Object System.Collections.ArrayList
    $parIdx = 0
    $curLine = $null
    $totalWords = 0
    $solidWords = 0

    foreach ($m in $script:HocrRx.Matches($hocr)) {
        if ($m.Groups[1].Success) {
            # --- a word ---
            if ($null -eq $curLine) { continue }
            $raw = $script:TagRx.Replace($m.Groups[2].Value, '')
            $txt = (Convert-HtmlEntity $raw).Trim()
            if (-not $txt) { continue }
            $conf = [double]::Parse($m.Groups[1].Value, [cultureinfo]::InvariantCulture)
            $totalWords++
            if ($conf -ge 70 -and $txt -match '\p{L}{3,}') { $solidWords++ }
            [void]$curLine.Words.Add([pscustomobject]@{ Text = $txt; Conf = $conf })
        }
        elseif ($m.Value[1] -eq 'p') {
            # --- new paragraph ('<p' vs '<span') ---
            $parIdx++
        }
        else {
            # --- new line ---
            $xs = 0.0
            $xm = $script:XSizeRx.Match($m.Value)
            if ($xm.Success) { $xs = [double]::Parse($xm.Groups[1].Value, [cultureinfo]::InvariantCulture) }
            $curLine = [pscustomobject]@{
                Par   = $parIdx
                XSize = $xs
                Words = (New-Object System.Collections.ArrayList)
                Text  = ''
            }
            [void]$lines.Add($curLine)
        }
    }

    # --- 2) Noise filtering -------------------------------------------------
    # A line produced by a rule or a figure fails at least one of these three
    # tests; a genuine text line passes all three.
    $kept = New-Object System.Collections.ArrayList
    $dropped = 0
    $droppedWords = 0
    foreach ($ln in $lines) {
        if ($ln.Words.Count -eq 0) { continue }
        $txt = (($ln.Words | ForEach-Object { $_.Text }) -join ' ').Trim()
        if (-not $txt) { continue }

        if ($MinConf -le 0) { $ln.Text = $txt; [void]$kept.Add($ln); continue }

        $avg = ($ln.Words | Measure-Object -Property Conf -Average).Average
        $alnum = ([regex]::Matches($txt, '[\p{L}\p{Nd}]')).Count / [math]::Max(1, $txt.Length)
        $solid = @($ln.Words | Where-Object { $_.Conf -ge 70 -and $_.Text -match '\p{L}{3,}' }).Count

        if ($avg -lt $MinConf -or $alnum -lt 0.55 -or $solid -lt 1) { $dropped++; continue }

        # The line as a whole is genuine text, but PSM 3 sometimes glues an
        # isolated diagram fragment onto an otherwise clean line of prose
        # (e.g. "U0 oo CL for continuous cyclical modulations..."). Drop just
        # those low-confidence short tokens instead of the whole line:
        #   - conf < 35            : garbage regardless of shape.
        #   - conf < 60 and len<=2 : a real short word (a, to, of, in, 15...)
        #     is common enough to have dictionary support and usually scores
        #     well above 60; an isolated 1-2 char token that doesn't is more
        #     likely a stray glyph. Digits are exempt (page/version numbers).
        $goodWords = @($ln.Words | Where-Object {
                $_.Conf -ge 35 -and
                -not ($_.Conf -lt 60 -and $_.Text.Length -le 2 -and $_.Text -notmatch '^\p{Nd}+$')
            })
        if ($goodWords.Count -eq 0) { $dropped++; continue }
        $droppedWords += ($ln.Words.Count - $goodWords.Count)

        $ln.Text = ($goodWords | ForEach-Object { $_.Text }) -join ' '
        [void]$kept.Add($ln)
    }

    $result = [pscustomobject]@{
        Text         = ''
        Kept         = $kept.Count
        Dropped      = $dropped
        DroppedWords = $droppedWords
        Headings     = 0
        TotalWords   = $totalWords
        SolidWords   = $solidWords
        IsFigure     = $false
    }

    # --- 3) Purely graphic page? -------------------------------------------
    $ratio = 0.0
    if ($totalWords -gt 0) { $ratio = 100.0 * $solidWords / $totalWords }
    if ($kept.Count -eq 0 -or ($FigurePageThreshold -gt 0 -and $totalWords -ge 5 -and $ratio -lt $FigurePageThreshold)) {
        $result.IsFigure = $true
        return $result
    }

    # --- 4) Rendering -------------------------------------------------------
    $sb = New-Object System.Text.StringBuilder

    if (-not $WithStructure) {
        $prevPar = -1
        foreach ($ln in $kept) {
            if ($prevPar -ne -1 -and $ln.Par -ne $prevPar) { [void]$sb.AppendLine() }
            [void]$sb.AppendLine($ln.Text)
            $prevPar = $ln.Par
        }
        $result.Text = $sb.ToString().TrimEnd()
        return $result
    }

    # Reference font height = median of the page. The ratio to that median is
    # DPI-independent, unlike the raw x_size in pixels.
    $sizes = @($kept | Where-Object { $_.XSize -gt 0 } | ForEach-Object { [double]$_.XSize })
    $median = Get-Median $sizes
    # Too few lines -> the median is unreliable, skip heading detection.
    $canDetectHeadings = ($sizes.Count -ge 4 -and $median -gt 0)

    $par = New-Object System.Text.StringBuilder
    $headings = 0

    # Flush the pending paragraph to the output
    $flush = {
        if ($par.Length -gt 0) {
            [void]$sb.AppendLine($par.ToString().Trim())
            [void]$sb.AppendLine()
            [void]$par.Clear()
        }
    }

    $prevPar = -1
    foreach ($ln in $kept) {
        $txt = $ln.Text
        $level = 0
        if ($canDetectHeadings -and $ln.XSize -gt 0) {
            $r = $ln.XSize / $median
            if ($r -ge 1.60) { $level = 1 }
            elseif ($r -ge 1.25) { $level = 2 }
            # Barely larger: only a short all-caps line qualifies as a subheading
            elseif ($r -ge 1.10 -and $txt.Length -lt 45 -and $txt -cmatch '^\P{Ll}*$') { $level = 3 }
        }

        if ($level -gt 0) {
            & $flush
            [void]$sb.AppendLine(('#' * $level) + ' ' + $txt)
            [void]$sb.AppendLine()
            $headings++
            $prevPar = -1
            continue
        }

        if ($prevPar -ne -1 -and $ln.Par -ne $prevPar) { & $flush }

        if ($par.Length -eq 0) {
            [void]$par.Append($txt)
        }
        elseif ($par[$par.Length - 1] -eq '-' -and $txt -cmatch '^\p{Ll}') {
            # End-of-line hyphenation: drop the hyphen and glue the word back
            $par.Length = $par.Length - 1
            [void]$par.Append($txt)
        }
        else {
            [void]$par.Append(' ').Append($txt)
        }
        $prevPar = $ln.Par
    }
    & $flush

    $result.Text = $sb.ToString().TrimEnd()
    $result.Headings = $headings
    return $result
}

# --- OCR pool ---------------------------------------------------------------
# Runs one tesseract process per page, at most -Threads at a time.
#
# Why processes rather than Tesseract's own threads: its OpenMP parallelism
# (OMP_THREAD_LIMIT) scales badly, around 1.2x whatever the core count, and
# several instances each spawning their own OpenMP team would oversubscribe the
# CPU and end up slower. Pinning every child to one thread and getting the
# parallelism from the process count instead scales nearly linearly.
#
# Returns the list of page numbers that failed.
function Invoke-TesseractPool {
    param([string[]]$Inputs, [string[]]$Bases, [int]$MaxConcurrent, [string]$Activity)

    $n = $Inputs.Count
    $failed = New-Object System.Collections.ArrayList
    $running = New-Object System.Collections.ArrayList
    $next = 0
    $done = 0

    $prevOmp = $env:OMP_THREAD_LIMIT
    $env:OMP_THREAD_LIMIT = '1'
    try {
        while ($done -lt $n) {
            # Top the pool back up
            while ($next -lt $n -and $running.Count -lt $MaxConcurrent) {
                # Quoted: Start-Process joins the array with spaces and does no
                # quoting of its own, so a path with a space would split.
                #   --oem 1  LSTM engine only (clearly better than the default)
                #   --psm 3  automatic segmentation (handles multi-column layouts)
                #   --dpi    real resolution -> avoids a bad internal estimate
                #   preserve_interword_spaces  keeps column alignment
                #   tessedit_do_invert=0       skips a useless second pass
                #   hocr     output format: confidences, font sizes, paragraphs
                $tessArgs = @(
                    ('"' + $Inputs[$next] + '"'), ('"' + $Bases[$next] + '"'),
                    '-l', $Language, '--oem', '1', '--psm', '3', '--dpi', "$Dpi",
                    '-c', 'preserve_interword_spaces=1', '-c', 'tessedit_do_invert=0', 'hocr')
                $proc = Start-Process -FilePath $script:TesseractExe -ArgumentList $tessArgs `
                    -NoNewWindow -PassThru `
                    -RedirectStandardError  ($Bases[$next] + '.err') `
                    -RedirectStandardOutput ($Bases[$next] + '.out')
                # Force .NET to open a real handle to the process right away.
                # Without this, .ExitCode read after a short-lived process has
                # already exited is unreliable (the PID can be recycled first)
                # and silently comes back as $null - which "-ne 0" then treats
                # as a mismatch, so EVERY page would be reported as failed even
                # on success. Touching .Handle here is the standard fix.
                [void]$proc.Handle
                [void]$running.Add([pscustomobject]@{ Proc = $proc; Index = $next })
                $next++
            }

            Start-Sleep -Milliseconds 50

            # Reap whatever finished (backwards: we remove as we go)
            for ($j = $running.Count - 1; $j -ge 0; $j--) {
                $r = $running[$j]
                if (-not $r.Proc.HasExited) { continue }
                if ($r.Proc.ExitCode -ne 0) { [void]$failed.Add($r.Index + 1) }
                $r.Proc.Dispose()
                $running.RemoveAt($j)
                $done++
            }
            Write-Progress -Activity $Activity -Status "Page $done / $n" -PercentComplete ([int](100 * $done / $n))
        }
    }
    finally {
        $env:OMP_THREAD_LIMIT = $prevOmp
        Write-Progress -Activity $Activity -Completed
    }
    # Leading comma: without it PowerShell enumerates the list on the way out,
    # so an empty one would come back as $null instead of an empty collection.
    return , $failed
}

# Reads a text file, returning '' rather than $null when it is missing or empty
# (Get-Content -Raw yields $null on an empty file, and $null.Trim() throws).
function Get-FileTextSafe([string]$FilePath) {
    if (-not (Test-Path -LiteralPath $FilePath)) { return '' }
    $t = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $t) { return '' }
    return $t.Trim()
}

# --- Conversion of a single PDF --------------------------------------------
function Convert-Pdf {
    param([string]$PdfFull, [string]$OutFull, [int]$FileIndex, [int]$FileTotal)

    $name = [System.IO.Path]::GetFileName($PdfFull)
    $prefix = if ($FileTotal -gt 1) { "[$FileIndex/$FileTotal] " } else { "" }
    Write-Host ""
    Write-Host "$prefix$name" -ForegroundColor Cyan

    $sf  = Wait-Op ([Windows.Storage.StorageFile]::GetFileFromPathAsync($PdfFull)) ([Windows.Storage.StorageFile])
    $doc = Wait-Op ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($sf))        ([Windows.Data.Pdf.PdfDocument])
    $pageCount = [int]$doc.PageCount

    $mode = @()
    if ($MinConfidence -gt 0) { $mode += "confidence filter >=$MinConfidence" } else { $mode += "raw" }
    if ($Structure)   { $mode += "structure" }
    if ($CleanImages) { $mode += "image cleaning" }
    Write-Host "  Pages: $pageCount   |   Language: $Language   |   DPI: $Dpi   |   $Threads thread(s)   |   $($mode -join ' + ')" -ForegroundColor DarkGray

    # -KeepImages is meant for inspecting/tuning the output, so it belongs
    # next to the PDF where it's easy to find rather than buried under the
    # system temp folder (which is also cleaned up automatically by Windows,
    # unlike this one).
    if ($KeepImages) {
        $tmpDir = Join-Path ([System.IO.Path]::GetDirectoryName($PdfFull)) `
            ([System.IO.Path]::GetFileNameWithoutExtension($PdfFull) + '_ocr-temp')
    }
    else {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pdfocr_" + [System.IO.Path]::GetRandomFileName())
    }
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
    $sb = New-Object System.Text.StringBuilder

    # Traceability header: name of the source PDF the OCR was run on.
    if ($IncludeSourceName) {
        [void]$sb.AppendLine("Source file (OCR): $name")
        [void]$sb.AppendLine()
    }

    $sumDropped = 0; $sumDroppedWords = 0; $sumHeadings = 0; $sumFigures = 0

    try {
        $bases      = New-Object string[] $pageCount
        $rawImgs    = New-Object string[] $pageCount
        $ocrInputs  = New-Object string[] $pageCount
        $cleanInfos = New-Object string[] $pageCount

        # === Phase 1: rasterise, serially =====================================
        # The WinRT PDF API is not thread-safe, and this stage is cheap anyway
        # (~0.1 s/page) - the CPU cost sits in the two stages that follow.
        $swAll = [System.Diagnostics.Stopwatch]::StartNew()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        for ($i = 0; $i -lt $pageCount; $i++) {
            $pageNo = $i + 1
            Write-Progress -Activity "1/3 Rasterisation : $name" `
                -Status "Page $pageNo / $pageCount" -PercentComplete ([int](100 * $i / $pageCount))

            $page = $doc.GetPage($i)
            $opts = [Windows.Data.Pdf.PdfPageRenderOptions]::new()
            $opts.DestinationWidth  = [uint32]([math]::Round($page.Size.Width  * $Dpi / 96.0))
            $opts.DestinationHeight = [uint32]([math]::Round($page.Size.Height * $Dpi / 96.0))

            $stream = [Windows.Storage.Streams.InMemoryRandomAccessStream]::new()
            Wait-Act ($page.RenderToStreamAsync($stream, $opts))
            $page.Dispose()

            $imgPath = Join-Path $tmpDir ("page-{0:D4}.png" -f $pageNo)
            $netIn = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($stream.GetInputStreamAt(0))
            $fs = [System.IO.File]::Create($imgPath)
            $netIn.CopyTo($fs)
            $fs.Close(); $netIn.Close(); $stream.Dispose()

            $rawImgs[$i]   = $imgPath
            $ocrInputs[$i] = $imgPath
            $bases[$i]     = Join-Path $tmpDir ("page-{0:D4}" -f $pageNo)
        }
        Write-Progress -Activity "1/3 Rasterisation : $name" -Completed
        Write-Host ("  1/3 Rasterisation  : {0} page(s) in {1:N0} s" -f $pageCount, $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray

        # === Phase 2: clean, in parallel inside C# ============================
        # A page that fails cleaning falls back to its raw image rather than
        # being lost.
        if ($CleanImages) {
            $sw.Restart()
            $cleanPaths = New-Object string[] $pageCount
            for ($i = 0; $i -lt $pageCount; $i++) {
                $cleanPaths[$i] = Join-Path $tmpDir ("page-{0:D4}-clean.png" -f ($i + 1))
            }
            # Cleaning runs in-process (System.Drawing/GDI+ Bitmaps), unlike
            # OCR which is one child process per page: GDI+ has its own,
            # separate resource limits and gets unreliable well before
            # -Threads worth of CPU cores would justify it (~150 MB per
            # concurrent page at 400 dpi besides). Capped at cores/3
            # (same conservative default as -Threads), never above whatever
            # -Threads was explicitly set to.
            $cleanThreads = [math]::Min($Threads, [math]::Max(1, [int]([Environment]::ProcessorCount / 3)))
            # ProcessBatch blocks until every page is done, so it runs on a
            # background task while this thread polls progress from disk:
            # WritePng() writes the *-clean.png file as the last step of each
            # page, so counting them approximates how many pages are done.
            $cleanTask = [OcrClean]::ProcessBatchAsync($rawImgs, $cleanPaths, [double]$Dpi, $cleanThreads)
            while (-not $cleanTask.IsCompleted) {
                $doneCount = (Get-ChildItem -LiteralPath $tmpDir -Filter '*-clean.png' -File -ErrorAction SilentlyContinue).Count
                Write-Progress -Activity "2/3 Image cleaning : $name" `
                    -Status "$doneCount / $pageCount page(s), $cleanThreads thread(s)" `
                    -PercentComplete ([int](100 * $doneCount / $pageCount))
                Start-Sleep -Milliseconds 100
            }
            $results = $cleanTask.GetAwaiter().GetResult()
            for ($i = 0; $i -lt $pageCount; $i++) {
                $parts = $results[$i] -split '\|'
                if ($parts[0] -eq 'ERR') {
                    Write-Warning "Cleaning failed on page $($i + 1) ($($parts[1])) - using the raw image instead."
                    $cleanInfos[$i] = ' | cleaning failed'
                }
                else {
                    $ocrInputs[$i]  = $cleanPaths[$i]
                    $cleanInfos[$i] = " | skew $($parts[0])deg, $($parts[1]) blobs"
                }
            }
            Write-Progress -Activity "2/3 Image cleaning : $name" -Completed
            Write-Host ("  2/3 Cleaning       : {0:N0} s ({1} thread(s))" -f $sw.Elapsed.TotalSeconds, $cleanThreads) -ForegroundColor DarkGray
        }

        # === Phase 3: OCR, one process per page, -Threads at a time ==========
        $sw.Restart()
        $failedPages = Invoke-TesseractPool -Inputs $ocrInputs -Bases $bases `
            -MaxConcurrent $Threads -Activity "3/3 OCR : $name"
        Write-Host ("  3/3 OCR            : {0:N0} s ({1} concurrent process(es))" -f $sw.Elapsed.TotalSeconds, $Threads) -ForegroundColor DarkGray
        if ($failedPages.Count -gt 0) {
            # Surface what tesseract actually said on the first failure rather
            # than just its exit code.
            $detail = Get-FileTextSafe ($bases[$failedPages[0] - 1] + '.err')
            if (-not $detail) { $detail = '(no message on stderr)' }
            throw "Tesseract failed on $($failedPages.Count) page(s): $($failedPages -join ', '). Page $($failedPages[0]): $detail"
        }

        # === Phase 4: parse the hOCR and assemble, serially ==================
        for ($i = 0; $i -lt $pageCount; $i++) {
            $pageNo = $i + 1
            $res = ConvertFrom-Hocr -HocrPath ($bases[$i] + '.hocr') -MinConf $MinConfidence -WithStructure $Structure
            $sumDropped      += $res.Dropped
            $sumDroppedWords += $res.DroppedWords
            $sumHeadings     += $res.Headings

            if ($res.IsFigure) {
                $sumFigures++
                [void]$sb.AppendLine("===== Page $pageNo / $pageCount (figure or blank page - not OCRed) =====")
                [void]$sb.AppendLine()
                Write-Host ("    [{0,3}/{1}] figure / blank page skipped{2}" -f $pageNo, $pageCount, $cleanInfos[$i]) -ForegroundColor DarkYellow
                continue
            }

            [void]$sb.AppendLine("===== Page $pageNo / $pageCount =====")
            [void]$sb.AppendLine($res.Text)
            [void]$sb.AppendLine()

            $wordNote = if ($res.DroppedWords -gt 0) { ", $($res.DroppedWords) word(s) cleaned" } else { '' }
            Write-Host ("    [{0,3}/{1}] OK: {2} char., {3} heading(s), {4} line(s) rejected{5}{6}" -f `
                    $pageNo, $pageCount, $res.Text.Length, $res.Headings, $res.Dropped, $wordNote, $cleanInfos[$i]) -ForegroundColor Green
        }

        [System.IO.File]::WriteAllText($OutFull, $sb.ToString(), $utf8)
        Write-Host ("  Total: {0:N0} s" -f $swAll.Elapsed.TotalSeconds) -ForegroundColor DarkGray
        Write-Host ("  Summary: {0} noisy line(s) rejected, {1} isolated word(s) cleaned, {2} heading(s) detected, {3} figure page(s) skipped." -f `
                $sumDropped, $sumDroppedWords, $sumHeadings, $sumFigures) -ForegroundColor DarkGray
        Write-Host "  -> $OutFull" -ForegroundColor Green
    }
    finally {
        if ($KeepImages) { Write-Host "  Intermediate files kept: $tmpDir" -ForegroundColor DarkGray }
        else { Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# --- Main loop --------------------------------------------------------------
$total = $pdfFiles.Count
if ($total -gt 1) { Write-Host "$total PDF file(s) to convert." -ForegroundColor Cyan }

$ok = 0; $ko = 0
for ($f = 0; $f -lt $total; $f++) {
    $pdf = $pdfFiles[$f]
    if ($isDirectory -or -not $OutputPath) {
        $out = [System.IO.Path]::ChangeExtension($pdf.FullName, '.txt')
    }
    elseif ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $out = [System.IO.Path]::GetFullPath($OutputPath)
    }
    else {
        # A relative -OutputPath is resolved against PowerShell's own location
        # ($PWD / Get-Location) - the same base Get-Item uses to resolve
        # -Path. Plain GetFullPath($OutputPath) would instead consult .NET's
        # own current-directory tracking, which is not guaranteed to follow
        # Set-Location/cd in every host, so an "identical" relative
        # -OutputPath could silently resolve against a stale base and land
        # in a different folder than -Path did.
        $out = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $OutputPath))
    }

    # Fail fast on a missing output directory rather than discovering it only
    # after the OCR work (rasterisation + cleaning + Tesseract) has run.
    $outDir = [System.IO.Path]::GetDirectoryName($out)
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    try {
        Convert-Pdf -PdfFull $pdf.FullName -OutFull $out -FileIndex ($f + 1) -FileTotal $total
        $ok++
    }
    catch {
        $ko++
        Write-Warning "Failed on $($pdf.Name): $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Done: $ok succeeded, $ko failed." -ForegroundColor $(if ($ko) { 'Yellow' } else { 'Green' })
