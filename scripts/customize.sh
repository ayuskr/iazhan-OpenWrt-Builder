#!/bin/bash
# ================================================
# customize.sh - 修改 feeds 源（在 feeds update 之前执行）
# ================================================

set -euo pipefail

# ---- 添加 nikki feed（已存在则跳过）----
if ! grep -q 'nikki' feeds.conf.default; then
  echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
fi

echo "✅ customize.sh 执行完毕"