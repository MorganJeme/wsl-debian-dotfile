#!/bin/bash

# ==============================================================================
#                 🚀 Your Personal Dev Env Setup (Mise Edition) 🚀
#
# 该脚本用于在全新的 WSL-Debian 环境中，一键自动化配置你的专属开发环境。
# Now powered by mise for ultimate speed and convenience!
# Designed with love for my dear friend. ❤️
# ==============================================================================

# --- 安全检查与环境准备 (Safety Checks & Preparation) ---

# 设定脚本出错时立即退出
set -e

# 定义彩色输出，让脚本交互更友好
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'

# 封装一个漂亮的日志函数
log_info() {
  echo -e "${C_BLUE}INFO: $1${C_RESET}"
}
log_success() {
  echo -e "${C_GREEN}SUCCESS: $1${C_RESET}"
}
log_warn() {
  echo -e "${C_YELLOW}WARN: $1${C_RESET}"
}
log_error() {
  echo -e "${C_RED}ERROR: $1${C_RESET}"
  exit 1
}

# 1. 权限检查：禁止 root 用户执行
if [[ "$EUID" -eq 0 ]]; then
  log_error "请不要使用 root 用户执行此脚本。请切换到你的普通用户账户下运行。"
fi

# 2. 提前获取 sudo 权限：一次性输入密码，全程无阻
log_info "接下来需要获取管理员权限 (sudo) 来安装软件包，请输入你的密码。"
if ! sudo -v; then
    log_error "获取 sudo 权限失败，请检查你的密码。"
fi
# 保持 sudo 权限在后台激活
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


# 3. 交互式获取代理地址
log_info "请输入你的 HTTP/HTTPS 代理地址 (例如: http://172.21.240.1:12334)。如果不需要代理，请直接回车。"
read -p "Proxy URL: " PROXY_URL

if [[ -n "$PROXY_URL" ]]; then
    # 为当前脚本会话设置代理环境变量
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    # 为 apt 配置代理参数
    APT_PROXY_OPTS="-o Acquire::http::proxy=\"$PROXY_URL\" -o Acquire::https::proxy=\"$PROXY_URL\""
    log_success "代理已设置为: $PROXY_URL"
else
    APT_PROXY_OPTS=""
    log_warn "未设置代理，将直接连接网络。"
fi


# --- 核心安装流程 (Core Installation Process) ---

# 函数：检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 1. 更新系统并安装基础依赖
log_info "第一步：更新系统软件包并安装基础依赖 (git, curl, zsh, vim)..."
# 添加了 ca-certificates 以支持 https
sudo apt ${APT_PROXY_OPTS} update
sudo apt ${APT_PROXY_OPTS} install -y git curl zsh vim build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python3-openssl ca-certificates

log_success "系统更新和基础依赖安装完成。"


# 2. Oh My Zsh 安装与配置 (与之前相同)
OMZ_DIR="$HOME/.oh-my-zsh"
log_info "第二步：安装 Oh My Zsh..."
if [ -d "$OMZ_DIR" ]; then
  log_warn "Oh My Zsh 已安装，跳过。"
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER"
    log_success "已将 Zsh 设置为你的默认 Shell。请注意，你需要重新登录才能完全生效。"
  fi
  log_success "Oh My Zsh 安装完成。"
fi


# 3. Zsh 主题和插件安装 (与之前相同)
ZSH_CUSTOM="$OMZ_DIR/custom"
# ... (这部分完全不变，为了简洁我省略了，请直接使用你原脚本中的内容)
# 安装 Powerlevel10k 主题
P10K_DIR="${ZSH_CUSTOM}/themes/powerlevel10k"
log_info "第三步：安装 Powerlevel10k 主题..."
if [ -d "$P10K_DIR" ]; then
  log_warn "Powerlevel10k 主题已安装，跳过。"
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  log_success "Powerlevel10k 主题下载完成。"
fi

# 安装 zsh-autosuggestions 插件
AUTOSUGG_DIR="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
log_info "第四步：安装 zsh-autosuggestions 插件..."
if [ -d "$AUTOSUGG_DIR" ]; then
  log_warn "zsh-autosuggestions 插件已安装，跳过。"
else
  git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGG_DIR"
  log_success "zsh-autosuggestions 插件下载完成。"
fi

# 安装 zsh-syntax-highlighting 插件
SYNTAX_DIR="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
log_info "第五步：安装 zsh-syntax-highlighting 插件..."
if [ -d "$SYNTAX_DIR" ]; then
  log_warn "zsh-syntax-highlighting 插件已安装，跳过。"
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_DIR"
  log_success "zsh-syntax-highlighting 插件下载完成。"
fi

# 6. 配置 NPM 全局环境
log_info "第六步：配置 NPM 全局安装路径..."
NPM_GLOBAL_DIR="$HOME/.npm-global"
if [ -d "$NPM_GLOBAL_DIR" ]; then
    log_warn "NPM 全局目录 (~/.npm-global) 已存在，跳过创建。"
else
    mkdir -p "$NPM_GLOBAL_DIR"
    log_success "已创建 NPM 全局目录: $NPM_GLOBAL_DIR"
fi

# 4. 【心脏移植手术】安装 mise 多版本管理器
log_info "第七步：安装高性能版本管理器 mise..."
if command_exists mise; then
  log_warn "mise 已安装，跳过。"
else
  # 使用官方推荐的安装脚本，它会自动处理架构和最新版本
  curl -fsSL https://mise.run | sh
  # 将 mise 的路径添加到当前会话的 PATH 中，以便后续步骤可以立即使用
  export PATH="$HOME/.local/bin:$PATH"
  log_success "mise 安装完成。"
fi


# --- 最终配置 (Final Configuration) ---

log_info "第八步：链接配置文件..."
# 获取脚本所在的目录，从而定位到整个 dotfiles 项目的根目录
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 链接 .zshrc
ln -sf "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
log_success "已链接 .zshrc"

# 链接 .p10k.zsh
ln -sf "${DOTFILES_DIR}/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
log_success "已链接 .p10k.zsh"

# 链接 .gitconfig
ln -sf "${DOTFILES_DIR}/git/.gitconfig" "$HOME/.gitconfig"
log_success "已链接 .gitconfig"

# 链接 .npmrc
# 注意：npm 的配置文件在家目录，而不是在 .config 目录
ln -sf "${DOTFILES_DIR}/npm/.npmrc" "$HOME/.npmrc"
log_success "已链接 .npmrc"

# 【升级改造】链接 mise 的全局配置文件
# 我们不再使用 .tool-versions，而是 mise 更强大的 .mise.toml
# 同时，我们也把全局配置目录链接起来，便于管理
ln -sf "${DOTFILES_DIR}/mise/config.toml" "$HOME/.config/mise/config.toml"
log_success "已链接 mise 全局配置文件 (config.toml)"


# --- 结束语 (Conclusion) ---
echo
echo -e "${C_PURPLE}===============================================================${C_RESET}"
echo -e "${C_GREEN}🚀 All Done! 你的专属开发环境已成功升级至 mise 核心！ 🚀${C_RESET}"
echo -e "${C_PURPLE}===============================================================${C_RESET}"
echo
echo -e "${C_YELLOW}重要提示:${C_RESET}"
echo -e "1. 请 ${C_RED}完全关闭并重新打开${C_RESET} 你的 WSL 终端来加载所有新配置。"
echo -e "2. mise 会在你第一次进入含有 ${C_GREEN}.tool-versions${C_RESET} 或 ${C_GREEN}.mise.toml${C_RESET} 的项目目录时，"
echo -e "   ${C_YELLOW}自动提示并安装${C_RESET} 所需的工具版本，体验非常智能！"
echo -e "3. 如果你想立即安装全局工具，请在新终端中运行: ${C_GREEN}mise install${C_RESET}"
echo -e "4. 别忘了在 Windows Terminal 中设置字体为 ${C_GREEN}MesloLGM NF${C_RESET} 以获得最佳视觉效果。"
echo
echo "享受 mise 带来的极致速度和丝滑体验吧，我的朋友！❤️"
