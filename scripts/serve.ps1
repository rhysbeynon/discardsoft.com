# Minimal static file server for the Discardsoft site.
# Uses raw TcpListener so it runs without admin rights or URL ACLs.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\serve.ps1 [-Port 8080]

param([int]$Port = 8080)

$root = Split-Path -Parent $PSScriptRoot
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".json" = "application/json"
  ".svg"  = "image/svg+xml"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".gif"  = "image/gif"
  ".webp" = "image/webp"
  ".ico"  = "image/x-icon"
  ".woff" = "font/woff"
  ".woff2" = "font/woff2"
  ".mp4"  = "video/mp4"
  ".txt"  = "text/plain; charset=utf-8"
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)

    $requestLine = $reader.ReadLine()
    while (($line = $reader.ReadLine()) -and $line -ne "") { }  # drain headers
    if (-not $requestLine) { continue }

    $path = [Uri]::UnescapeDataString($requestLine.Split(' ')[1].Split('?')[0])
    if ($path.EndsWith('/')) { $path = $path + 'index.html' }

    $full = [System.IO.Path]::GetFullPath((Join-Path $root ($path.TrimStart('/') -replace '/', '\')))

    if ($full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $full -PathType Leaf)) {
      $body = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full).ToLower()
      $type = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
      $status = "200 OK"
    } else {
      $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
      $type = "text/plain"
      $status = "404 Not Found"
    }

    $header = "HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $($body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($hb, 0, $hb.Length)
    $stream.Write($body, 0, $body.Length)
    $stream.Flush()
  } catch {
    # ignore per-request errors; keep the server alive
  } finally {
    $client.Close()
  }
}
