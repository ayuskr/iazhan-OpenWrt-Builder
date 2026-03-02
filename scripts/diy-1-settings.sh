#!/bin/bash
# ================================================
# diy-1-settings.sh - 系统设置
# 修改路由器的默认参数：IP、主机名、时区、主题等
# ================================================

set -euo pipefail

# ---- 读取 cfg 配置：优先读取与 config 同名的 .cfg，没有则读取 default.cfg ----
CFG_FILE="$GITHUB_WORKSPACE/configs/${MATRIX_CONFIG}.cfg"
[ -f "$CFG_FILE" ] || CFG_FILE="$GITHUB_WORKSPACE/configs/default.cfg"

DEFAULT_IP="192.168.100.1"
DEFAULT_THEME="luci-theme-argon"
DEFAULT_HOSTNAME="OpenWrt"
BUILDER_NAME="OpenWrt Builder"
RELEASES_URL=""
WIFI_SSID=""
WIFI_PASSWORD=""
NOWIFI=""
if [ -f "$CFG_FILE" ]; then
  _ip=$(grep -m1 '^DEFAULT_IP=' "$CFG_FILE" | cut -d= -f2 | tr -d ' ')
  _theme=$(grep -m1 '^DEFAULT_THEME=' "$CFG_FILE" | cut -d= -f2 | tr -d ' ')
  _hostname=$(grep -m1 '^DEFAULT_HOSTNAME=' "$CFG_FILE" | cut -d= -f2 | tr -d ' ')
  _builder=$(grep -m1 '^BUILDER_NAME=' "$CFG_FILE" | cut -d= -f2-)
  _url=$(grep -m1 '^RELEASES_URL=' "$CFG_FILE" | cut -d= -f2 | tr -d ' ')
  _ssid=$(grep -m1 '^WIFI_SSID=' "$CFG_FILE" | cut -d= -f2-)
  _password=$(grep -m1 '^WIFI_PASSWORD=' "$CFG_FILE" | cut -d= -f2-)
  _nowifi=$(grep -m1 '^NOWIFI=' "$CFG_FILE" | cut -d= -f2 | tr -d ' ')
  [ -n "$_ip" ]       && DEFAULT_IP="$_ip"
  [ -n "$_theme" ]    && DEFAULT_THEME="$_theme"
  [ -n "$_hostname" ] && DEFAULT_HOSTNAME="$_hostname"
  [ -n "$_builder" ]  && BUILDER_NAME="$_builder"
  [ -n "$_url" ]      && RELEASES_URL="$_url"
  [ -n "$_ssid" ]     && WIFI_SSID="$_ssid"
  [ -n "$_password" ] && WIFI_PASSWORD="$_password"
  [ -n "$_nowifi" ]   && NOWIFI="$_nowifi"
fi

# ---- 移除 luci-app-attendedsysupgrade ----
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# ---- 修改默认 IP ----
sed -i "s/192\.168\.[0-9]*\.[0-9]*/${DEFAULT_IP}/g" package/base-files/files/bin/config_generate
# LuCI 网络配置页面中的 IP 引用
sed -i "s/192\.168\.[0-9]*\.[0-9]*/${DEFAULT_IP}/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")

# ---- 修改默认主机名 ----
sed -i "s/hostname='.*'/hostname='${DEFAULT_HOSTNAME}'/g" package/base-files/files/bin/config_generate

# ---- 修改默认主题 ----
sed -i "s/luci-theme-bootstrap/${DEFAULT_THEME}/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# ---- 修改默认时区为上海 ----
# sed -i "s/'UTC'/'CST-8'\n\t\tset system.@system[-1].zonename='Asia\/Shanghai'/g" \
#   package/base-files/files/bin/config_generate

# ---- LuCI 状态页固件版本署名 ----
BUILD_TIME=$(TZ=Asia/Shanghai date "+%Y-%m-%d %H:%M:%S")
STATUS_JS="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
if [ -f "$STATUS_JS" ]; then
  sed -i "s#_('Firmware Version'), (L\.isObject(boardinfo\.release) ? boardinfo\.release\.description + ' / ' : '') + (luciversion || ''),# \
            _('Firmware Version'),\n \
            E('span', {}, [\n \
                (L.isObject(boardinfo.release)\n \
                ? boardinfo.release.description + ' / '\n \
                : '') + (luciversion || '') + ' / ',\n \
            E('a', {\n \
                href: '${RELEASES_URL}',\n \
                target: '_blank',\n \
                rel: 'noopener noreferrer'\n \
                }, [ 'Built by ${BUILDER_NAME} ${BUILD_TIME}' ])\n \
            ]),#" "$STATUS_JS"
fi

# ---- WiFi 默认名称和密码（NOWIFI 时跳过）----
if [ "$NOWIFI" != "true" ]; then
  WIFI_SH=$(find ./target/linux/qualcommax/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
  WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
  if [ -f "$WIFI_SH" ]; then
    [ -n "$WIFI_SSID" ]     && sed -i "s/BASE_SSID='.*'/BASE_SSID='${WIFI_SSID}'/g" "$WIFI_SH"
    [ -n "$WIFI_PASSWORD" ] && sed -i "s/BASE_WORD='.*'/BASE_WORD='${WIFI_PASSWORD}'/g" "$WIFI_SH"
  elif [ -f "$WIFI_UC" ]; then
    [ -n "$WIFI_SSID" ]     && sed -i "s/ssid='.*'/ssid='${WIFI_SSID}'/g" "$WIFI_UC"
    [ -n "$WIFI_PASSWORD" ] && sed -i "s/key='.*'/key='${WIFI_PASSWORD}'/g" "$WIFI_UC"
    sed -i "s/country='.*'/country='CN'/g" "$WIFI_UC"
    sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" "$WIFI_UC"
  fi
fi

# ---- 强制写入基础配置 ----
{
  echo "CONFIG_PACKAGE_luci=y"
  echo "CONFIG_LUCI_LANG_zh_Hans=y"
  echo "CONFIG_PACKAGE_${DEFAULT_THEME}=y"
  echo "CONFIG_PACKAGE_${DEFAULT_THEME}-config=y"
} >> .config

# ---- 高通平台专属调整 ----
# 取消 nss 相关 feed，开启 sqm-nss
# {
#   echo "CONFIG_FEED_nss_packages=n"
#   echo "CONFIG_FEED_sqm_scripts_nss=n"
#   echo "CONFIG_PACKAGE_luci-app-sqm=y"
#   echo "CONFIG_PACKAGE_sqm-scripts-nss=y"
#   echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y"
# } >> .config

# 设置 NSS 固件版本（ipq50xx 用 12.2，其他用 12.5）
# echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> .config
# if [[ "${MATRIX_CONFIG,,}" == *"ipq50"* ]]; then
#   echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> .config
# else
#   echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
# fi

# ---- 替换 apk 软件源为国内镜像，并删除不存在的 nss_packages 源（首次启动时执行）----
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-fix-apk-mirrors << 'SCRIPT'
#!/bin/sh
DISTFEEDS="/etc/apk/repositories.d/distfeeds.list"
if [ -f "$DISTFEEDS" ]; then
    sed -i \
      -e 's,https://downloads.immortalwrt.org,https://mirrors.cernet.edu.cn/immortalwrt,g' \
      -e 's,https://mirrors.vsean.net/openwrt,https://mirrors.cernet.edu.cn/immortalwrt,g' \
      "$DISTFEEDS"
    sed -i '/nss_packages/d' "$DISTFEEDS"
fi
exit 0
SCRIPT
chmod +x files/etc/uci-defaults/99-fix-apk-mirrors

echo "✅ diy-1-settings.sh 执行完毕"