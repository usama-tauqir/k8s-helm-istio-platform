# Istio lab helpers. Har nayi window mein:  . ..\scripts\istio-lab.ps1
if (-not (Get-Job -State Running -ErrorAction SilentlyContinue | Where-Object Command -match "port-forward")) {
  $global:pf = Start-Job { kubectl port-forward -n istio-ingress svc/istio-ingress 18080:80 }
  Start-Sleep 8
}
function global:Count-Canary {
  $r = 1..50 | % { $p = curl.exe -s -H "Host: vote.local" http://localhost:18080/ | Out-String
    if (-not $p) {"ERROR"} elseif ($p -cmatch "Coffee") {"v2 (Tea/Coffee)"} elseif ($p -cmatch "Dogs") {"v1 (Cats/Dogs)"} else {"UNKNOWN"} }
  $r | Group-Object -NoElement | Format-Table Name,Count -AutoSize | Out-String | Write-Host
}
Write-Host "Ready: port-forward 18080 + Count-Canary"
$global:CHART = "D:\github-projects\example-voting-app\helm\voting-app"
function global:Count-Pods([string]$Cookie = "") {
  $h = @("-H", "Host: vote.local"); if ($Cookie) { $h += @("-b", "voter_id=$Cookie") }
  $r = 1..30 | % { $p = curl.exe -s @h http://localhost:18080/ | Out-String
    $v = if ($p -cmatch "Coffee") {"v2"} elseif ($p -cmatch "Dogs") {"v1"} else {"ERR"}
    $pod = if ($p -match 'container ID ([\w-]+)') { $matches[1] } else { "?" }
    "$v  $pod" }
  $r | Group-Object -NoElement | Format-Table Name,Count -AutoSize | Out-String | Write-Host
}
function global:Measure-Vote([int]$N = 20) {
  $r = 1..$N | % { $o = curl.exe -s -o NUL -w "%{http_code} %{time_total}" -H "Host: vote.local" http://localhost:18080/
    $c, $t = $o -split " "; $speed = if ([double]$t -ge 2.5) {"SLOW (~3s)"} else {"fast"}; "HTTP $c  $speed" }
  $r | Group-Object -NoElement | Format-Table Name,Count -AutoSize | Out-String | Write-Host
}
$env:Path += ";C:\istio\istio-1.30.7\bin"
function global:Fortio([string]$Args2) { Invoke-Expression "kubectl exec -n voting deploy/fortio-deploy -c fortio -- fortio load $Args2 2>&1" | Select-String "Code \d+ :" | Out-String | Write-Host }
