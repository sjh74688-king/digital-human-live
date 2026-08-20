# =============================================================================
# 星澜直播 XingLan Live · Windows 一键安装脚本
#
# 说明：
#   1) 本脚本只从 GitHub Releases 下载【官方签名安装包】，不下载任何源码；
#   2) 下载后先做 SHA-256 完整性校验，再静默安装；
#   3) 需要以【管理员身份】运行 PowerShell。
#
# 用法：
#   iwr -useb https://raw.githubusercontent.com/<你的账号>/digital-human-live/main/scripts/install.ps1 -OutFile $env:TEMP\xl.ps1
#   powershell -ExecutionPolicy Bypass -File $env:TEMP\xl.ps1
#
# 上架前替换：<你的GitHub账号>、$Product 文件名前缀
# =============================================================================

$ErrorActionPreference = "Stop"

# ---------- 配置区（上架前替换） ----------
$RepoOwner   = "<你的GitHub账号>"
$RepoName    = "digital-human-live"
$ProductName = "XingLanLive"            # 安装包文件名前缀
$InstallDir  = "C:\Program Files\XingLanLive"
# 期望的 SHA-256（每次发版后由发布流程更新到这里；也可改为从 Releases 的 sha256.txt 读取）
$ExpectedSha256 = "替换为最新版本的SHA256小写"
# ------------------------------------------

# 1. 获取最新版本 tag（调用 GitHub API，无需 token 有速率限制但个人足够）
Write-Host "[1/4] 查询最新版本..." -ForegroundColor Cyan
$api = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
$rel = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "XingLanInstaller" }
$tag = $rel.tag_name
Write-Host "      最新版本: $tag"

# 2. 定位 Windows 安装包资产
$asset = $rel.assets | Where-Object { $_.name -like "$ProductName-Setup-*x64.exe" } | Select-Object -First 1
if (-not $asset) { throw "未找到 Windows 安装包资产（$ProductName-Setup-*x64.exe）" }
$url = $asset.browser_download_url
Write-Host "[2/4] 下载: $url" -ForegroundColor Cyan

$exePath = Join-Path $env:TEMP "$($asset.name)"
Invoke-WebRequest -Uri $url -OutFile $exePath -UseBasicParsing

# 3. SHA-256 校验
Write-Host "[3/4] 校验 SHA-256..." -ForegroundColor Cyan
$actual = (Get-FileHash -Path $exePath -Algorithm SHA256).Hash.ToLower()
if ($ExpectedSha256 -and $actual -ne $ExpectedSha256) {
    Remove-Item $exePath -Force
    throw "SHA-256 校验失败！实际: $actual`n期望: $ExpectedSha256`n文件可能已损坏或被篡改，已删除。请重试或从 Releases 页面手动下载。"
}
Write-Host "      校验通过: $actual"

# 4. 静默安装
Write-Host "[4/4] 安装到 $InstallDir ..." -ForegroundColor Cyan
Start-Process -FilePath $exePath -ArgumentList "/S /D=$InstallDir" -Wait
if ($LASTEXITCODE -ne 0) { throw "安装失败，退出码 $LASTEXITCODE" }

Remove-Item $exePath -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "✔ 安装完成。请启动「星澜直播」并输入 License Key 激活。" -ForegroundColor Green
Write-Host "  购买/补发 Key：https://【购买链接】" -ForegroundColor Yellow
