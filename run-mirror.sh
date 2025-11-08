#!/bin/sh
# CoreMark 一键运行脚本 - 狗点饭镜像版
# 使用方法: curl -fsSL https://gou.fan/coremark/run-mirror.sh | sh

set -e

# 颜色输出（柔和配色）
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
CYAN='\033[0;96m'
NC='\033[0m'

# 配置 - 使用狗点饭镜像源
DOWNLOAD_BASE="https://gou.fan/coremark/releases/latest/download"

# 全局状态
CLEANED_UP=0

printf "${BLUE}========================================${NC}\n"
printf "${BLUE}  狗点饭 NAS CoreMark 跑分工具${NC}\n"
printf "${BLUE}  (国内镜像加速版)${NC}\n"
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
    download_url="${DOWNLOAD_BASE}/${binary_name}"
    
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
    
    printf "\n${YELLOW}正在从狗点饭镜像下载 CoreMark (%s)...${NC}\n" "$arch" >&2
    
    download_success=0
    
    # 优先尝试 curl
    if which curl >/dev/null 2>&1 || type curl >/dev/null 2>&1; then
        if curl -f -L --progress-bar -o "$binary_name" "$download_url" 2>&2; then
            download_success=1
        fi
    fi
    
    # 如果 curl 失败，尝试 wget
    if [ $download_success -eq 0 ]; then
        if which wget >/dev/null 2>&1 || type wget >/dev/null 2>&1; then
            if wget --show-progress -q -O "$binary_name" "$download_url" 2>&2; then
                download_success=1
            fi
        fi
    fi
    
    # 如果都失败了
    if [ $download_success -eq 0 ]; then
        printf "${RED}========================================${NC}\n" >&2
        printf "${RED} 下载失败！${NC}\n" >&2
        printf "${RED}========================================${NC}\n" >&2
        printf "${CYAN}下载地址: %s${NC}\n\n" "$download_url" >&2
        printf "${YELLOW}请尝试以下操作：${NC}\n\n" >&2
        printf "1. 检查网络连接\n" >&2
        printf "2. 手动下载：\n" >&2
        printf "   ${BLUE}https://gou.fan/coremark/releases/latest/download/${binary_name}${NC}\n\n" >&2
        printf "3. 或使用 GitHub 官方脚本：\n" >&2
        printf "   ${CYAN}curl -fsSL https://raw.githubusercontent.com/huladabang/coremark-goufan/main/run.sh | sh${NC}\n" >&2
        exit 1
    fi
    
    # 检查文件是否下载成功且不为空
    if [ ! -f "$binary_name" ] || [ ! -s "$binary_name" ]; then
        printf "${RED}下载失败: 文件为空或不存在${NC}\n" >&2
        exit 1
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
    
    # 从二进制文件路径提取工作目录，并切换到该目录
    # 这样日志文件会创建在正确的位置
    work_dir=$(dirname "$binary")
    cd "$work_dir" || {
        printf "${RED}错误: 无法进入工作目录 %s${NC}\n" "$work_dir" >&2
        exit 1
    }
    
    # 清理可能残留的日志文件（防止上次运行留下的文件干扰）
    if [ -f coremark_result.log ]; then
        rm -f coremark_result.log >/dev/null 2>&1 || true
    fi
    
    # 检测逻辑核心数（包括超线程）
    cpu_threads=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)
    
    printf "${YELLOW}正在运行 CoreMark 跑分...${NC}\n"
    printf "${YELLOW}使用 ${cpu_threads} 个线程 (逻辑核心数)${NC}\n"
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
    
    # 使用绝对路径存储日志文件，确保即使在子shell中也能正确创建
    result_log="${work_dir}/coremark_result.log"
    
    # 使用 M<n> 参数指定线程数，充分利用超线程
    # 使用绝对路径重定向，确保日志文件创建在正确位置
    if ! "$binary" "M${cpu_threads}" 0x0 0x0 0x66 $iterations 7 1 2000 > "$result_log" 2>&1; then
        printf "${RED}========================================${NC}\n"
        printf "${RED} 运行失败！${NC}\n"
        printf "${RED}========================================${NC}\n"
        
        # 检查日志文件是否存在（可能因为权限问题创建失败）
        if [ -f "$result_log" ] && [ -r "$result_log" ]; then
            if grep -qi "permission denied" "$result_log" >/dev/null 2>&1; then
                printf "${YELLOW}可能是文件系统挂载为 noexec（禁止执行）${NC}\n\n"
                printf "${BLUE}请尝试以下操作：${NC}\n"
                printf "1. 找到一个允许执行的目录：\n"
                printf " ${GREEN}群晖:${NC} cd /volume1/@tmp\n"
                printf " ${GREEN}威联通:${NC} cd /share/CACHEDEV1_DATA/temp\n"
                printf " ${GREEN}其他:${NC} cd /var/tmp 或 cd ~\n\n"
                printf "2. 重新下载并运行：\n"
                arch=$(detect_arch)
                cpu_threads=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)
                printf " ${BLUE}wget https://gou.fan/coremark/releases/latest/download/coremark_%s${NC}\n" "$arch"
                printf " ${BLUE}chmod +x coremark_%s${NC}\n" "$arch"
                printf " ${BLUE}./coremark_%s M%s 0x0 0x0 0x66 0 7 1 2000${NC}\n\n" "$arch" "$cpu_threads"
            else
                printf "${YELLOW}错误信息：${NC}\n"
                cat "$result_log"
            fi
        else
            printf "${YELLOW}无法创建日志文件，可能是目录权限问题或磁盘空间不足${NC}\n"
            printf "${YELLOW}工作目录: %s${NC}\n" "$work_dir"
        fi
        # 清理失败的日志文件
        rm -f "$result_log" >/dev/null 2>&1 || true
        exit 1
    fi
    
    # 检查日志文件是否存在
    if [ ! -f "$result_log" ] || [ ! -r "$result_log" ]; then
        printf "${RED}错误: 无法读取日志文件 %s${NC}\n" "$result_log" >&2
        exit 1
    fi
    
    score=$(grep "CoreMark 1.0" "$result_log" | grep -oE "CoreMark 1.0 : [0-9.]+" | grep -oE "[0-9.]+$")
    iterations_done=$(grep "Iterations" "$result_log" | grep -oE "Iterations[[:space:]]*:[[:space:]]*[0-9]+" | grep -oE "[0-9]+$")
    total_time=$(grep "Total time" "$result_log" | grep -oE "Total time \\(secs\\)[[:space:]]*:[[:space:]]*[0-9.]+" | grep -oE "[0-9.]+$")
    
    printf "\n${GREEN}========================================${NC}\n"
    printf "${GREEN} CoreMark 跑分结果${NC}\n"
    printf "${GREEN}========================================${NC}\n"
    printf "${GREEN}分数:${NC} ${BLUE}%s${NC} CoreMark/MHz\n" "$score"
    printf "${GREEN}迭代次数:${NC} %s\n" "$iterations_done"
    printf "${GREEN}总耗时:${NC} %s 秒\n" "$total_time"
    printf "${GREEN}========================================${NC}\n\n"
    
    printf "${YELLOW}跑分结果详情:${NC}\n"
    cat "$result_log"
}

# 提交结果提示
submit_result() {
    printf "\n${YELLOW}========================================${NC}\n"
    printf "${YELLOW} 想要提交你的跑分结果？${NC}\n"
    printf "${YELLOW}========================================${NC}\n"
    printf "📸 ${GREEN}请截图保存：CPU信息 + 跑分结果${NC}\n"
    printf "🌐 ${GREEN}然后访问提交页面：${NC}\n"
    printf "   ${BLUE}https://gou.fan/coremark/submit${NC}\n\n"
    printf "💡 ${CYAN}提交后需管理员审核，通过后将会显示在 NAS/迷你主机 CPU 性能天梯图中！${NC}\n"
    printf "   感谢你帮助我们完善低功耗CPU性能排行榜！\n\n"
}

# 清理临时文件
cleanup() {
    if [ "${CLEANED_UP:-0}" -eq 1 ]; then
        return
    fi

    # 防止清理过程中的错误导致脚本退出
    set +e
    
    if [ -n "$TEMP_BINARY" ]; then
        printf "${YELLOW}清理临时文件...${NC}\n"
        # 清理二进制文件
        [ -f "$TEMP_BINARY" ] && rm -f "$TEMP_BINARY" >/dev/null 2>&1
        # 清理日志文件（从二进制路径提取目录）
        if [ -n "$TEMP_BINARY" ]; then
            work_dir=$(dirname "$TEMP_BINARY")
            [ -f "${work_dir}/coremark_result.log" ] && rm -f "${work_dir}/coremark_result.log" >/dev/null 2>&1
        fi
        printf "${GREEN}清理完成!${NC}\n"
    fi
    
    # 恢复错误处理
    set -e

    CLEANED_UP=1
}

# 主函数
main() {
    # 脚本开始时的清理：清理可能残留的临时文件和日志文件
    # 防止上次运行留下的文件干扰本次执行
    set +e  # 临时禁用错误退出，清理失败不影响后续执行
    # 清理常见的临时目录中可能存在的残留文件
    for tmp_dir in /volume1/@tmp /volume2/@tmp /share/CACHEDEV1_DATA/temp /var/tmp /tmp; do
        [ -d "$tmp_dir" ] && [ -w "$tmp_dir" ] && rm -f "${tmp_dir}/coremark_result.log" >/dev/null 2>&1 || true
    done
    set -e  # 恢复错误退出
    
    printf "${GREEN}检测系统信息...${NC}\n"
    os=$(detect_os)
    arch=$(detect_arch)
    printf "${GREEN}操作系统:${NC} %s\n" "$os"
    printf "${GREEN}架构:${NC} %s\n" "$arch"
    get_cpu_info
    
    TEMP_BINARY=$(download_coremark "$arch")
    
    run_coremark "$TEMP_BINARY" 0
    
    submit_result
    
    cleanup
    
    printf "\n${BLUE}感谢使用狗点饭 CoreMark 跑分工具！${NC}\n"
}

trap cleanup EXIT INT TERM

main

