Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outDir = Join-Path $root 'DailyQuests\Assets.xcassets\AppIcon.appiconset'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

function New-Point([double]$x, [double]$y) {
    return New-Object System.Drawing.PointF([float]$x, [float]$y)
}

function New-ShieldPath([double]$S, [double]$left, [double]$right, [double]$top, [double]$side, [double]$tip) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.StartFigure()
    $path.AddLine((New-Point ($left * $S) ($top * $S)), (New-Point ($right * $S) ($top * $S)))
    $path.AddLine((New-Point ($right * $S) ($top * $S)), (New-Point ($right * $S) ($side * $S)))
    $path.AddBezier(
        (New-Point ($right * $S) ($side * $S)),
        (New-Point ($right * $S) (($side + 0.15) * $S)),
        (New-Point (($right - 0.16) * $S) (($tip - 0.12) * $S)),
        (New-Point (0.5 * $S) ($tip * $S))
    )
    $path.AddBezier(
        (New-Point (0.5 * $S) ($tip * $S)),
        (New-Point ((0.16 + $left) * $S) (($tip - 0.12) * $S)),
        (New-Point ($left * $S) (($side + 0.15) * $S)),
        (New-Point ($left * $S) ($side * $S))
    )
    $path.CloseFigure()
    return $path
}

function New-StarPath([double]$S) {
    $cx = 0.5 * $S
    $cy = 0.478 * $S
    $v = 0.152 * $S
    $h = 0.122 * $S
    $i = 0.030 * $S
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $points = @(
        (New-Point $cx ($cy - $v)),
        (New-Point ($cx + $i) ($cy - $i)),
        (New-Point ($cx + $h) $cy),
        (New-Point ($cx + $i) ($cy + $i)),
        (New-Point $cx ($cy + $v)),
        (New-Point ($cx - $i) ($cy + $i)),
        (New-Point ($cx - $h) $cy),
        (New-Point ($cx - $i) ($cy - $i))
    )
    $path.AddPolygon([System.Drawing.PointF[]]$points)
    return $path
}

function New-Master([int]$S) {
    $bmp = New-Object System.Drawing.Bitmap($S, $S, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#120E1E'))

    # background gradient
    $rect = New-Object System.Drawing.Rectangle(0, 0, $S, $S)
    $bgTop = [System.Drawing.ColorTranslator]::FromHtml('#1A1330')
    $bgBottom = [System.Drawing.ColorTranslator]::FromHtml('#0A0810')
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $bgTop, $bgBottom, 90.0)
    $g.FillRectangle($bgBrush, $rect)
    $bgBrush.Dispose()

    # soft violet glow top
    $glowRect = New-Object System.Drawing.RectangleF(([float](0.1 * $S)), ([float](-0.35 * $S)), ([float](0.8 * $S)), ([float](0.9 * $S)))
    $glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glowPath.AddEllipse($glowRect)
    $glowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($glowPath)
    $glowBrush.CenterColor = [System.Drawing.Color]::FromArgb(90, 92, 63, 190)
    $glowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 92, 63, 190))
    $g.FillPath($glowBrush, $glowPath)
    $glowBrush.Dispose()
    $glowPath.Dispose()

    # shield ring
    $outer = New-ShieldPath $S 0.185 0.815 0.165 0.495 0.858
    $ringRect = New-Object System.Drawing.RectangleF(0, 0, $S, $S)
    $goldLight = [System.Drawing.ColorTranslator]::FromHtml('#FBF0CF')
    $goldMid = [System.Drawing.ColorTranslator]::FromHtml('#E8C987')
    $goldDeep = [System.Drawing.ColorTranslator]::FromHtml('#B08A43')
    $goldBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($ringRect, $goldLight, $goldDeep, 90.0)
    $blend = New-Object System.Drawing.Drawing2D.ColorBlend
    $blend.Colors = @($goldLight, $goldMid, $goldDeep)
    $blend.Positions = @(0.0, 0.45, 1.0)
    $goldBrush.InterpolationColors = $blend
    $g.FillPath($goldBrush, $outer)

    $inner = New-ShieldPath $S 0.245 0.755 0.225 0.505 0.775
    $innerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0D0A16'))
    $g.FillPath($innerBrush, $inner)
    $innerBrush.Dispose()

    # star
    $star = New-StarPath $S
    $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#F3E8CF'))
    $g.FillPath($starBrush, $star)
    $starBrush.Dispose()

    # subtle inner outline
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 251, 240, 207), ([float](0.006 * $S)))
    $g.DrawPath($pen, $outer)
    $pen.Dispose()

    $g.Dispose()
    $outer.Dispose()
    $inner.Dispose()
    $star.Dispose()
    return $bmp
}

function Save-Resized([System.Drawing.Bitmap]$master, [int]$size, [string]$path) {
    $target = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $tg = [System.Drawing.Graphics]::FromImage($target)
    $tg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $tg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $tg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $tg.DrawImage($master, (New-Object System.Drawing.Rectangle(0, 0, $size, $size)))
    $tg.Dispose()
    $target.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $target.Dispose()
}

$masterSize = 2048
$master = New-Master $masterSize

$sizes = @(40, 58, 60, 80, 87, 120, 180, 1024)
foreach ($size in $sizes) {
    $file = Join-Path $outDir ("icon-" + $size + ".png")
    Save-Resized $master $size $file
    Write-Output ("icon-" + $size + ".png")
    if ($size -eq 120) {
        Copy-Item $file (Join-Path $outDir 'icon-120b.png') -Force
        Write-Output 'icon-120b.png'
    }
}

$master.Dispose()
Write-Output 'done'
