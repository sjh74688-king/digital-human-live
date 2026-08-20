#!/usr/bin/env bash
# =============================================================================
# 泡泡直播 Paopao Live · macOS 一键安装脚本
#
# 说明：
#   1) 本脚本只从 GitHub Releases 下载【官方签名 + 公证（notarized）的 dmg】；
#   2) 下载后做 SHA-256 完整性校验，再挂载安装到 /Applications；
#   3) 在终端中运行：curl -fsSL <...>/install.sh | bash
#
# 上架前替换：REPO_OWNER、PRODUCT_PREFIX、EXPECTED_SHA256
# =============================================================================
set -euo pipefail

# ---------- 配置区（上架前替换） ----------
REPO_OWNER="<你的GitHub账号>"
REPO_NAME="digital-human-live"
PRODUCT_PREFIX="PaopaoLive"
APP_NAME="泡泡直播.app"          # dmg 内的应用名，按你打包时的实际名称替换
EXPECTED_SHA256="替换为最新版本的SHA256小写"
# ------------------------------------------

echo "[1/4] 查询最新版本..."
api="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
tag=$(curl -fsSL -H "User-Agent: PaopaoInstaller" "$api" | grep -m1 '"tag_name"' | cut -d'"' -f4)
echo "      最新版本: ${tag}"

# 定位 macOS 资产
dl_url=$(curl -fsSL -H "User-Agent: PaopaoInstaller" "$api" \
  | grep -m1 "${PRODUCT_PREFIX}-.*\.dmg\"" | grep 'browser_download_url' | cut -d'"' -f4)
if [[ -z "$dl_url" ]]; then
  echo "错误：未找到 macOS 安装包（${PRODUCT_PREFIX}-*.dmg）" >&2
  exit 1
fi

echo "[2/4] 下载: ${dl_url}"
dmg_path="$(mktemp -d)/xl.dmg"
curl -fSL --progress-bar -o "$dmg_path" "$dl_url"

echo "[3/4] 校验 SHA-256..."
if [[ -n "$EXPECTED_SHA256" && "$EXPECTED_SHA256" != "替换为最新版本的SHA256小写" ]]; then
  actual=$(shasum -a 256 "$dmg_path" | awk '{print $1}')
  if [[ "$actual" != "$EXPECTED_SHA256" ]]; then
    rm -f "$dmg_path"
    echo "错误：SHA-256 校验失败！实际: $actual  期望: $EXPECTED_SHA256" >&2
    exit 1
  fi
  echo "      校验通过"
else
  echo "      （未配置期望值，跳过校验——发布前请务必在脚本中填入）" >&2
fi

echo "[4/4] 安装到 /Applications ..."
mnt=$(mktemp -d)/mnt
mkdir -p "$mnt"
hdiutil attach "$dmg_path" -nobrowse -mountpoint "$mnt" >/dev/null
cp -R "$mnt/${APP_NAME}" /Applications/
hdiutil detach "$mnt" >/dev/null
rm -rf "$dmg_path" "$mnt"

# 清除 Gatekeeper 隔离标记（官方签名+公证的包一般不需要，保留作兜底；若被拦截请手动：右键→打开）
xattr -d com.apple.quarantine "/Applications/${APP_NAME}" 2>/dev/null || true

echo ""
echo "✔ 安装完成。请启动「泡泡直播」并输入 License Key 激活。"
echo "  购买/补发 Key：https://【购买链接】"
