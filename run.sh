#!/bin/sh
# CoreMark 一键运行脚本 - 狗点饭 NAS 性能跑分
# 使用方法: curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh | sh

set -e

# 颜色输出（柔和配色）
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
CYAN='\033[0;96m'
NC='\033[0m'

# 配置
REPO_URL="https://github.com/huladabang/coremark-goufan"
DOWNLOAD_BASE="${REPO_URL}/releases/latest/download"
MIRROR_BASE="https://gou.fan/coremark/releases/latest/download"

# 检测是否在国内
is_in_china() {
    # 尝试访问 GitHub，如果失败则可能在国内
    if which curl >/dev/null 2>&1 || type curl >/dev/null 2>&1; then
        if ! curl -s --connect-timeout 3 -I https://github.com >/dev/null 2>&1; then
            return 0
        fi
    elif which wget >/dev/null 2>&1 || type wget >/dev/null 2>&1; then
        if ! wget -q --spider --timeout=3 https://github.com >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

printf "${BLUE}========================================${NC}\n"
printf "${BLUE}  狗点饭 NAS CoreMark 跑分工具${NC}\n"
printf "${BLUE}========================================${NC}\n\n"

# 检测架构
detect_arch() {
    arch=$(uname -m)
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
            printf "${RED}错误: 不支持的架构 $arch${NC}\n" >&2
            exit 1
            ;;
    esac
}

# 检测操作系统
detect_os() {
    if [ "$(uname -s)" = "Linux" ]; then
        echo "linux"
    else
        printf "${RED}错误: 目前仅支持 Linux 系统${NC}\n" >&2
        exit 1
    fi
}

# 获取CPU信息
get_cpu_info() {
    if [ -f /proc/cpuinfo ]; then
        cpu_model=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2 | sed 's/^[ \t]*//')
        cpu_cores=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)
        printf "${GREEN}CPU 型号:${NC} %s\n" "$cpu_model"
        printf "${GREEN}CPU 核心数:${NC} %s\n" "$cpu_cores"
    fi
}

# 查找可执行目录
find_executable_dir() {
    # 使用空格分隔的字符串代替数组
    test_dirs="/volume1/@tmp /volume2/@tmp /volumeUSB1/usbshare /share/CACHEDEV1_DATA/.qpkg /share/CACHEDEV1_DATA/temp /mnt/HDA_ROOT/.tmp /var/tmp /opt/tmp /usr/tmp $HOME $HOME/tmp /tmp"
    
    for dir in $test_dirs; do
        [ -z "$dir" ] && continue
        [ -d "$dir" ] && [ -w "$dir" ] || continue
        
        test_file="$dir/.coremark_test_$$"
        
        cat > "$test_file" 2>/dev/null <<'EOF'
#!/bin/sh
exit 0
EOF
        [ $? -eq 0 ] || continue
        
        chmod +x "$test_file" >/dev/null 2>&1 || {
            rm -f "$test_file" >/dev/null 2>&1
            continue
        }
        
        if "$test_file" >/dev/null 2>&1; then
            rm -f "$test_file"
            echo "$dir"
            return 0
        fi
        
        rm -f "$test_file" >/dev/null 2>&1
    done
    
    echo "/tmp"
    return 1
}

# 下载二进制文件
download_coremark() {
    arch=$1
    binary_name="coremark_${arch}"
    
    if is_in_china; then
        printf "${YELLOW}检测到可能在国内网络环境，使用镜像源...${NC}\n" >&2
        download_url="${MIRROR_BASE}/${binary_name}"
        source_name="狗点饭镜像"
    else
        download_url="${DOWNLOAD_BASE}/${binary_name}"
        source_name="GitHub"
    fi
    
    work_dir=$(find_executable_dir)
    if [ $? -eq 0 ]; then
        printf "${GREEN}✓ 找到可执行目录: ${NC}%s\n" "$work_dir" >&2
    else
        printf "${RED}========================================${NC}\n" >&2
        printf "${RED} 警告：无法找到可执行目录${NC}\n" >&2
        printf "${RED}========================================${NC}\n" >&2
        printf "${YELLOW}你的系统可能限制了程序执行。${NC}\n" >&2
        printf "${YELLOW}请尝试以下手动操作：${NC}\n\n" >&2
        printf " ${BLUE}1. 下载二进制文件：${NC}\n" >&2
        printf "   wget %s\n\n" "$download_url" >&2
        printf " ${BLUE}2. 找到可写且可执行的目录，例如：${NC}\n" >&2
        printf "   cd /volume1/@tmp ${GREEN}# 群晖${NC}\n" >&2
        printf "   cd /share/CACHEDEV1_DATA/temp ${GREEN}# 威联通${NC}\n" >&2
        printf "   cd /var/tmp ${GREEN}# 通用${NC}\n\n" >&2
        printf " ${BLUE}3. 移动文件并运行：${NC}\n" >&2
        printf "   mv ~/%s .\n" "$binary_name" >&2
        printf "   chmod +x %s\n" "$binary_name" >&2
        printf "   ./%s 0x0 0x0 0x66 0 7 1 2000\n\n" "$binary_name" >&2
        printf "${YELLOW}尝试继续使用: %s${NC}\n\n" "$work_dir" >&2
    fi
    
    cd "$work_dir" || {
        printf "${RED}无法进入工作目录: %s${NC}\n" "$work_dir" >&2
        printf "${YELLOW}提示: 请检查目录是否存在并有写入权限${NC}\n" >&2
        exit 1
    }
    
    printf "\n${YELLOW}正在从 %s 下载 CoreMark (%s)...${NC}\n" "$source_name" "$arch" >&2
    
    download_file() {
        url=$1
        output=$2
        download_success=0
        
        # 优先尝试 wget
        if which wget >/dev/null 2>&1 || type wget >/dev/null 2>&1; then
            if wget -q --show-progress -O "$output" "$url" 2>&1; then
                download_success=1
            fi
        fi
        
        # 如果 wget 失败或不存在，尝试 curl
        if [ $download_success -eq 0 ]; then
            if which curl >/dev/null 2>&1 || type curl >/dev/null 2>&1; then
                if curl -f -L --progress-bar -o "$output" "$url" 2>&1; then
                    download_success=1
                fi
            fi
        fi
        
        # 如果都失败了
        if [ $download_success -eq 0 ]; then
            printf "${RED}下载失败: 无法使用 wget 或 curl 下载文件${NC}\n" >&2
            return 1
        fi
        
        # 检查文件是否下载成功且不为空
        if [ ! -f "$output" ] || [ ! -s "$output" ]; then
            printf "${RED}下载失败: 文件为空或不存在${NC}\n" >&2
            return 1
        fi
        
        return 0
    }
    
    if ! download_file "$download_url" "$binary_name"; then
        printf "${YELLOW}下载失败，尝试备用源...${NC}\n" >&2
        
        if [ "$source_name" = "狗点饭镜像" ]; then
            download_url="${DOWNLOAD_BASE}/${binary_name}"
            source_name="GitHub"
        else
            download_url="${MIRROR_BASE}/${binary_name}"
            source_name="狗点饭镜像"
        fi
        
        printf "${YELLOW}正在从 %s 下载...${NC}\n" "$source_name" >&2
        if ! download_file "$download_url" "$binary_name"; then
            printf "${RED}========================================${NC}\n" >&2
            printf "${RED} 下载失败！${NC}\n" >&2
            printf "${RED}========================================${NC}\n" >&2
            printf "${CYAN}诊断信息：${NC}\n" >&2
            printf "  GitHub 下载地址: ${DOWNLOAD_BASE}/${binary_name}\n" >&2
            printf "  镜像下载地址: ${MIRROR_BASE}/${binary_name}\n\n" >&2
            printf "${YELLOW}请尝试手动诊断：${NC}\n\n" >&2
            printf "1. 测试网络连接：\n" >&2
            printf "   ${CYAN}curl -I https://github.com${NC}\n" >&2
            printf "   ${CYAN}curl -I https://gou.fan${NC}\n\n" >&2
            printf "2. 手动下载测试：\n" >&2
            printf "   ${CYAN}curl -I ${DOWNLOAD_BASE}/${binary_name}${NC}\n" >&2
            printf "   ${CYAN}curl -I ${MIRROR_BASE}/${binary_name}${NC}\n\n" >&2
            printf "3. 访问以下链接手动下载：\n" >&2
            printf "   ${BLUE}https://github.com/huladabang/coremark-goufan/releases/latest${NC}\n\n" >&2
            printf "4. 如果有代理，设置后重试：\n" >&2
            printf "   ${CYAN}export http_proxy=http://your-proxy:port${NC}\n" >&2
            printf "   ${CYAN}export https_proxy=http://your-proxy:port${NC}\n" >&2
            exit 1
        fi
    fi
    
    chmod +x "$binary_name" >/dev/null 2>&1 || {
        printf "${YELLOW}警告: 无法设置执行权限，但会尝试运行${NC}\n" >&2
    }
    
    printf "${GREEN}下载完成!${NC}\n\n" >&2
    echo "$work_dir/$binary_name"
}

# 运行 CoreMark
run_coremark() {
    binary=$1
    iterations=${2:-0}
    
    printf "${YELLOW}正在运行 CoreMark 跑分...${NC}\n"
    printf "${YELLOW}这可能需要几分钟时间，请耐心等待...${NC}\n\n"
    
    if [ ! -f "$binary" ]; then
        printf "${RED}错误: 找不到二进制文件 %s${NC}\n" "$binary" >&2
        exit 1
    fi
    
    if [ ! -x "$binary" ]; then
        printf "${YELLOW}警告: 文件没有执行权限，尝试添加...${NC}\n"
        chmod +x "$binary" >/dev/null 2>&1 || {
            printf "${RED}无法添加执行权限${NC}\n" >&2
        }
    fi
    
    if ! "$binary" 0x0 0x0 0x66 $iterations 7 1 2000 > coremark_result.log 2>&1; then
        printf "${RED}========================================${NC}\n"
        printf "${RED} 运行失败！${NC}\n"
        printf "${RED}========================================${NC}\n"
        
        if grep -qi "permission denied" coremark_result.log >/dev/null 2>&1; then
            printf "${YELLOW}可能是文件系统挂载为 noexec（禁止执行）${NC}\n\n"
            printf "${BLUE}请尝试以下操作：${NC}\n"
            printf "1. 找到一个允许执行的目录：\n"
            printf " ${GREEN}群晖:${NC} cd /volume1/@tmp\n"
            printf " ${GREEN}威联通:${NC} cd /share/CACHEDEV1_DATA/temp\n"
            printf " ${GREEN}其他:${NC} cd /var/tmp 或 cd ~\n\n"
            printf "2. 重新下载并运行：\n"
            arch=$(detect_arch)
            printf " ${BLUE}wget https://github.com/huladabang/coremark-goufan/releases/latest/download/coremark_%s${NC}\n" "$arch"
            printf " ${BLUE}chmod +x coremark_%s${NC}\n" "$arch"
            printf " ${BLUE}./coremark_%s 0x0 0x0 0x66 0 7 1 2000${NC}\n\n" "$arch"
        else
            printf "${YELLOW}错误信息：${NC}\n"
            cat coremark_result.log
        fi
        exit 1
    fi
    
    score=$(grep "CoreMark 1.0" coremark_result.log | grep -oE "CoreMark 1.0 : [0-9.]+" | grep -oE "[0-9.]+$")
    iterations_done=$(grep "Iterations" coremark_result.log | grep -oE "Iterations[[:space:]]*:[[:space:]]*[0-9]+" | grep -oE "[0-9]+$")
    total_time=$(grep "Total time" coremark_result.log | grep -oE "Total time \\(secs\\)[[:space:]]*:[[:space:]]*[0-9.]+" | grep -oE "[0-9.]+$")
    
    printf "\n${GREEN}========================================${NC}\n"
    printf "${GREEN} CoreMark 跑分结果${NC}\n"
    printf "${GREEN}========================================${NC}\n"
    printf "${GREEN}分数:${NC} ${BLUE}%s${NC} CoreMark/MHz\n" "$score"
    printf "${GREEN}迭代次数:${NC} %s\n" "$iterations_done"
    printf "${GREEN}总耗时:${NC} %s 秒\n" "$total_time"
    printf "${GREEN}========================================${NC}\n\n"
    
    printf "${YELLOW}完整跑分结果:${NC}\n"
    cat coremark_result.log
    printf "\n${BLUE}结果已保存到: coremark_result.log${NC}\n"
}

# 提交结果提示
submit_result() {
    printf "\n${YELLOW}========================================${NC}\n"
    printf "${YELLOW} 想要提交你的跑分结果？${NC}\n"
    printf "${YELLOW}========================================${NC}\n"
    printf "访问 ${BLUE}https://gou.fan${NC} 提交你的跑分数据\n"
    printf "帮助我们完善 NAS 性能排行榜！\n\n"
}

# 清理临时文件
cleanup() {
    if [ -n "$TEMP_BINARY" ] && [ -f "$TEMP_BINARY" ]; then
        printf "${YELLOW}清理临时文件...${NC}\n"
        rm -f "$TEMP_BINARY" coremark_result.log
    fi
}

# 主函数
main() {
    printf "${GREEN}检测系统信息...${NC}\n"
    os=$(detect_os)
    arch=$(detect_arch)
    printf "${GREEN}操作系统:${NC} %s\n" "$os"
    printf "${GREEN}架构:${NC} %s\n" "$arch"
    get_cpu_info
    
    TEMP_BINARY=$(download_coremark "$arch")
    
    run_coremark "$TEMP_BINARY" 0
    
    submit_result
    
    printf "${YELLOW}是否保留 CoreMark 二进制文件和结果？(y/N) ${NC}"
    read -r keep_files
    if [ "$keep_files" = "y" ] || [ "$keep_files" = "Y" ]; then
        printf "${GREEN}文件已保留: %s, coremark_result.log${NC}\n" "$TEMP_BINARY"
    else
        cleanup
        printf "${GREEN}清理完成!${NC}\n"
    fi
    
    printf "\n${BLUE}感谢使用狗点饭 CoreMark 跑分工具！${NC}\n"
}

trap cleanup EXIT INT TERM

main
