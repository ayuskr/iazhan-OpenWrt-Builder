#!/bin/bash
# ================================================
# diy-2-packages.sh - 添加额外软件包
# 使用稀疏克隆将第三方插件加入 package/ 目录
# ================================================

set -euo pipefail

# ---- Git 稀疏克隆函数（只克隆指定子目录到 package/） ----
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ---- 移除 feeds 中的旧版包，替换为最新版 ----
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/lang/golang
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-aurora

# ---- sing-box 及相关包（按仓库 README 官方推荐方式）----
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box}
git clone https://github.com/sbwml/openwrt_helloworld package/helloworld

# ---- 更新 golang 最新工具链 ----
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ---- 主题（克隆到 feeds 目录）----
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config feeds/luci/applications/luci-app-argon-config
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-app-aurora-config feeds/luci/applications/luci-app-aurora-config

# ---- 额外插件（放到 package/ 目录）----
git_sparse_clone main https://github.com/VIKINGYFY/packages luci-app-wolplus

# ---- 重新 install，让编译系统识别替换后的包 ----
./scripts/feeds update -a
./scripts/feeds install -a

echo "✅ diy-2-packages.sh 执行完毕"