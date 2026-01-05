# 設定輸入與輸出檔名
$File = "AX_Duffy_1518_Byte_fixed_UDP_UniDir_Bridge_B2Y_CPU"
$inputFile = "$File.txt"
$outputFile = "$File.csv"


# 讀取檔案內容
$content = Get-Content $inputFile

# 定義儲存清單
$all_idle = @()
$cpu0_idle = @()
$cpu1_idle = @()

foreach ($line in $content) {
    # 匹配包含時間戳的行，並排除標題行
    if ($line -match "\d{2}:\d{2}:\d{2}") {
        # 將行拆分為陣列 (以空白字元拆分)
        $parts = $line -split '\s+' | Where-Object { $_ -ne "" }
        
        # 取得最後一個數值 (%idle)
        $idleValue = $parts[-1]

        # 根據第二個欄位 (CPU ID) 分類
        if ($parts[1] -eq "all") {
            $all_idle += $idleValue
        }
        elseif ($parts[1] -eq "0") {
            $cpu0_idle += $idleValue
        }
        elseif ($parts[1] -eq "1") {
            $cpu1_idle += $idleValue
        }
    }
}

# 找出最大列數，確保對齊
$maxCount = ($all_idle.Count, $cpu0_idle.Count, $cpu1_idle.Count | Measure-Object -Maximum).Maximum

# 建立物件陣列
$results = for ($i = 0; $i -lt $maxCount; $i++) {
    [PSCustomObject]@{
        CPU_ALL_Idle = if ($i -lt $all_idle.Count) { $all_idle[$i] } else { "" }
        CPU_0_Idle   = if ($i -lt $cpu0_idle.Count) { $cpu0_idle[$i] } else { "" }
        CPU_1_Idle   = if ($i -lt $cpu1_idle.Count) { $cpu1_idle[$i] } else { "" }
    }
}

# 匯出為 CSV (使用 UTF8 編碼以相容 Excel)
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Excel: $outputFile" -ForegroundColor Cyan
