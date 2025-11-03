#!/bin/bash
# CoreMark 一键运行脚本 - 狗点饭 NAS 性能跑分
# 使用方法: bash <(curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh)

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO_URL="https://github.com/huladabang/coremark-goufan"
DOWNLOAD_BASE="${REPO_URL}/releases/latest/download"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  狗点饭 NAS CoreMark 跑分工具${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 检测架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armhf)
            echo "armv7"
            ;;
        *)
            echo -e "${RED}错误: 不支持的架构 $arch${NC}" >&2
            exit 1
            ;;
    esac
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo -e "${RED}错误: 目前仅支持 Linux 系统${NC}" >&2
        exit 1
    fi
}

# 获取CPU信息
get_cpu_info() {
    if [ -f /proc/cpuinfo ]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2 | sed 's/^[ \t]*//')
        local cpu_cores=$(nproc)
        echo -e "${GREEN}CPU 型号:${NC} $cpu_model"
        echo -e "${GREEN}CPU 核心数:${NC} $cpu_cores"
    fi
}

# 下载二进制文件
download_coremark() {
    local arch=$1
    local binary_name="coremark_${arch}"
    local download_url="${DOWNLOAD_BASE}/${binary_name}"
    
    echo -e "\n${YELLOW}正在下载 CoreMark ($arch)...${NC}"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$binary_name" "$download_url" || {
            echo -e "${RED}下载失败!${NC}" >&2
            exit 1
        }
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$binary_name" "$download_url" || {
            echo -e "${RED}下载失败!${NC}" >&2
            exit 1
        }
    else
        echo -e "${RED}错误: 需要 wget 或 curl 来下载文件${NC}" >&2
        exit 1
    fi
    
    chmod +x "$binary_name"
    echo -e "${GREEN}下载完成!${NC}\n"
    echo "$binary_name"
}

# 运行 CoreMark
run_coremark() {
    local binary=$1
    local iterations=${2:-0}
    
    echo -e "${YELLOW}正在运行 CoreMark 跑分...${NC}"
    echo -e "${YELLOW}这可能需要几分钟时间，请耐心等待...${NC}\n"
    
    # 运行性能测试
    ./"$binary" 0x0 0x0 0x66 $iterations 7 1 2000 > coremark_result.log
    
    # 提取分数
    local score=$(grep "CoreMark 1.0" coremark_result.log | grep -oP "CoreMark 1.0 : \K[0-9.]+")
    local iterations_done=$(grep "Iterations" coremark_result.log | grep -oP "Iterations\s*:\s*\K[0-9]+")
    local total_time=$(grep "Total time" coremark_result.log | grep -oP "Total time \(secs\)\s*:\s*\K[0-9.]+")
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}       CoreMark 跑分结果${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}分数:${NC} ${BLUE}$score${NC} CoreMark/MHz"
    echo -e "${GREEN}迭代次数:${NC} $iterations_done"
    echo -e "${GREEN}总耗时:${NC} $total_time 秒"
    echo -e "${GREEN}========================================${NC}\n"
    
    # 显示完整结果
    echo -e "${YELLOW}完整跑分结果:${NC}"
    cat coremark_result.log
    
    echo -e "\n${BLUE}结果已保存到: coremark_result.log${NC}"
}

# 提交结果提示
submit_result() {
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  想要提交你的跑分结果？${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "访问 ${BLUE}https://gou.fan${NC} 提交你的跑分数据"
    echo -e "帮助我们完善 NAS 性能排行榜！\n"
}

# 清理临时文件
cleanup() {
    if [ -n "$TEMP_BINARY" ] && [ -f "$TEMP_BINARY" ]; then
        echo -e "${YELLOW}清理临时文件...${NC}"
        rm -f "$TEMP_BINARY" coremark_result.log
    fi
}

# 主函数
main() {
    # 显示系统信息
    echo -e "${GREEN}检测系统信息...${NC}"
    local os=$(detect_os)
    local arch=$(detect_arch)
    echo -e "${GREEN}操作系统:${NC} $os"
    echo -e "${GREEN}架构:${NC} $arch"
    get_cpu_info
    
    # 下载二进制文件
    TEMP_BINARY=$(download_coremark "$arch")
    
    # 运行跑分
    run_coremark "$TEMP_BINARY" 0
    
    # 提交结果提示
    submit_result
    
    # 询问是否保留文件
    echo -e -n "${YELLOW}是否保留 CoreMark 二进制文件和结果？(y/N) ${NC}"
    read -r keep_files
    if [[ ! "$keep_files" =~ ^[Yy]$ ]]; then
        cleanup
        echo -e "${GREEN}清理完成!${NC}"
    else
        echo -e "${GREEN}文件已保留: $TEMP_BINARY, coremark_result.log${NC}"
    fi
    
    echo -e "\n${BLUE}感谢使用狗点饭 CoreMark 跑分工具！${NC}"
}

# 捕获退出信号，确保清理
trap cleanup EXIT INT TERM

# 运行主函数
main

