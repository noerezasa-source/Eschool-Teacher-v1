$headers = @{
    "Authorization" = "Bearer 4965|EQvowcs1zfoxtSlRb0qgO3sODkj2bfAQsbinMvr775970cd5"
    "Accept" = "application/json"
    "school-code" = "SCH20260002"
    "role" = "teacher"
    "view_type" = "teacher"
    "X-Requested-With" = "XMLHttpRequest"
}

$url = "https://devapisekolah.eschool.ac.id/api/leaves"

$testCases = @(
    @{ label = "Full"; value = "Full" },
    @{ label = "full (lowercase)"; value = "full" },
    @{ label = "0 (numeric)"; value = "0" },
    @{ label = "1 (numeric)"; value = "1" },
    @{ label = "half_day"; value = "half_day" },
    @{ label = "Sehari Penuh"; value = "Sehari Penuh" }
)

foreach ($test in $testCases) {
    Write-Host "=== Test: $($test.label) ==="
    try {
        $form = @{
            "reason" = "test cuti"
            "leave_details[0][type]" = $test.value
            "leave_details[0][date]" = "2026-05-20"
        }
        $r = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Form $form -ErrorAction Stop
        Write-Host "SUCCESS ($($r.StatusCode)): $($r.Content)"
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $content = ""
        try {
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $content = $sr.ReadToEnd()
            $sr.Close()
        } catch {
            $content = $_.Exception.Message
        }
        Write-Host "FAIL ($statusCode): $content"
    }
    Write-Host ""
}
