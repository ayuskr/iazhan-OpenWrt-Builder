#!/bin/bash
set -euo pipefail

source "$GITHUB_WORKSPACE/scripts/third-party-sources.sh"

echo "==> 移除不需要或重复的包"

rm -rf feeds/luci/applications/luci-app-homeproxy
rm -rf feeds/luci/applications/luci-app-nikki
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-upnp
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/luci/applications/luci-app-package-manager

rm -rf feeds/packages/net/smartdns
rm -rf feeds/packages/net/chinadns-ng
rm -rf feeds/packages/net/nikki
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/lang/golang

rm -rf feeds/luci/themes/luci-theme-aurora
rm -rf feeds/luci/applications/luci-app-aurora-config

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

echo "==> 拉取 PassWall Packages"
clone_pinned_repo "$PASSWALL_PACKAGES_REPO" "$PASSWALL_PACKAGES_BRANCH" "$PASSWALL_PACKAGES_COMMIT" package/passwall-packages

echo "==> 拉取 PassWall LuCI"
if ! git clone --depth=1 --single-branch --branch "$PASSWALL_LUCI_BRANCH" "$PASSWALL_LUCI_REPO" package/passwall; then
  echo "❌ PassWall 主仓库拉取失败：$PASSWALL_LUCI_REPO"
  echo "请检查仓库地址是否可匿名访问。"
  exit 1
fi

if [ "$PASSWALL_LUCI_COMMIT" != "HEAD" ]; then
  current="$(git -C package/passwall rev-parse HEAD)"
  if [ "$current" != "$PASSWALL_LUCI_COMMIT" ]; then
    git -C package/passwall fetch --depth=1 origin "$PASSWALL_LUCI_COMMIT"
    git -C package/passwall checkout -q "$PASSWALL_LUCI_COMMIT"
  fi
fi

echo "==> 拉取 MosDNS"
clone_pinned_repo "$MOSDNS_REPO" "$MOSDNS_BRANCH" "$MOSDNS_COMMIT" package/mosdns

echo "==> 拉取 Lucky"
clone_pinned_repo "$LUCKY_REPO" "$LUCKY_BRANCH" "$LUCKY_COMMIT" package/lucky

echo "==> 重新更新并安装 feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "✅ diy-2-packages.sh 执行完毕"
