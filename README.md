# OpenClaw 一键管理脚本

> 让新手也能 30 秒内完成 [OpenClaw](https://docs.openclaw.ai) 安装与配置的交互式 Bash 脚本。

![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WSL2-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

<img width="527" height="553" alt="image" src="https://github.com/user-attachments/assets/3fa2d4ec-bb48-4401-8a89-7178e0904fc0" />

## 功能概览

```
主菜单
├── 1. 🔍 环境检查与准备
│   ├── 全面环境检查（Node / npm / pnpm / Git / Docker / OpenClaw）
│   ├── 安装 Node.js v24（nvm / fnm / 系统包管理器）
│   ├── 切换 npm 国内镜像源 / 还原官方源
│   └── 安装 pnpm
├── 2. 📦 安装 OpenClaw
│   ├── ⭐ 一键智能安装（自动检测环境 → 国内源 → 安装 → 引导）
│   ├── 官方安装脚本
│   ├── npm / pnpm 全局安装
│   ├── 从源码构建
│   └── 仅安装（跳过新手引导）
├── 3. ⚙️  配置管理
│   ├── 新手引导 / 交互式配置向导
│   ├── 查看 / 设置 / 删除配置项
│   ├── 验证配置 / 健康检查 (doctor)
│   └── 密钥管理 & 安全审计
├── 4. 🔧 日常维护
│   ├── 状态概览 / 详细状态（含渠道探测）
│   ├── 健康检查 / 仪表盘 / 日志
│   ├── 会话管理 / 备份管理 / 内存管理
│   ├── Gateway 网关（启动/停止/重启/安装/卸载）
│   └── Cron 定时任务
├── 5. 📡 渠道管理
│   ├── 列出/状态检查/添加/移除渠道
│   ├── WhatsApp Web 登录/登出
│   └── 配对请求管理
├── 6. 🧩 插件管理（含飞书）
│   ├── ⭐ 飞书 OpenClaw 插件安装 / 升级
│   ├── 飞书流式输出开关
│   ├── 通用插件 list/install/enable/disable/doctor
│   └── Skills 列表 & 就绪检查
├── 7. 🤖 模型管理
│   ├── 模型状态 / 列表 / 扫描
│   ├── 设置默认模型 / 图像模型
│   ├── 认证管理（交互式 / setup-token / paste-token）
│   ├── 别名管理
│   └── 回退模型管理（文本 & 图像）
├── 8. 🤝 智能体管理
│   ├── 列出/添加/删除智能体
│   ├── 路由绑定管理
│   └── 消息发送
├── 9. 🔄 更新与卸载
│   ├── 更新 OpenClaw
│   ├── 重置（配置 / 配置+凭据+会话 / 完全）
│   └── 卸载（服务+数据 / 完全 / 彻底移除 CLI）
└── 0. ⚡ 快捷操作
    ├── 一键状态总览 / 一键诊断
    ├── TUI 终端界面 / 浏览器仪表盘
    └── 文档搜索 / 版本查看
```

## 特色

- **国内网络自动检测**：通过 Google 连通性 + 系统时区 + Locale 三重判断，自动切换 npm 镜像源
- **一键智能安装**：检测 Node → 检测网络 → 切换镜像 → 安装 OpenClaw → 运行引导，全程无需手动干预
- **飞书插件集成**：内置飞书官方 OpenClaw 插件的安装、升级、流式输出配置
- **层级菜单导航**：每级子菜单均可返回上级，主菜单可退出
- **彩色终端输出**：ASCII Banner + 状态指示器 + 彩色提示，清晰友好
- **安全操作确认**：删除、重置、卸载等危险操作均需二次确认

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | macOS / Linux / WSL2 |
| Shell | Bash 4.0+ |
| Node.js | v24 推荐（v22.16+ 兼容），脚本可自动安装 |
| curl | 必须（安装脚本依赖） |

> **Windows 用户**：请在 [WSL2](https://learn.microsoft.com/zh-cn/windows/wsl/install) 环境下运行。

## 快速开始

### 一行命令运行

> 国内服务器 / 本地电脑如果拉取 GitHub 困难，请使用下方 **国内加速** 命令。

<table>
<tr><td><b>🌏 国际线路</b>（GitHub 源）</td></tr>
<tr><td>

```bash
curl -fsSL https://raw.githubusercontent.com/jxzzlfh/openclaw/main/openclaw-manager.sh -o openclaw-manager.sh && chmod +x openclaw-manager.sh && ./openclaw-manager.sh
```

</td></tr>
<tr><td><b>🇨🇳 国内加速</b>（国内服务器源）</td></tr>
<tr><td>

```bash
curl -fsSL https://cang.zixi.run/openclaw-manager.sh | tr -d '\r' > openclaw-manager.sh && chmod +x openclaw-manager.sh && ./openclaw-manager.sh
```

</td></tr>
</table>

### 手动下载运行

```bash
# 1. 克隆仓库
git clone https://github.com/jxzzlfh/openclaw.git
cd openclaw

# 2. 添加执行权限
chmod +x openclaw-manager.sh

# 3. 运行脚本
./openclaw-manager.sh
```

### WSL2 用户

```powershell
# 国际线路
wsl bash -c "curl -fsSL https://raw.githubusercontent.com/jxzzlfh/openclaw/main/openclaw-manager.sh -o openclaw-manager.sh && chmod +x openclaw-manager.sh && ./openclaw-manager.sh"

# 国内加速
wsl bash -c "curl -fsSL https://cang.zixi.run/openclaw-manager.sh | tr -d '\r' > openclaw-manager.sh && chmod +x openclaw-manager.sh && ./openclaw-manager.sh"
```

## 使用示例

### 新手首次安装（推荐流程）

1. 运行脚本 → 选择 `1` 环境检查与准备 → 选择 `1` 全面环境检查
2. 如果 Node.js 未安装，选择 `2` 安装 Node.js
3. 返回主菜单 → 选择 `2` 安装 OpenClaw → 选择 `1` 一键智能安装
4. 按照引导完成模型配置

### 安装飞书插件

1. 主菜单 → 选择 `6` 插件管理 → 选择 `1` 安装飞书插件
2. 安装完成后选择 `3` 开启飞书流式输出

### 日常检查

1. 主菜单 → 选择 `0` 快捷操作 → 选择 `1` 一键状态总览

## 常用命令速查

| 场景 | 菜单路径 |
|------|----------|
| 首次安装 | `2 → 1`（一键智能安装） |
| 切换国内源 | `1 → 3` |
| 安装飞书插件 | `6 → 1` |
| 飞书流式输出 | `6 → 3` |
| 查看状态 | `0 → 1`（快捷一键总览） |
| 查看日志 | `4 → 5` 或 `4 → 6`（实时） |
| 设置默认模型 | `7 → 4` |
| 更新 OpenClaw | `9 → 1` |
| 完全卸载 | `9 → 8` |

## 相关文档

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [安装指南](https://docs.openclaw.ai/zh-CN/install)
- [CLI 参考](https://docs.openclaw.ai/zh-CN/cli)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)

## License

MIT
