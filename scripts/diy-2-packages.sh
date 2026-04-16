#!/bin/bash
# ================================================
# diy-2-packages.sh - 主路由精简插件方案
# 目标：
# - 保留主路由基础
# - 添加 passwall / mosdns / lucky
# - 删除重复代理和无关主题/插件
# - 无 WiFi / 无 USB 方向配套
# ================================================

set -euo pipefail

source "$GITHUB_WORKSPACE/scripts/third-party-sources.sh"

echo "==> 移除不需要或重复的包"

# 重复代理 / DNS / 非必要插件
rm -rf feeds/luci/applications/luci-app-homeproxy
#rm -rf feeds/luci/applications/luci-app-nikki
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-upnp
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/luci/applications/luci-app-package-manager

rm -rf feeds/packages/net/smartdns
rm -rf feeds/packages/net/chinadns-ng
#rm -rf feeds/packages/net/nikki
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/lang/golang

# 不需要的主题/扩展
#rm -rf feeds/luci/themes/luci-theme-aurora
#rm -rf feeds/luci/applications/luci-app-aurora-config

# 额外包清理
rm -rf package/luci-app-wolplus
rm -rf package/helloworld
rm -rf package/passwall
rm -rf package/passwall-packages
rm -rf package/mosdns
rm -rf package/lucky

echo "==> 替换 Golang"
clone_pinned_repo "$GOLANG_REPO" "$GOLANG_BRANCH" "$GOLANG_COMMIT" feeds/packages/lang/golang

echo "==> 安装 Argon 主题"
clone_pinned_repo "$ARGON_THEME_REPO" "$ARGON_THEME_BRANCH" "$ARGON_THEME_COMMIT" feeds/luci/themes/luci-theme-argon
clone_pinned_repo "$ARGON_CONFIG_REPO" "$ARGON_CONFIG_BRANCH" "$ARGON_CONFIG_COMMIT" feeds/luci/applications/luci-app-argon-config

echo "==> 拉取 PassWall"
clone_pinned_repo "$PASSWALL_PACKAGES_REPO" "$PASSWALL_PACKAGES_BRANCH" "$PASSWALL_PACKAGES_COMMIT" package/passwall-packages
clone_pinned_repo "$PASSWALL_LUCI_REPO" "$PASSWALL_LUCI_BRANCH" "$PASSWALL_LUCI_COMMIT" package/passwall

echo "==> 拉取 MosDNS"
clone_pinned_repo "$MOSDNS_REPO" "$MOSDNS_BRANCH" "$MOSDNS_COMMIT" package/mosdns

echo "==> 拉取 Lucky"
clone_pinned_repo "$LUCKY_REPO" "$LUCKY_BRANCH" "$LUCKY_COMMIT" package/lucky

# ---- GECOOSAC 预留 ----
# echo "==> 拉取 GECOOSAC"
# clone_pinned_repo "$GECOOSAC_REPO" "$GECOOSAC_BRANCH" "$GECOOSAC_COMMIT" package/gecoosac

echo "==> 重新更新并安装 feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "✅ diy-2-packages.sh 执行完毕"
