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

# 备用下载源（狗点饭镜像，国内用户优先使用）
MIRROR_BASE="https://gou.fan/coremark/releases/latest/download"

# 检测是否在国内
is_in_china() {
    # 简单检测：尝试访问 GitHub 是否超时
    if command -v curl >/dev/null 2>&1; then
        if ! curl -s --connect-timeout 3 -I https://github.com >/dev/null 2>&1; then
            return 0  # 无法访问，可能在国内
        fi
    fi
    return 1  # 可以访问
}

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

# 查找可执行目录
find_executable_dir() {
    # 定义各品牌 NAS 可能的可执行目录
    local test_dirs=(
        # 群晖 (Synology DSM)
        "/volume1/@tmp"
        "/volume2/@tmp"
        "/volumeUSB1/usbshare"
        # 威联通 (QNAP QTS)
        "/share/CACHEDEV1_DATA/.qpkg"
        "/share/CACHEDEV1_DATA/temp"
        "/mnt/HDA_ROOT/.tmp"
        # 通用 Linux 目录
        "/var/tmp"
        "/opt/tmp"
        "/usr/tmp"
        # 用户目录
        "$HOME"
        "$HOME/tmp"
        # 最后尝试 /tmp（可能有 noexec）
        "/tmp"
    )
    
    for dir in "${test_dirs[@]}"; do
        # 跳过空路径
        [ -z "$dir" ] && continue
        
        # 检查目录是否存在且可写
        [ -d "$dir" ] && [ -w "$dir" ] || continue
        
        # 创建测试文件
        local test_file="$dir/.coremark_test_$$"
        
        # 尝试写入简单的可执行脚本
        cat > "$test_file" 2>/dev/null <<'EOF'
#!/bin/sh
exit 0
EOF
        [ $? -eq 0 ] || continue
        
        # 添加执行权限
        chmod +x "$test_file" >/dev/null 2>&1 || {
            rm -f "$test_file" >/dev/null 2>&1
            continue
        }
        
        # 测试是否真的可以执行
        if "$test_file" >/dev/null 2>&1; then
            rm -f "$test_file"
            echo "$dir"
            return 0
        fi
        
        # 清理测试文件
        rm -f "$test_file" >/dev/null 2>&1
    done
    
    # 如果都不行，返回 /tmp 作为后备（可能失败，但至少有个地方）
    echo "/tmp"
    return 1
}

# 下载二进制文件
download_coremark() {
    local arch=$1
    local binary_name="coremark_${arch}"
    
    # 选择下载源
    local download_url
    local source_name
    if is_in_china; then
        echo -e "${YELLOW}检测到可能在国内网络环境，使用镜像源...${NC}" >&2
        download_url="${MIRROR_BASE}/${binary_name}"
        source_name="狗点饭镜像"
    else
        download_url="${DOWNLOAD_BASE}/${binary_name}"
        source_name="GitHub"
    fi
    
    # 查找可执行目录
    local work_dir=$(find_executable_dir)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 找到可执行目录: ${NC}$work_dir" >&2
    else
        echo -e "${RED}========================================${NC}" >&2
        echo -e "${RED}  警告：无法找到可执行目录${NC}" >&2
        echo -e "${RED}========================================${NC}" >&2
        echo -e "${YELLOW}你的系统可能限制了程序执行。${NC}" >&2
        echo -e "${YELLOW}请尝试以下手动操作：${NC}\n" >&2
        echo -e "  ${BLUE}1. 下载二进制文件：${NC}" >&2
        echo -e "     wget $download_url\n" >&2
        echo -e "  ${BLUE}2. 找到可写且可执行的目录，例如：${NC}" >&2
        echo -e "     cd /volume1/@tmp      ${GREEN}# 群晖${NC}" >&2
        echo -e "     cd /share/CACHEDEV1_DATA/temp  ${GREEN}# 威联通${NC}" >&2
        echo -e "     cd /var/tmp           ${GREEN}# 通用${NC}\n" >&2
        echo -e "  ${BLUE}3. 移动文件并运行：${NC}" >&2
        echo -e "     mv ~/$binary_name ." >&2
        echo -e "     chmod +x $binary_name" >&2
        echo -e "     ./$binary_name 0x0 0x0 0x66 0 7 1 2000\n" >&2
        echo -e "${YELLOW}尝试继续使用: $work_dir${NC}\n" >&2
    fi
    
    # 切换到工作目录
    cd "$work_dir" || {
        echo -e "${RED}无法进入工作目录: $work_dir${NC}" >&2
        echo -e "${YELLOW}提示: 请检查目录是否存在并有写入权限${NC}" >&2
        exit 1
    }
    
    echo -e "\n${YELLOW}正在从 ${source_name} 下载 CoreMark ($arch)...${NC}" >&2
    
    # 定义下载函数
    download_file() {
        local url=$1
        local output=$2
        if command -v wget >/dev/null 2>&1; then
            wget -q --show-progress -O "$output" "$url" 2>&1
        elif command -v curl >/dev/null 2>&1; then
            curl -L --progress-bar -o "$output" "$url" 2>&1
        else
            return 1
        fi
    }
    
    # 尝试下载
    if ! download_file "$download_url" "$binary_name"; then
        echo -e "${YELLOW}下载失败，尝试备用源...${NC}" >&2
        
        # 切换到备用源
        if [ "$source_name" = "狗点饭镜像" ]; then
            download_url="${DOWNLOAD_BASE}/${binary_name}"
            source_name="GitHub"
        else
            download_url="${MIRROR_BASE}/${binary_name}"
            source_name="狗点饭镜像"
        fi
        
        echo -e "${YELLOW}正在从 ${source_name} 下载...${NC}" >&2
        
        if ! download_file "$download_url" "$binary_name"; then
            echo -e "${RED}========================================${NC}" >&2
            echo -e "${RED}  下载失败！${NC}" >&2
            echo -e "${RED}========================================${NC}" >&2
            echo -e "${YELLOW}请尝试以下手动操作：${NC}\n" >&2
            echo -e "1. 访问以下链接手动下载：" >&2
            echo -e "   ${BLUE}https://github.com/huladabang/coremark-goufan/releases/latest${NC}" >&2
            echo -e "   ${BLUE}https://coremark.gou.fan/releases/latest/download/${binary_name}${NC}\n" >&2
            echo -e "2. 或使用代理后重试" >&2
            exit 1
        fi
    fi
    
    chmod +x "$binary_name" >/dev/null 2>&1 || {
        echo -e "${YELLOW}警告: 无法设置执行权限，但会尝试运行${NC}" >&2
    }
    
    echo -e "${GREEN}下载完成!${NC}\n" >&2
    # 返回二进制文件的完整路径
    echo "$work_dir/$binary_name"
}

# 运行 CoreMark
run_coremark() {
    local binary=$1
    local iterations=${2:-0}
    
    echo -e "${YELLOW}正在运行 CoreMark 跑分...${NC}"
    echo -e "${YELLOW}这可能需要几分钟时间，请耐心等待...${NC}\n"
    
    # 检查文件是否存在
    if [ ! -f "$binary" ]; then
        echo -e "${RED}错误: 找不到二进制文件 $binary${NC}" >&2
        exit 1
    fi
    
    # 检查是否有执行权限
    if [ ! -x "$binary" ]; then
        echo -e "${YELLOW}警告: 文件没有执行权限，尝试添加...${NC}"
        chmod +x "$binary" >/dev/null 2>&1 || {
            echo -e "${RED}无法添加执行权限${NC}" >&2
        }
    fi
    
    # 尝试运行性能测试
    if ! "$binary" 0x0 0x0 0x66 $iterations 7 1 2000 > coremark_result.log 2>&1; then
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  运行失败！${NC}"
        echo -e "${RED}========================================${NC}"
        
        # 检查是否是权限问题
        if grep -qi "permission denied" coremark_result.log >/dev/null 2>&1; then
            echo -e "${YELLOW}可能是文件系统挂载为 noexec（禁止执行）${NC}\n"
            echo -e "${BLUE}请尝试以下操作：${NC}"
            echo -e "1. 找到一个允许执行的目录："
            echo -e "   ${GREEN}群晖:${NC} cd /volume1/@tmp"
            echo -e "   ${GREEN}威联通:${NC} cd /share/CACHEDEV1_DATA/temp"
            echo -e "   ${GREEN}其他:${NC} cd /var/tmp 或 cd ~\n"
            echo -e "2. 重新下载并运行："
            echo -e "   ${BLUE}wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_$(detect_arch)${NC}"
            echo -e "   ${BLUE}chmod +x coremark_$(detect_arch)${NC}"
            echo -e "   ${BLUE}./coremark_$(detect_arch) 0x0 0x0 0x66 0 7 1 2000${NC}\n"
        else
            echo -e "${YELLOW}错误信息：${NC}"
            cat coremark_result.log
        fi
        
        exit 1
    fi
    
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

