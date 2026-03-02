# OpenWrt Builder

> 基于 [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) 的 OpenWrt 自动编译框架。  
> 支持多设备并行编译、自动发布 Release、上游更新检测与手动 SSH 调试。

---

## ✨ 亮点

- 🚀 Push 即编译：修改 `configs/`、`scripts/` 或 workflow 即自动触发
- 📦 多设备并行：`configs/*.config` 一设备一任务，互不干扰
- 🔄 上游追踪：每 6 小时检测一次上游提交变化
- 🧩 脚本模块化：`diy-*.sh` 自动按序执行，无需改 workflow
- 🗂️ 自动发布：编译产物发布到 Releases，保留最近版本
- 🛡️ CI 加固：并发控制、失败日志上传、配置校验流程

---

## 📁 仓库结构

```text
.
├── .github/workflows/
│   ├── build-openwrt.yml      # 主编译流程（自动/定时/手动）
│   ├── manual-build.yml       # 手动编译（支持 SSH 调试）
│   ├── check-update.yml       # 上游更新检测并触发构建
│   └── validate-configs.yml   # 配置与脚本规范校验
├── configs/
│   ├── default.config         # 默认配置（无其他 config 时回退）
│   ├── default.cfg            # 默认参数（IP/主题/描述等）
│   └── <device>.config        # 设备配置（可多个）
├── scripts/
│   ├── customize.sh           # feeds update 前执行
│   ├── diy-1-settings.sh      # 系统参数定制
│   ├── diy-2-packages.sh      # 额外软件包
│   └── diy-*.sh               # 你的自定义扩展脚本
└── README.md
```

---

## 🚀 快速开始

### 1) 准备设备配置

在本地生成 `.config`，放入 `configs/` 并按设备命名：

```bash
configs/ax3600.config
configs/ax9000.config
```

> 若存在非 `default.config` 的配置，构建会自动跳过 `default.config`。

### 2) 提交并触发构建

```bash
git add configs/ax3600.config
git commit -m "add ax3600 config"
git push
```

### 3) 下载固件

构建完成后，在仓库 **Releases** 页面下载固件。

---

## 🕹️ 触发方式

| 方式 | 说明 |
|---|---|
| Push 触发 | 修改 `configs/`、`scripts/`、workflow 文件时自动触发 |
| 定时触发 | 每天北京时间 10:00（默认关闭） |
| 上游触发 | 每 6 小时检查上游，有新提交自动触发 |
| 手动触发 | Actions 中运行 `手动触发编译`，可指定配置并启用 SSH |

### 开启定时编译

仓库中设置变量：

`Settings → Secrets and variables → Actions → Variables`

新增：

- `ENABLE_SCHEDULE=true`

---

## 🧩 自定义脚本机制

`customize.sh` 与 `diy-*.sh` 在编译前自动执行：

```text
customize.sh (feeds update 前)
    ↓
feeds update & install
    ↓
diy-1-*.sh
    ↓
diy-2-*.sh
    ↓
diy-3-*.sh ...
    ↓
开始编译
```

### 新增脚本示例

```bash
touch scripts/diy-3-smartdns.sh
```

命名规则：`diy-<数字>-<描述>.sh`（数字决定顺序）。

---

## ⚙️ 多设备并行说明

`configs/` 下每个 `.config` 都会生成独立 job：

```text
configs/
├── ax3600.config  -> job 1
├── ax9000.config  -> job 2
└── r4s.config     -> job 3
```

各 job 并行执行，最终分别产出固件与 Release 文件。

---

## 🛠️ 本地生成配置文件

```bash
git clone --depth 1 --single-branch --branch main-nss \
  https://github.com/LiBwrt/openwrt-6.x openwrt
cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig

cp .config /path/to/this-repo/configs/your-device.config
```

---

## 📌 默认参数

| 参数 | 值 |
|---|---|
| 上游源码 | `LiBwrt/openwrt-6.x` |
| 编译分支 | `main-nss` |
| 默认登录 IP | `192.168.100.1` |
| 默认密码 | 无 |
| Release 保留 | 最近 5 个 |
| Artifact 保留 | 7 天 |

---

## 📄 License

MIT
