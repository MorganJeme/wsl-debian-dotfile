#!/bin/bash

# ==============================================================================
#                      🔄 Your Personal Dev Env Updater (v2) 🔄
#
# 该脚本用于一键更新你的整个开发环境，包括系统包、Shell、插件和版本管理器。
# Now with robust plugin updates and authenticated API access!
# Designed with love for my dear friend. ❤️
# ==============================================================================

# --- 准备工作 (Preparation) ---
set -e
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'

log_info() { echo -e "\n${C_BLUE}➡️  $1${C_RESET}"; }
log_success() { echo -e "${C_GREEN}✅ SUCCESS: $1${C_RESET}"; }
log_warn() { echo -e "${C_YELLOW}⚠️  WARN: $1${C_RESET}"; }

# --- 更新流程 (Update Process) ---

# 1. 交互式获取代理和 GitHub Token
log_info "请输入你的 HTTP/HTTPS 代理地址 (如果需要的话)。"
read -p "Proxy URL (回车跳过): " PROXY_URL

log_info "请输入你的 GitHub Personal Access Token (PAT)。"
log_info "这将用于提高 API 速率限制，避免 403 错误。Token 不会被存储在脚本中。"
read -s -p "GitHub PAT (输入时不可见，回车确认): " GITHUB_TOKEN
echo

if [[ -n "$PROXY_URL" ]]; then
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    APT_PROXY_OPTS="-o Acquire::http::proxy=\"$PROXY_URL\" -o Acquire::https::proxy=\"$PROXY_URL\""
    log_success "代理已设置。"
else
    APT_PROXY_OPTS=""
    log_warn "未设置代理。"
fi

if [[ -n "$GITHUB_TOKEN" ]]; then
    export GITHUB_TOKEN="$GITHUB_TOKEN"
    log_success "GitHub Token 已设置，将用于认证 API 请求。"
else
    log_warn "未输入 GitHub Token，可能会遇到 API 速率限制。"
fi

# 2. 更新 APT 软件包
log_info "正在更新系统 APT 软件包..."
sudo -v
sudo apt ${APT_PROXY_OPTS} update && sudo apt ${APT_PROXY_OPTS} upgrade -y
sudo apt ${APT_PROXY_OPTS} autoremove -y
log_success "APT 软件包已更新至最新。"

# 3. 更新 Oh My Zsh 核心
log_info "正在更新 Oh My Zsh..."
ZSH_DIR="$HOME/.oh-my-zsh"
if [ -d "$ZSH_DIR" ]; then
    (cd "$ZSH_DIR" && git pull)
    log_success "Oh My Zsh 核心已更新。"
else
    log_warn "未找到 Oh My Zsh 安装目录，跳过。"
fi

# 4. 更新通过 Git 安装的 Zsh 插件和主题
log_info "正在更新自定义 Zsh 插件和主题..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ -d "$ZSH_CUSTOM" ]; then
    find "$ZSH_CUSTOM" -mindepth 2 -maxdepth 2 -type d -name ".git" -exec sh -c '
        dir="$(dirname "{}")";
        echo "  - 正在更新 $(basename "$dir")...";
        (cd "$dir" && git pull);
    ' \;
    log_success "所有自定义插件和主题已更新。"
else
    log_warn "未找到 Zsh 自定义目录，跳过。"
fi

# 5. 更新 mise 自身
log_info "正在更新 mise..."
if command -v mise >/dev/null 2>&1; then
    mise self-update
    log_success "mise 已更新至最新版本。"
else
    log_warn "未找到 mise 命令，跳过。"
fi

# 6. 更新 mise 的插件
log_info "正在更新 mise 的所有插件..."
if command -v mise >/dev/null 2>&1; then
    mise plugins update
    log_success "mise 插件已更新。"
else
    log_warn "未找到 mise 命令，跳过。"
fi

# --- 结束语 (Conclusion) ---
echo
echo -e "${C_PURPLE}===============================================================${C_RESET}"
echo -e "${C_GREEN}✨ All systems updated! 你的开发环境已焕然一新！ ✨${C_RESET}"
echo -e "${C_PURPLE}===============================================================${C_RESET}"
echo
echo "享受最新的工具带来的极致体验吧！❤️"
