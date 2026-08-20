# =============================================================================
# 发版辅助脚本（在你的【私有构建机/CI】上运行，不是公开仓库要跑的东西）
#
# 作用：
#   1) 读取 build 目录里的安装包，生成 SHA-256 校验清单 sha256.txt；
#   2) 创建 GitHub Release（tag + 安装包 + sha256.txt + 发布说明）；
#   3) 打印需要回填到 install.ps1 / install.sh 的 $ExpectedSha256。
#
# 用法（在私有仓库根目录，已安装 gh 并 gh auth login）：
#   .\scripts\publish-release.ps1 -Tag "v1.0.0" -Notes "首个正式版"
#
# 注意：
#   - 安装包 > 2GB 的资产 GitHub 不收，请先传到对象存储，在 Release 说明里贴外链；
#   - 发版后记得把打印出来的 SHA-256 回填进公开仓库的两个安装脚本并提交。
# =============================================================================
param(
  [Parameter(Mandatory)][string]$Tag,
  [string]$Notes = "版本更新",
  [string]$BuildDir = "build",
  [string]$Repo = "占位/owner/digital-human-live"   # 替换为 你的账号/仓库名
)

$ErrorActionPreference = "Stop"
$buildDir = Resolve-Path $BuildDir
$assets = Get-ChildItem $buildDir -File -Include "*.exe","*.msi","*.dmg","*.zip" -Recurse

if (-not $assets) { throw "在 $buildDir 下没找到任何安装包" }

# 1) 生成 sha256.txt
$manifestPath = Join-Path $buildDir "sha256.txt"
$lines = foreach ($a in $assets) {
  $h = (Get-FileHash $a.FullName -Algorithm SHA256).Hash.ToLower()
  "$h  $($a.Name)"
}
$lines | Set-Content -Path $manifestPath -Encoding utf8
Write-Host "已生成 $manifestPath"

# 2) 创建/更新 Release
$ghArgs = @("release", "create", $Tag,
  "--repo", $Repo,
  "--title", "泡泡直播 $Tag",
  "--notes", $Notes,
  "--latest")
foreach ($a in $assets) { $ghArgs += "--generate-notes" | Out-Null; $ghArgs += $a.FullName }
$ghArgs += $manifestPath

# gh release create 不支持 --generate-notes 与自定义 notes 同用，这里简化：
& gh release create $Tag --repo $Repo --title "泡泡直播 $Tag" --notes $Notes @($assets | ForEach-Object { $_.FullName }) $manifestPath

Write-Host ""
Write-Host "✔ Release 已发布: $Tag"
Write-Host "下一步：把下面的 SHA-256 回填到公开仓库 scripts/install.ps1 的 `\$ExpectedSha256 并提交：" -ForegroundColor Yellow
Get-Content $manifestPath
