#!/bin/bash

# ============================================================
# 第三方源码固定版本
# ============================================================

# ---- PassWall ----
PASSWALL_PACKAGES_REPO="https://github.com/xiaorouji/openwrt-passwall-packages.git"
PASSWALL_PACKAGES_BRANCH="main"
PASSWALL_PACKAGES_COMMIT="HEAD"

PASSWALL_LUCI_REPO="https://github.com/xiaorouji/openwrt-passwall.git"
PASSWALL_LUCI_BRANCH="main"
PASSWALL_LUCI_COMMIT="HEAD"


# ---- MosDNS ----
MOSDNS_REPO="https://github.com/sbwml/luci-app-mosdns"
MOSDNS_BRANCH="v5"
MOSDNS_COMMIT="HEAD"

# ---- Lucky ----
LUCKY_REPO="https://github.com/gdy666/luci-app-lucky"
LUCKY_BRANCH="main"
LUCKY_COMMIT="HEAD"

# ---- Golang ----
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="26.x"
GOLANG_COMMIT="dd4792423c1e93788fe25415ba04398f9c34e298"

# ---- Argon Theme ----
ARGON_THEME_REPO="https://github.com/jerrykuku/luci-theme-argon"
ARGON_THEME_BRANCH="master"
ARGON_THEME_COMMIT="7aba78ccb84297496f63e1dacefe64c89d83d72e"

ARGON_CONFIG_REPO="https://github.com/jerrykuku/luci-app-argon-config"
ARGON_CONFIG_BRANCH="master"
ARGON_CONFIG_COMMIT="2ddae597f994f8a49358f8dfd03b7e6a732aae63"

# ---- GECOOSAC 预留 ----
# GECOOSAC_REPO="https://github.com/xxx/xxx"
# GECOOSAC_BRANCH="main"
# GECOOSAC_COMMIT="HEAD"

clone_pinned_repo() {
  local repo="$1"
  local branch="$2"
  local commit="$3"
  local dest="$4"

  rm -rf "$dest"
  git clone --depth=1 --branch "$branch" --single-branch "$repo" "$dest"

  if [ "$commit" != "HEAD" ]; then
    local current
    current="$(git -C "$dest" rev-parse HEAD)"
    if [ "$current" != "$commit" ]; then
      git -C "$dest" fetch --depth=1 origin "$commit"
      git -C "$dest" checkout -q "$commit"
    fi
  fi
}

git_sparse_clone_pinned() {
  local branch="$1"
  local repo="$2"
  local commit="$3"
  shift 3

  local repo_name="${repo##*/}"
  repo_name="${repo_name%.git}"
  local tmpdir
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/${repo_name}.XXXXXX")"

  git clone --depth=1 --branch "$branch" --single-branch --filter=blob:none --sparse "$repo" "$tmpdir"

  if [ "$commit" != "HEAD" ]; then
    local current
    current="$(git -C "$tmpdir" rev-parse HEAD)"
    if [ "$current" != "$commit" ]; then
      git -C "$tmpdir" fetch --depth=1 origin "$commit"
      git -C "$tmpdir" checkout -q "$commit"
    fi
  fi

  git -C "$tmpdir" sparse-checkout set "$@"
  mkdir -p package
  for path in "$@"; do
    rm -rf "package/${path##*/}"
    mv -f "$tmpdir/$path" package/
  done
  rm -rf "$tmpdir"
}

emit_third_party_markdown() {
  cat <<EOF
## 🔗 第三方依赖版本

- \`openwrt-passwall-packages\`: ${PASSWALL_PACKAGES_REPO} @ ${PASSWALL_PACKAGES_COMMIT}
- \`openwrt-passwall\`: ${PASSWALL_LUCI_REPO} @ ${PASSWALL_LUCI_COMMIT}
- \`luci-app-mosdns\`: ${MOSDNS_REPO} @ ${MOSDNS_COMMIT}
- \`luci-app-lucky\`: ${LUCKY_REPO} @ ${LUCKY_COMMIT}
- \`packages_lang_golang\`: [sbwml/packages_lang_golang@${GOLANG_COMMIT}](https://github.com/sbwml/packages_lang_golang/commit/${GOLANG_COMMIT})
- \`luci-theme-argon\`: [jerrykuku/luci-theme-argon@${ARGON_THEME_COMMIT}](https://github.com/jerrykuku/luci-theme-argon/commit/${ARGON_THEME_COMMIT})
- \`luci-app-argon-config\`: [jerrykuku/luci-app-argon-config@${ARGON_CONFIG_COMMIT}](https://github.com/jerrykuku/luci-app-argon-config/commit/${ARGON_CONFIG_COMMIT})
EOF
}
