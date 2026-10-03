Add-Type -AssemblyName System.Drawing

$source = [System.Drawing.Bitmap]::new((Resolve-Path 'images/logo.jpg').ProviderPath)
$width = $source.Width
$height = $source.Height
$removed = [bool[,]]::new($height, $width)
$queue = [System.Collections.Generic.Queue[int]]::new()

function Test-WoodPixel([int]$x, [int]$y) {
  $pixel = $source.GetPixel($x, $y)
  return ($pixel.GetHue() -le 30 -and $pixel.GetSaturation() -ge 0.20 -and $pixel.GetBrightness() -le 0.70)
}

function Add-WoodPixel([int]$x, [int]$y) {
  if (-not $removed[$y, $x] -and (Test-WoodPixel $x $y)) {
    $removed[$y, $x] = $true
    $queue.Enqueue(($y * $width) + $x)
  }
}

for ($x = 0; $x -lt $width; $x++) {
  Add-WoodPixel $x 0
  Add-WoodPixel $x ($height - 1)
}
for ($y = 1; $y -lt ($height - 1); $y++) {
  Add-WoodPixel 0 $y
  Add-WoodPixel ($width - 1) $y
}

while ($queue.Count -gt 0) {
  $index = $queue.Dequeue()
  $x = $index % $width
  $y = [int][Math]::Floor($index / $width)
  for ($dy = -1; $dy -le 1; $dy++) {
    for ($dx = -1; $dx -le 1; $dx++) {
      if ($dx -eq 0 -and $dy -eq 0) { continue }
      $nextX = $x + $dx
      $nextY = $y + $dy
      if ($nextX -ge 0 -and $nextY -ge 0 -and $nextX -lt $width -and $nextY -lt $height) {
        Add-WoodPixel $nextX $nextY
      }
    }
  }
}

$output = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$transparentPixels = 0
for ($y = 0; $y -lt $height; $y++) {
  for ($x = 0; $x -lt $width; $x++) {
    if ($removed[$y, $x]) {
      $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
      $transparentPixels++
    } else {
      $output.SetPixel($x, $y, $source.GetPixel($x, $y))
    }
  }
}

$output.Save((Join-Path (Get-Location) 'images/logo-transparent.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$alphaPixels = 0
for ($y = 0; $y -lt $height; $y++) {
  for ($x = 0; $x -lt $width; $x++) {
    if ($output.GetPixel($x, $y).A -lt 255) { $alphaPixels++ }
  }
}
Write-Output ('PNG {0}x{1}; transparent pixels={2}; alpha pixels={3}; corner alpha={4}' -f $width, $height, $transparentPixels, $alphaPixels, $output.GetPixel(0, 0).A)
$output.Dispose()
$source.Dispose()
