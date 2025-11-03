#!/bin/bash
# 本地构建测试脚本
# 用于在本地测试编译是否正常

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CoreMark 本地构建测试${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 检测当前架构
CURRENT_ARCH=$(uname -m)
echo -e "${GREEN}当前架构: ${NC}$CURRENT_ARCH"

# 获取 CPU 核心数
NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
echo -e "${GREEN}CPU 核心数: ${NC}$NPROC\n"

# 清理之前的构建
echo -e "${YELLOW}清理之前的构建...${NC}"
make clean 2>/dev/null || true
rm -f coremark.exe coremark_test

# 构建
echo -e "${YELLOW}开始编译 CoreMark...${NC}"
echo -e "${BLUE}编译参数:${NC}"
echo -e "  PORT_DIR=linux"
echo -e "  XCFLAGS=\"-O2 -DMULTITHREAD=$NPROC -DUSE_PTHREAD\""
echo -e "  LFLAGS_END=\"-pthread\"\n"

if make PORT_DIR=linux \
    XCFLAGS="-O2 -DMULTITHREAD=$NPROC -DUSE_PTHREAD" \
    LFLAGS_END="-pthread" \
    compile; then
    echo -e "\n${GREEN}✅ 编译成功！${NC}\n"
else
    echo -e "\n${RED}❌ 编译失败！${NC}"
    exit 1
fi

# 重命名
mv ./coremark.exe ./coremark_test
chmod +x ./coremark_test

# 检查文件
echo -e "${YELLOW}检查编译产物:${NC}"
ls -lh coremark_test
file coremark_test
echo ""

# 运行测试
echo -e "${YELLOW}运行性能测试...${NC}"
echo -e "${BLUE}这可能需要几分钟时间...${NC}\n"

if ./coremark_test 0x0 0x0 0x66 0 7 1 2000 > test_result.log 2>&1; then
    echo -e "${GREEN}✅ 测试运行成功！${NC}\n"
    
    # 显示结果
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}       CoreMark 测试结果${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 提取关键信息
    grep "CoreMark 1.0" test_result.log || true
    grep "Correct operation validated" test_result.log || true
    grep "Total time" test_result.log || true
    grep "Iterations" test_result.log || true
    
    echo -e "${GREEN}========================================${NC}\n"
    
    # 完整日志
    echo -e "${BLUE}完整测试日志已保存到: test_result.log${NC}\n"
    
    # 验证测试
    echo -e "${YELLOW}运行验证测试...${NC}"
    if ./coremark_test 0x3415 0x3415 0x66 0 7 1 2000 > test_validation.log 2>&1; then
        if grep -q "Correct operation validated" test_validation.log; then
            echo -e "${GREEN}✅ 验证测试通过！${NC}\n"
        else
            echo -e "${RED}❌ 验证测试失败！${NC}\n"
            exit 1
        fi
    else
        echo -e "${RED}❌ 验证测试运行失败！${NC}\n"
        exit 1
    fi
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ✅ 所有测试通过！${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo -e "${BLUE}构建的二进制文件: coremark_test${NC}"
    echo -e "${BLUE}测试日志: test_result.log, test_validation.log${NC}\n"
    
else
    echo -e "${RED}❌ 测试运行失败！${NC}"
    echo -e "${YELLOW}日志内容:${NC}"
    cat test_result.log
    exit 1
fi

# 清理询问
echo -e "${YELLOW}是否清理测试文件？(y/N) ${NC}"
read -r cleanup_choice
if [[ "$cleanup_choice" =~ ^[Yy]$ ]]; then
    rm -f coremark_test test_result.log test_validation.log
    make clean
    echo -e "${GREEN}清理完成！${NC}"
fi

echo -e "\n${BLUE}测试完成！如果你看到此消息，说明本地构建正常。${NC}"
echo -e "${BLUE}现在可以推送到 GitHub 触发自动构建了。${NC}\n"

