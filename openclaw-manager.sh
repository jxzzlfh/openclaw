#!/usr/bin/env bash
# ============================================================================
# OpenClaw 一键管理脚本
# 适用于 macOS / Linux / WSL2
# 功能：安装、配置、日常维护、渠道管理、插件管理、模型管理、更新与卸载
# ============================================================================

set -euo pipefail

# --------------- 颜色定义 ---------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --------------- 工具函数 ---------------
print_banner() {
    clear
    echo -e "${RED}${BOLD}"
    cat << 'EOF'
   ___                    ____ _
  / _ \ _ __   ___ _ __  / ___| | __ ___      __
 | | | | '_ \ / _ \ '_ \| |   | |/ _` \ \ /\ / /
 | |_| | |_) |  __/ | | | |___| | (_| |\ V  V /
  \___/| .__/ \___|_| |_|\____|_|\__,_| \_/\_/
       |_|
EOF
    echo -e "${NC}"
    echo -e "${DIM}  一键管理脚本 v1.0 — 安装 · 配置 · 维护 · 更新${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
    echo ""
}

info()    { echo -e "  ${BLUE}ℹ${NC}  $*"; }
success() { echo -e "  ${GREEN}✔${NC}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "  ${RED}✘${NC}  $*"; }
header()  { echo -e "\n${CYAN}${BOLD}  ── $* ──${NC}\n"; }

press_enter() {
    echo ""
    read -rp "  按 Enter 继续..."
}

confirm() {
    local prompt="${1:-确认操作}"
    read -rp "  ${prompt} [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# --------------- 环境检测 ---------------
detect_os() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        OS="macOS"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        OS="WSL2"
    elif [[ "$(uname -s)" == "Linux" ]]; then
        OS="Linux"
    else
        OS="Unknown"
    fi
}

detect_china() {
    IS_CHINA=false
    if command -v curl &>/dev/null; then
        local test_url="https://www.google.com"
        if ! curl -s --connect-timeout 3 --max-time 5 "$test_url" &>/dev/null; then
            IS_CHINA=true
        fi
    fi
    if [[ -f /etc/timezone ]] && grep -qi "Asia/Shanghai\|Asia/Chongqing" /etc/timezone 2>/dev/null; then
        IS_CHINA=true
    fi
    if [[ "${LANG:-}" == *"zh_CN"* ]] || [[ "${LC_ALL:-}" == *"zh_CN"* ]]; then
        IS_CHINA=true
    fi
}

check_node() {
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//')
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
        return 0
    fi
    return 1
}

check_npm() {
    command -v npm &>/dev/null
}

check_openclaw() {
    command -v openclaw &>/dev/null
}

check_pnpm() {
    command -v pnpm &>/dev/null
}

check_git() {
    command -v git &>/dev/null
}

check_curl() {
    command -v curl &>/dev/null
}

check_docker() {
    command -v docker &>/dev/null
}

# --------------- 环境检查与准备菜单 ---------------
menu_env_check() {
    while true; do
        print_banner
        header "环境检查与准备"

        echo -e "  ${BOLD}1)${NC}  全面环境检查"
        echo -e "  ${BOLD}2)${NC}  安装 Node.js (推荐 v24)"
        echo -e "  ${BOLD}3)${NC}  切换 npm 为国内镜像源"
        echo -e "  ${BOLD}4)${NC}  还原 npm 为官方源"
        echo -e "  ${BOLD}5)${NC}  安装 pnpm"
        echo -e "  ${BOLD}6)${NC}  查看当前 npm 源"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-6]: " choice

        case $choice in
        1) do_full_env_check ;;
        2) do_install_node ;;
        3) do_set_china_npm ;;
        4) do_reset_npm ;;
        5) do_install_pnpm ;;
        6) do_show_npm_registry ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

do_full_env_check() {
    print_banner
    header "全面环境检查"

    detect_os
    info "操作系统: ${BOLD}$OS${NC}"

    detect_china
    if $IS_CHINA; then
        warn "检测到可能位于中国大陆网络环境"
    else
        info "网络环境: 国际网络"
    fi

    echo ""
    # Node.js
    if check_node; then
        if [[ "$NODE_MAJOR" -ge 24 ]]; then
            success "Node.js: v${NODE_VERSION} ${GREEN}(推荐版本)${NC}"
        elif [[ "$NODE_MAJOR" -ge 22 ]]; then
            warn "Node.js: v${NODE_VERSION} ${YELLOW}(兼容，建议升级到 v24)${NC}"
        else
            error "Node.js: v${NODE_VERSION} ${RED}(版本过低，需要 v22.16+ 或 v24)${NC}"
        fi
    else
        error "Node.js: ${RED}未安装${NC}"
    fi

    # npm
    if check_npm; then
        local npm_ver
        npm_ver=$(npm -v 2>/dev/null)
        success "npm: v${npm_ver}"
        local registry
        registry=$(npm config get registry 2>/dev/null)
        if [[ "$registry" == *"npmmirror"* ]] || [[ "$registry" == *"taobao"* ]]; then
            info "npm 源: ${CYAN}国内镜像${NC} ($registry)"
        else
            info "npm 源: $registry"
        fi
    else
        error "npm: ${RED}未安装${NC}"
    fi

    # pnpm
    if check_pnpm; then
        local pnpm_ver
        pnpm_ver=$(pnpm -v 2>/dev/null)
        success "pnpm: v${pnpm_ver}"
    else
        info "pnpm: 未安装 (可选)"
    fi

    # Git
    if check_git; then
        local git_ver
        git_ver=$(git --version 2>/dev/null | awk '{print $3}')
        success "Git: v${git_ver}"
    else
        warn "Git: 未安装 (从源码构建需要)"
    fi

    # curl
    if check_curl; then
        success "curl: 已安装"
    else
        error "curl: ${RED}未安装 (安装脚本需要)${NC}"
    fi

    # Docker
    if check_docker; then
        local docker_ver
        docker_ver=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
        success "Docker: v${docker_ver} (可选)"
    else
        info "Docker: 未安装 (可选，容器化部署需要)"
    fi

    # OpenClaw
    echo ""
    if check_openclaw; then
        local oc_ver
        oc_ver=$(openclaw --version 2>/dev/null || echo "未知")
        success "OpenClaw: ${GREEN}已安装${NC} (${oc_ver})"
    else
        info "OpenClaw: 未安装"
    fi

    # 建议
    echo ""
    header "建议"
    if ! check_node; then
        echo -e "  ${YELLOW}→${NC} 请先安装 Node.js v24 (选择菜单项 2)"
    fi
    if $IS_CHINA; then
        local registry
        registry=$(npm config get registry 2>/dev/null || echo "")
        if [[ "$registry" != *"npmmirror"* ]]; then
            echo -e "  ${YELLOW}→${NC} 建议切换 npm 为国内源以加速下载 (选择菜单项 3)"
        fi
    fi
    if ! check_openclaw; then
        echo -e "  ${YELLOW}→${NC} 环境就绪后，可前往"安装 OpenClaw"菜单进行安装"
    fi

    press_enter
}

do_install_node() {
    print_banner
    header "安装 Node.js"

    echo -e "  ${BOLD}1)${NC}  使用 nvm 安装 (推荐)"
    echo -e "  ${BOLD}2)${NC}  使用 fnm 安装"
    echo -e "  ${BOLD}3)${NC}  使用系统包管理器安装"
    echo ""
    echo -e "  ${DIM}0)  返回${NC}"
    echo ""
    read -rp "  请选择 [0-3]: " choice

    case $choice in
    1)
        info "正在安装 nvm..."
        if $IS_CHINA; then
            export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
            curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash || \
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        else
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        fi
        export NVM_DIR="${HOME}/.nvm"
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        info "正在安装 Node.js v24..."
        nvm install 24
        nvm use 24
        nvm alias default 24
        success "Node.js $(node -v) 安装完成"
        ;;
    2)
        info "正在安装 fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash
        export PATH="${HOME}/.local/share/fnm:$PATH"
        eval "$(fnm env)" 2>/dev/null || true
        info "正在安装 Node.js v24..."
        fnm install 24
        fnm use 24
        fnm default 24
        success "Node.js $(node -v) 安装完成"
        ;;
    3)
        detect_os
        if [[ "$OS" == "macOS" ]]; then
            if command -v brew &>/dev/null; then
                brew install node@24 || brew install node
            else
                error "请先安装 Homebrew: https://brew.sh"
            fi
        elif [[ "$OS" == "Linux" ]] || [[ "$OS" == "WSL2" ]]; then
            info "使用 NodeSource 安装..."
            curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
        success "Node.js $(node -v) 安装完成"
        ;;
    0) return ;;
    esac
    press_enter
}

do_set_china_npm() {
    info "切换 npm 为国内镜像源..."
    npm config set registry https://registry.npmmirror.com
    success "已切换至: $(npm config get registry)"
    press_enter
}

do_reset_npm() {
    info "还原 npm 为官方源..."
    npm config set registry https://registry.npmjs.org/
    success "已还原至: $(npm config get registry)"
    press_enter
}

do_install_pnpm() {
    info "正在安装 pnpm..."
    npm install -g pnpm@latest
    success "pnpm $(pnpm -v) 安装完成"
    press_enter
}

do_show_npm_registry() {
    local registry
    registry=$(npm config get registry 2>/dev/null)
    info "当前 npm 源: ${BOLD}$registry${NC}"
    press_enter
}

# --------------- 安装 OpenClaw 菜单 ---------------
menu_install() {
    while true; do
        print_banner
        header "安装 OpenClaw"

        echo -e "  ${BOLD}1)${NC}  ${GREEN}一键智能安装 (推荐)${NC}"
        echo -e "  ${BOLD}2)${NC}  官方安装脚本"
        echo -e "  ${BOLD}3)${NC}  npm 全局安装"
        echo -e "  ${BOLD}4)${NC}  pnpm 全局安装"
        echo -e "  ${BOLD}5)${NC}  从源码构建"
        echo -e "  ${BOLD}6)${NC}  仅安装 (跳过新手引导)"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-6]: " choice

        case $choice in
        1) do_smart_install ;;
        2) do_install_script ;;
        3) do_install_npm ;;
        4) do_install_pnpm_oc ;;
        5) do_install_source ;;
        6) do_install_no_onboard ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

do_smart_install() {
    print_banner
    header "一键智能安装"

    # 检查 Node
    if ! check_node; then
        warn "未检测到 Node.js，将自动安装..."
        detect_china
        if $IS_CHINA; then
            info "检测到国内网络，使用镜像安装..."
            export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
        fi
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        export NVM_DIR="${HOME}/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        nvm install 24
        nvm use 24
        nvm alias default 24
        success "Node.js $(node -v) 安装完成"
    else
        success "Node.js v${NODE_VERSION} 已就绪"
    fi

    # 检查 npm 源
    detect_china
    if $IS_CHINA; then
        local registry
        registry=$(npm config get registry 2>/dev/null)
        if [[ "$registry" != *"npmmirror"* ]]; then
            info "国内网络，自动切换 npm 镜像源..."
            npm config set registry https://registry.npmmirror.com
            success "npm 源已切换至国内镜像"
        fi
    fi

    # 安装 OpenClaw
    info "正在安装 OpenClaw..."
    npm install -g openclaw@latest
    success "OpenClaw 安装完成"

    # 运行新手引导
    info "启动新手引导..."
    openclaw onboard --install-daemon

    success "安装与配置全部完成！"
    press_enter
}

do_install_script() {
    print_banner
    header "官方安装脚本"
    info "运行官方安装脚本..."
    curl -fsSL https://openclaw.ai/install.sh | bash
    success "安装完成"
    press_enter
}

do_install_npm() {
    print_banner
    header "npm 全局安装"
    npm install -g openclaw@latest
    success "安装完成，正在运行新手引导..."
    openclaw onboard --install-daemon
    press_enter
}

do_install_pnpm_oc() {
    print_banner
    header "pnpm 全局安装"
    if ! check_pnpm; then
        warn "pnpm 未安装，先安装 pnpm..."
        npm install -g pnpm@latest
    fi
    pnpm add -g openclaw@latest
    info "请运行以下命令批准构建脚本："
    echo -e "  ${CYAN}pnpm approve-builds -g${NC}"
    pnpm approve-builds -g || true
    openclaw onboard --install-daemon
    success "安装完成"
    press_enter
}

do_install_source() {
    print_banner
    header "从源码构建"
    if ! check_git; then
        error "需要 Git，请先安装"
        press_enter
        return
    fi
    if ! check_pnpm; then
        info "安装 pnpm..."
        npm install -g pnpm@latest
    fi
    local clone_dir="${HOME}/openclaw-src"
    if [[ -d "$clone_dir" ]]; then
        warn "目录 $clone_dir 已存在"
        if ! confirm "删除并重新克隆?"; then
            press_enter
            return
        fi
        rm -rf "$clone_dir"
    fi
    git clone https://github.com/openclaw/openclaw.git "$clone_dir"
    cd "$clone_dir"
    pnpm install
    pnpm ui:build
    pnpm build
    pnpm link --global
    openclaw onboard --install-daemon
    success "源码构建安装完成"
    press_enter
}

do_install_no_onboard() {
    print_banner
    header "仅安装 (跳过新手引导)"
    curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
    success "安装完成 (跳过了新手引导，后续可运行 openclaw onboard)"
    press_enter
}

# --------------- 配置管理菜单 ---------------
menu_config() {
    while true; do
        print_banner
        header "配置管理"

        echo -e "  ${BOLD}1)${NC}  运行新手引导 (onboard)"
        echo -e "  ${BOLD}2)${NC}  交互式配置向导 (configure)"
        echo -e "  ${BOLD}3)${NC}  查看配置项"
        echo -e "  ${BOLD}4)${NC}  设置配置项"
        echo -e "  ${BOLD}5)${NC}  删除配置项"
        echo -e "  ${BOLD}6)${NC}  验证配置"
        echo -e "  ${BOLD}7)${NC}  查看配置文件路径"
        echo -e "  ${BOLD}8)${NC}  健康检查 (doctor)"
        echo -e "  ${BOLD}9)${NC}  密钥管理"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-9]: " choice

        case $choice in
        1) openclaw onboard --install-daemon; press_enter ;;
        2) openclaw configure; press_enter ;;
        3)
            read -rp "  配置路径 (如 agents.defaults.model.primary): " path
            [[ -n "$path" ]] && openclaw config get "$path"
            press_enter
            ;;
        4)
            read -rp "  配置路径: " path
            read -rp "  配置值: " val
            [[ -n "$path" && -n "$val" ]] && openclaw config set "$path" "$val" && success "已设置"
            press_enter
            ;;
        5)
            read -rp "  配置路径: " path
            [[ -n "$path" ]] && openclaw config unset "$path" && success "已删除"
            press_enter
            ;;
        6) openclaw config validate; press_enter ;;
        7) openclaw config file; press_enter ;;
        8) openclaw doctor; press_enter ;;
        9) menu_secrets ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_secrets() {
    while true; do
        print_banner
        header "密钥管理"

        echo -e "  ${BOLD}1)${NC}  重新加载密钥"
        echo -e "  ${BOLD}2)${NC}  审计密钥"
        echo -e "  ${BOLD}3)${NC}  交互式密钥配置"
        echo -e "  ${BOLD}4)${NC}  安全审计"
        echo -e "  ${BOLD}5)${NC}  安全审计 (深度)"
        echo -e "  ${BOLD}6)${NC}  安全修复"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-6]: " choice

        case $choice in
        1) openclaw secrets reload; press_enter ;;
        2) openclaw secrets audit; press_enter ;;
        3) openclaw secrets configure; press_enter ;;
        4) openclaw security audit; press_enter ;;
        5) openclaw security audit --deep; press_enter ;;
        6) openclaw security audit --fix; press_enter ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 日常维护菜单 ---------------
menu_maintain() {
    while true; do
        print_banner
        header "日常维护"

        echo -e "  ${BOLD} 1)${NC}  查看状态概览"
        echo -e "  ${BOLD} 2)${NC}  查看详细状态 (含渠道探测)"
        echo -e "  ${BOLD} 3)${NC}  健康检查"
        echo -e "  ${BOLD} 4)${NC}  打开仪表盘 (浏览器)"
        echo -e "  ${BOLD} 5)${NC}  查看日志"
        echo -e "  ${BOLD} 6)${NC}  查看日志 (实时跟踪)"
        echo -e "  ${BOLD} 7)${NC}  会话管理"
        echo -e "  ${BOLD} 8)${NC}  备份管理"
        echo -e "  ${BOLD} 9)${NC}  内存管理"
        echo -e "  ${BOLD}10)${NC}  Gateway 网关管理"
        echo -e "  ${BOLD}11)${NC}  Cron 定时任务"
        echo ""
        echo -e "  ${DIM} 0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-11]: " choice

        case $choice in
        1)  openclaw status; press_enter ;;
        2)  openclaw status --deep --usage; press_enter ;;
        3)  openclaw health --verbose; press_enter ;;
        4)  openclaw dashboard ;;
        5)  openclaw logs --limit 100; press_enter ;;
        6)  info "按 Ctrl+C 退出日志跟踪"; openclaw logs --follow; press_enter ;;
        7)  openclaw sessions --verbose; press_enter ;;
        8)  menu_backup ;;
        9)  menu_memory ;;
        10) menu_gateway ;;
        11) menu_cron ;;
        0)  return ;;
        *)  warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_backup() {
    while true; do
        print_banner
        header "备份管理"

        echo -e "  ${BOLD}1)${NC}  创建备份"
        echo -e "  ${BOLD}2)${NC}  验证备份"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-2]: " choice

        case $choice in
        1) openclaw backup create; press_enter ;;
        2) openclaw backup verify; press_enter ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_memory() {
    while true; do
        print_banner
        header "内存管理"

        echo -e "  ${BOLD}1)${NC}  查看内存索引状态"
        echo -e "  ${BOLD}2)${NC}  重新索引内存"
        echo -e "  ${BOLD}3)${NC}  语义搜索内存"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-3]: " choice

        case $choice in
        1) openclaw memory status; press_enter ;;
        2) openclaw memory index; press_enter ;;
        3)
            read -rp "  搜索关键词: " query
            [[ -n "$query" ]] && openclaw memory search "$query"
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_gateway() {
    while true; do
        print_banner
        header "Gateway 网关管理"

        echo -e "  ${BOLD}1)${NC}  查看网关状态"
        echo -e "  ${BOLD}2)${NC}  启动网关"
        echo -e "  ${BOLD}3)${NC}  停止网关"
        echo -e "  ${BOLD}4)${NC}  重启网关"
        echo -e "  ${BOLD}5)${NC}  安装网关服务"
        echo -e "  ${BOLD}6)${NC}  卸载网关服务"
        echo -e "  ${BOLD}7)${NC}  网关健康探测"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-7]: " choice

        case $choice in
        1) openclaw gateway status; press_enter ;;
        2) openclaw gateway start; press_enter ;;
        3) openclaw gateway stop; press_enter ;;
        4) openclaw gateway restart; press_enter ;;
        5) openclaw gateway install; press_enter ;;
        6) openclaw gateway uninstall; press_enter ;;
        7) openclaw gateway health; press_enter ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_cron() {
    while true; do
        print_banner
        header "Cron 定时任务"

        echo -e "  ${BOLD}1)${NC}  Cron 状态"
        echo -e "  ${BOLD}2)${NC}  列出任务"
        echo -e "  ${BOLD}3)${NC}  添加任务"
        echo -e "  ${BOLD}4)${NC}  启用任务"
        echo -e "  ${BOLD}5)${NC}  禁用任务"
        echo -e "  ${BOLD}6)${NC}  删除任务"
        echo -e "  ${BOLD}7)${NC}  手动运行任务"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-7]: " choice

        case $choice in
        1) openclaw cron status; press_enter ;;
        2) openclaw cron list --all; press_enter ;;
        3)
            info "将进入交互式创建（需要提供 --name, --at/--every/--cron, --message/--system-event）"
            read -rp "  任务名称: " name
            read -rp "  调度规则 (如 '0 9 * * *'): " cron_expr
            read -rp "  消息内容: " msg
            [[ -n "$name" && -n "$cron_expr" && -n "$msg" ]] && \
                openclaw cron add --name "$name" --cron "$cron_expr" --message "$msg"
            press_enter
            ;;
        4)
            read -rp "  任务 ID: " tid
            [[ -n "$tid" ]] && openclaw cron enable "$tid"
            press_enter
            ;;
        5)
            read -rp "  任务 ID: " tid
            [[ -n "$tid" ]] && openclaw cron disable "$tid"
            press_enter
            ;;
        6)
            read -rp "  任务 ID: " tid
            [[ -n "$tid" ]] && openclaw cron rm "$tid"
            press_enter
            ;;
        7)
            read -rp "  任务 ID: " tid
            [[ -n "$tid" ]] && openclaw cron run "$tid"
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 渠道管理菜单 ---------------
menu_channels() {
    while true; do
        print_banner
        header "渠道管理"

        echo -e "  ${BOLD}1)${NC}  列出已配置渠道"
        echo -e "  ${BOLD}2)${NC}  渠道状态检查"
        echo -e "  ${BOLD}3)${NC}  渠道状态检查 (深度探测)"
        echo -e "  ${BOLD}4)${NC}  添加渠道"
        echo -e "  ${BOLD}5)${NC}  移除渠道"
        echo -e "  ${BOLD}6)${NC}  渠道登录 (WhatsApp Web)"
        echo -e "  ${BOLD}7)${NC}  渠道登出"
        echo -e "  ${BOLD}8)${NC}  查看渠道日志"
        echo -e "  ${BOLD}9)${NC}  配对请求管理"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-9]: " choice

        case $choice in
        1) openclaw channels list; press_enter ;;
        2) openclaw channels status; press_enter ;;
        3) openclaw channels status --probe; press_enter ;;
        4) openclaw channels add; press_enter ;;
        5)
            read -rp "  渠道名称 (whatsapp/telegram/discord/slack/feishu...): " ch
            read -rp "  账户 ID (默认 default): " acc
            acc="${acc:-default}"
            if confirm "确认移除 ${ch}:${acc}?"; then
                openclaw channels remove --channel "$ch" --account "$acc" --delete
            fi
            press_enter
            ;;
        6) openclaw channels login; press_enter ;;
        7)
            read -rp "  渠道名称: " ch
            openclaw channels logout --channel "${ch:-whatsapp}"
            press_enter
            ;;
        8) openclaw channels logs; press_enter ;;
        9)
            echo -e "  ${BOLD}a)${NC} 列出配对请求"
            echo -e "  ${BOLD}b)${NC} 批准配对"
            read -rp "  选择: " sub
            case $sub in
            a) openclaw pairing list ;;
            b)
                read -rp "  渠道: " ch
                read -rp "  配对码: " code
                openclaw pairing approve "$ch" "$code" --notify
                ;;
            esac
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 插件管理菜单 (含飞书) ---------------
menu_plugins() {
    while true; do
        print_banner
        header "插件管理"

        echo -e "  ${MAGENTA}${BOLD}── 飞书 (Lark) 插件 ──${NC}"
        echo -e "  ${BOLD}1)${NC}  ${GREEN}安装飞书 OpenClaw 插件${NC}"
        echo -e "  ${BOLD}2)${NC}  升级飞书 OpenClaw 插件"
        echo -e "  ${BOLD}3)${NC}  开启飞书流式输出"
        echo -e "  ${BOLD}4)${NC}  关闭飞书流式输出"
        echo ""
        echo -e "  ${MAGENTA}${BOLD}── 通用插件管理 ──${NC}"
        echo -e "  ${BOLD}5)${NC}  列出所有插件"
        echo -e "  ${BOLD}6)${NC}  查看插件详情"
        echo -e "  ${BOLD}7)${NC}  安装插件"
        echo -e "  ${BOLD}8)${NC}  启用插件"
        echo -e "  ${BOLD}9)${NC}  禁用插件"
        echo -e "  ${BOLD}10)${NC} 插件诊断"
        echo ""
        echo -e "  ${MAGENTA}${BOLD}── Skills ──${NC}"
        echo -e "  ${BOLD}11)${NC} 列出 Skills"
        echo -e "  ${BOLD}12)${NC} Skills 就绪检查"
        echo ""
        echo -e "  ${DIM} 0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-12]: " choice

        case $choice in
        1)
            info "正在安装飞书 OpenClaw 插件..."
            npx -y @larksuite/openclaw-lark-tools install
            success "飞书插件安装完成"
            press_enter
            ;;
        2)
            info "正在升级飞书 OpenClaw 插件..."
            npx -y @larksuite/openclaw-lark-tools update
            success "飞书插件升级完成"
            press_enter
            ;;
        3)
            openclaw config set channels.feishu.streaming true
            success "飞书流式输出已开启"
            press_enter
            ;;
        4)
            openclaw config set channels.feishu.streaming false
            success "飞书流式输出已关闭"
            press_enter
            ;;
        5) openclaw plugins list; press_enter ;;
        6)
            read -rp "  插件 ID: " pid
            [[ -n "$pid" ]] && openclaw plugins info "$pid"
            press_enter
            ;;
        7)
            read -rp "  插件路径/包名: " pkg
            [[ -n "$pkg" ]] && openclaw plugins install "$pkg"
            press_enter
            ;;
        8)
            read -rp "  插件 ID: " pid
            [[ -n "$pid" ]] && openclaw plugins enable "$pid"
            press_enter
            ;;
        9)
            read -rp "  插件 ID: " pid
            [[ -n "$pid" ]] && openclaw plugins disable "$pid"
            press_enter
            ;;
        10) openclaw plugins doctor; press_enter ;;
        11) openclaw skills list --verbose; press_enter ;;
        12) openclaw skills check; press_enter ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 模型管理菜单 ---------------
menu_models() {
    while true; do
        print_banner
        header "模型管理"

        echo -e "  ${BOLD} 1)${NC}  查看模型状态"
        echo -e "  ${BOLD} 2)${NC}  列出可用模型"
        echo -e "  ${BOLD} 3)${NC}  列出所有模型 (含本地)"
        echo -e "  ${BOLD} 4)${NC}  设置默认模型"
        echo -e "  ${BOLD} 5)${NC}  设置默认图像模型"
        echo -e "  ${BOLD} 6)${NC}  扫描可用模型"
        echo -e "  ${BOLD} 7)${NC}  添加认证 (交互式)"
        echo -e "  ${BOLD} 8)${NC}  Anthropic setup-token"
        echo -e "  ${BOLD} 9)${NC}  粘贴 token"
        echo -e "  ${BOLD}10)${NC}  管理模型别名"
        echo -e "  ${BOLD}11)${NC}  管理回退模型"
        echo -e "  ${BOLD}12)${NC}  模型状态探测"
        echo ""
        echo -e "  ${DIM} 0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-12]: " choice

        case $choice in
        1)  openclaw models status; press_enter ;;
        2)  openclaw models list; press_enter ;;
        3)  openclaw models list --all; press_enter ;;
        4)
            read -rp "  模型 ID: " mid
            [[ -n "$mid" ]] && openclaw models set "$mid" && success "默认模型已设置"
            press_enter
            ;;
        5)
            read -rp "  图像模型 ID: " mid
            [[ -n "$mid" ]] && openclaw models set-image "$mid" && success "默认图像模型已设置"
            press_enter
            ;;
        6)  openclaw models scan; press_enter ;;
        7)  openclaw models auth add; press_enter ;;
        8)  openclaw models auth setup-token --provider anthropic; press_enter ;;
        9)
            read -rp "  提供商 (如 anthropic/openai): " provider
            openclaw models auth paste-token --provider "${provider:-anthropic}"
            press_enter
            ;;
        10) menu_model_aliases ;;
        11) menu_model_fallbacks ;;
        12) openclaw models status --probe; press_enter ;;
        0)  return ;;
        *)  warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_model_aliases() {
    while true; do
        print_banner
        header "模型别名管理"

        echo -e "  ${BOLD}1)${NC}  列出别名"
        echo -e "  ${BOLD}2)${NC}  添加别名"
        echo -e "  ${BOLD}3)${NC}  移除别名"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-3]: " choice

        case $choice in
        1) openclaw models aliases list; press_enter ;;
        2)
            read -rp "  别名: " alias
            read -rp "  模型 ID: " model
            [[ -n "$alias" && -n "$model" ]] && openclaw models aliases add "$alias" "$model"
            press_enter
            ;;
        3)
            read -rp "  别名: " alias
            [[ -n "$alias" ]] && openclaw models aliases remove "$alias"
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

menu_model_fallbacks() {
    while true; do
        print_banner
        header "回退模型管理"

        echo -e "  ${BOLD}1)${NC}  列出文本回退模型"
        echo -e "  ${BOLD}2)${NC}  添加文本回退模型"
        echo -e "  ${BOLD}3)${NC}  移除文本回退模型"
        echo -e "  ${BOLD}4)${NC}  清除所有文本回退"
        echo -e "  ${BOLD}5)${NC}  列出图像回退模型"
        echo -e "  ${BOLD}6)${NC}  添加图像回退模型"
        echo -e "  ${BOLD}7)${NC}  移除图像回退模型"
        echo -e "  ${BOLD}8)${NC}  清除所有图像回退"
        echo ""
        echo -e "  ${DIM}0)  返回上一级${NC}"
        echo ""
        read -rp "  请选择 [0-8]: " choice

        case $choice in
        1) openclaw models fallbacks list; press_enter ;;
        2)
            read -rp "  模型 ID: " mid
            [[ -n "$mid" ]] && openclaw models fallbacks add "$mid"
            press_enter
            ;;
        3)
            read -rp "  模型 ID: " mid
            [[ -n "$mid" ]] && openclaw models fallbacks remove "$mid"
            press_enter
            ;;
        4) openclaw models fallbacks clear; press_enter ;;
        5) openclaw models image-fallbacks list; press_enter ;;
        6)
            read -rp "  图像模型 ID: " mid
            [[ -n "$mid" ]] && openclaw models image-fallbacks add "$mid"
            press_enter
            ;;
        7)
            read -rp "  图像模型 ID: " mid
            [[ -n "$mid" ]] && openclaw models image-fallbacks remove "$mid"
            press_enter
            ;;
        8) openclaw models image-fallbacks clear; press_enter ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 智能体管理菜单 ---------------
menu_agents() {
    while true; do
        print_banner
        header "智能体管理"

        echo -e "  ${BOLD}1)${NC}  列出智能体"
        echo -e "  ${BOLD}2)${NC}  添加智能体"
        echo -e "  ${BOLD}3)${NC}  删除智能体"
        echo -e "  ${BOLD}4)${NC}  查看路由绑定"
        echo -e "  ${BOLD}5)${NC}  添加路由绑定"
        echo -e "  ${BOLD}6)${NC}  移除路由绑定"
        echo -e "  ${BOLD}7)${NC}  发送消息 (agent)"
        echo -e "  ${BOLD}8)${NC}  发送消息 (message)"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-8]: " choice

        case $choice in
        1) openclaw agents list; press_enter ;;
        2) openclaw agents add; press_enter ;;
        3)
            read -rp "  智能体 ID: " aid
            if [[ -n "$aid" ]] && confirm "确认删除智能体 $aid?"; then
                openclaw agents delete "$aid" --force
            fi
            press_enter
            ;;
        4) openclaw agents bindings; press_enter ;;
        5)
            read -rp "  智能体 ID: " aid
            read -rp "  绑定 (如 telegram:default): " bind
            [[ -n "$aid" && -n "$bind" ]] && openclaw agents bind --agent "$aid" --bind "$bind"
            press_enter
            ;;
        6)
            read -rp "  智能体 ID: " aid
            read -rp "  绑定: " bind
            [[ -n "$aid" && -n "$bind" ]] && openclaw agents unbind --agent "$aid" --bind "$bind"
            press_enter
            ;;
        7)
            read -rp "  消息内容: " msg
            [[ -n "$msg" ]] && openclaw agent --message "$msg"
            press_enter
            ;;
        8)
            read -rp "  目标 (如 +15555550123): " target
            read -rp "  消息内容: " msg
            [[ -n "$target" && -n "$msg" ]] && openclaw message send --target "$target" --message "$msg"
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 更新与卸载菜单 ---------------
menu_update_uninstall() {
    while true; do
        print_banner
        header "更新与卸载"

        echo -e "  ${GREEN}${BOLD}── 更新 ──${NC}"
        echo -e "  ${BOLD}1)${NC}  更新 OpenClaw"
        echo -e "  ${BOLD}2)${NC}  更新 OpenClaw (npm)"
        echo ""
        echo -e "  ${YELLOW}${BOLD}── 重置 ──${NC}"
        echo -e "  ${BOLD}3)${NC}  重置配置"
        echo -e "  ${BOLD}4)${NC}  重置配置+凭据+会话"
        echo -e "  ${BOLD}5)${NC}  完全重置 (含工作区)"
        echo ""
        echo -e "  ${RED}${BOLD}── 卸载 ──${NC}"
        echo -e "  ${BOLD}6)${NC}  卸载网关服务+数据"
        echo -e "  ${BOLD}7)${NC}  完全卸载 (保留 CLI)"
        echo -e "  ${BOLD}8)${NC}  完全卸载 + 移除 CLI"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-8]: " choice

        case $choice in
        1) openclaw update; press_enter ;;
        2)
            npm install -g openclaw@latest
            success "已通过 npm 更新到最新版本"
            press_enter
            ;;
        3)
            if confirm "确认重置配置?"; then
                openclaw reset --scope config --yes
                success "配置已重置"
            fi
            press_enter
            ;;
        4)
            if confirm "确认重置配置+凭据+会话?"; then
                openclaw reset --scope config+creds+sessions --yes
                success "已重置"
            fi
            press_enter
            ;;
        5)
            warn "此操作将删除工作区数据！"
            if confirm "确认完全重置?"; then
                openclaw reset --scope full --yes
                success "完全重置完成"
            fi
            press_enter
            ;;
        6)
            if confirm "确认卸载网关服务和状态数据?"; then
                openclaw uninstall --service --state --yes
                success "网关服务和数据已卸载"
            fi
            press_enter
            ;;
        7)
            warn "将卸载所有数据，但保留 openclaw CLI 命令"
            if confirm "确认完全卸载?"; then
                openclaw uninstall --all --yes
                success "卸载完成 (CLI 仍可用)"
            fi
            press_enter
            ;;
        8)
            warn "将彻底移除 OpenClaw 及其所有数据！"
            if confirm "最终确认: 彻底卸载?"; then
                openclaw uninstall --all --yes
                npm uninstall -g openclaw 2>/dev/null || true
                success "OpenClaw 已彻底卸载"
            fi
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 快捷操作菜单 ---------------
menu_quick() {
    while true; do
        print_banner
        header "快捷操作"

        echo -e "  ${BOLD}1)${NC}  一键状态总览 (status + health + channels)"
        echo -e "  ${BOLD}2)${NC}  一键诊断 (doctor + security audit)"
        echo -e "  ${BOLD}3)${NC}  打开 TUI 终端界面"
        echo -e "  ${BOLD}4)${NC}  打开浏览器仪表盘"
        echo -e "  ${BOLD}5)${NC}  搜索文档"
        echo -e "  ${BOLD}6)${NC}  查看 OpenClaw 版本"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -rp "  请选择 [0-6]: " choice

        case $choice in
        1)
            header "状态总览"
            echo -e "${CYAN}── openclaw status ──${NC}"
            openclaw status 2>/dev/null || true
            echo ""
            echo -e "${CYAN}── openclaw health ──${NC}"
            openclaw health 2>/dev/null || true
            echo ""
            echo -e "${CYAN}── openclaw channels status ──${NC}"
            openclaw channels status 2>/dev/null || true
            press_enter
            ;;
        2)
            header "全面诊断"
            echo -e "${CYAN}── openclaw doctor ──${NC}"
            openclaw doctor 2>/dev/null || true
            echo ""
            echo -e "${CYAN}── openclaw security audit ──${NC}"
            openclaw security audit 2>/dev/null || true
            press_enter
            ;;
        3) openclaw tui; press_enter ;;
        4) openclaw dashboard ;;
        5)
            read -rp "  搜索关键词: " query
            [[ -n "$query" ]] && openclaw docs "$query"
            press_enter
            ;;
        6)
            openclaw --version
            press_enter
            ;;
        0) return ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 主菜单 ---------------
main_menu() {
    while true; do
        print_banner

        # 状态指示
        if check_openclaw; then
            local ver
            ver=$(openclaw --version 2>/dev/null || echo "?")
            echo -e "  ${GREEN}●${NC} OpenClaw ${DIM}$ver${NC}"
        else
            echo -e "  ${RED}●${NC} OpenClaw ${DIM}未安装${NC}"
        fi
        if check_node; then
            echo -e "  ${GREEN}●${NC} Node.js  ${DIM}v${NODE_VERSION}${NC}"
        else
            echo -e "  ${RED}●${NC} Node.js  ${DIM}未安装${NC}"
        fi
        echo ""

        echo -e "  ${BOLD}1)${NC}  🔍  环境检查与准备"
        echo -e "  ${BOLD}2)${NC}  📦  安装 OpenClaw"
        echo -e "  ${BOLD}3)${NC}  ⚙️   配置管理"
        echo -e "  ${BOLD}4)${NC}  🔧  日常维护"
        echo -e "  ${BOLD}5)${NC}  📡  渠道管理"
        echo -e "  ${BOLD}6)${NC}  🧩  插件管理 (含飞书)"
        echo -e "  ${BOLD}7)${NC}  🤖  模型管理"
        echo -e "  ${BOLD}8)${NC}  🤝  智能体管理"
        echo -e "  ${BOLD}9)${NC}  🔄  更新与卸载"
        echo -e "  ${BOLD}0)${NC}  ⚡  快捷操作"
        echo ""
        echo -e "  ${DIM}q)  退出脚本${NC}"
        echo ""
        read -rp "  请选择 [0-9/q]: " choice

        case $choice in
        1) menu_env_check ;;
        2) menu_install ;;
        3) menu_config ;;
        4) menu_maintain ;;
        5) menu_channels ;;
        6) menu_plugins ;;
        7) menu_models ;;
        8) menu_agents ;;
        9) menu_update_uninstall ;;
        0) menu_quick ;;
        q|Q)
            echo ""
            info "再见！"
            exit 0
            ;;
        *) warn "无效选项" && sleep 1 ;;
        esac
    done
}

# --------------- 入口 ---------------
detect_os
detect_china
check_node 2>/dev/null || true
main_menu
