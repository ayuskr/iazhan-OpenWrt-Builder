#!/bin/bash

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

cfg_get_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    return 0
  fi

  sed -n "s/^${key}=//p" "$file" | head -n1 || true
}

cfg_get_trimmed_value() {
  trim_whitespace "$(cfg_get_value "$1" "$2")"
}

default_theme_config_package() {
  case "$1" in
    luci-theme-argon)
      printf '%s' 'luci-app-argon-config'
      ;;
    luci-theme-aurora)
      printf '%s' 'luci-app-aurora-config'
      ;;
    *)
      printf '%s' ''
      ;;
  esac
}

builder_config_defaults() {
  DEFAULT_IP="192.168.100.1"
  DEFAULT_THEME="luci-theme-argon"
  THEME_CONFIG_PACKAGE="$(default_theme_config_package "$DEFAULT_THEME")"
  DEFAULT_HOSTNAME="OpenWrt"
  BUILDER_NAME="OpenWrt Builder"
  RELEASES_URL=""
  DESC="This is OpenWrt Firmware"
  WIFI_SSID=""
  WIFI_PASSWORD=""
  NOWIFI=""
}

builder_cfg_path() {
  local config_name="${1:-default}"
  local specific_cfg="$GITHUB_WORKSPACE/configs/${config_name}.cfg"

  if [ -f "$specific_cfg" ]; then
    printf '%s' "$specific_cfg"
  else
    printf '%s' "$GITHUB_WORKSPACE/configs/default.cfg"
  fi
}

load_builder_cfg() {
  local cfg_file="$1"
  builder_config_defaults

  if [ ! -f "$cfg_file" ]; then
    return 0
  fi

  local _ip _theme _theme_cfg _hostname _builder _url _desc _ssid _password _nowifi
  _ip="$(cfg_get_trimmed_value "$cfg_file" 'DEFAULT_IP')"
  _theme="$(cfg_get_trimmed_value "$cfg_file" 'DEFAULT_THEME')"
  _theme_cfg="$(cfg_get_trimmed_value "$cfg_file" 'THEME_CONFIG_PACKAGE')"
  _hostname="$(cfg_get_trimmed_value "$cfg_file" 'DEFAULT_HOSTNAME')"
  _builder="$(cfg_get_value "$cfg_file" 'BUILDER_NAME')"
  _url="$(cfg_get_trimmed_value "$cfg_file" 'RELEASES_URL')"
  _desc="$(cfg_get_value "$cfg_file" 'DESC')"
  _ssid="$(cfg_get_value "$cfg_file" 'WIFI_SSID')"
  _password="$(cfg_get_value "$cfg_file" 'WIFI_PASSWORD')"
  _nowifi="$(cfg_get_trimmed_value "$cfg_file" 'NOWIFI')"

  [ -n "$_ip" ] && DEFAULT_IP="$_ip"
  [ -n "$_theme" ] && DEFAULT_THEME="$_theme"
  [ -n "$_hostname" ] && DEFAULT_HOSTNAME="$_hostname"
  [ -n "$_builder" ] && BUILDER_NAME="$_builder"
  [ -n "$_url" ] && RELEASES_URL="$_url"
  [ -n "$_desc" ] && DESC="$_desc"
  [ -n "$_ssid" ] && WIFI_SSID="$_ssid"
  [ -n "$_password" ] && WIFI_PASSWORD="$_password"
  [ -n "$_nowifi" ] && NOWIFI="$_nowifi"

  if [ -n "$_theme_cfg" ]; then
    THEME_CONFIG_PACKAGE="$_theme_cfg"
  else
    THEME_CONFIG_PACKAGE="$(default_theme_config_package "$DEFAULT_THEME")"
  fi
}

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\/&#]/\\&/g'
}