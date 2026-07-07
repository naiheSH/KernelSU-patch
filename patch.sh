#!/bin/bash
# KernelSU 自动更新与补丁工具 (Linux 版)
# 功能：自动检测最新版本、下载 .ko 文件、对启动镜像进行补丁

set -e

# GitHub 相关信息
REPO_OWNER="tiann"
REPO_NAME="KernelSU"

# 代理设置（如果需要代理访问 GitHub，取消下面的注释并填入你的代理地址）
# export HTTP_PROXY="http://127.0.0.1:7890"
# export HTTPS_PROXY="http://127.0.0.1:7890"

# GitHub Release 页面地址列表（按优先级排列）
RELEASE_URLS=(
    "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    "https://ghfast.top/https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    "https://gh-proxy.com/https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest"
)

# GitHub 下载镜像前缀（按优先级排列，留空则直连）
DOWNLOAD_MIRRORS=(
    ""
    "https://ghfast.top/"
    "https://gh-proxy.com/"
)

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"
KO_DIR="${SCRIPT_DIR}/ko"
IMG_DIR="${SCRIPT_DIR}/img"

# 创建目录
mkdir -p "$BIN_DIR" "$KO_DIR" "$IMG_DIR"

# 要下载的 .ko 文件列表
FILES=(
    "android12-5.10_kernelsu.ko"
    "android13-5.10_kernelsu.ko"
    "android13-5.15_kernelsu.ko"
    "android14-5.15_kernelsu.ko"
    "android14-6.1_kernelsu.ko"
    "android15-6.6_kernelsu.ko"
    "android16-6.12_kernelsu.ko"
)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   KernelSU 自动更新与补丁工具 (Linux)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查 ksud 是否存在
if [ ! -f "${BIN_DIR}/ksud" ]; then
    echo -e "${RED}错误: 未找到 ksud 文件！${NC}"
    echo "请将 ksud 放入 ${BIN_DIR} 目录后重试。"
    echo "可以从 https://github.com/tiann/KernelSU/actions 下载 Linux 版本。"
    exit 1
fi

# 确保 ksud 有执行权限
chmod +x "${BIN_DIR}/ksud"

# 获取 GitHub 最新版本号
echo "正在获取 GitHub 最新版本号..."

LATEST_VERSION=""

# 方法1: 使用 gh CLI（已认证，最可靠）
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    LATEST_VERSION=$(gh api repos/${REPO_OWNER}/${REPO_NAME}/releases/latest --jq '.tag_name' 2>/dev/null || true)
    if [ -n "$LATEST_VERSION" ]; then
        echo "通过 gh CLI 获取版本成功"
    fi
fi

# 方法2: 解析 Release 页面获取版本号（不依赖 API，更稳定）
if [ -z "$LATEST_VERSION" ]; then
    for RELEASE_URL in "${RELEASE_URLS[@]}"; do
        LATEST_VERSION=$(curl -s -L --connect-timeout 10 "$RELEASE_URL" 2>/dev/null | grep -oP 'releases/tag/\Kv[0-9.]+' | head -1)
        if [ -n "$LATEST_VERSION" ]; then
            echo "通过 Release 页面获取版本成功"
            break
        fi
    done
fi

# 读取本地存储的版本号
VERSION_FILE="${KO_DIR}/version.txt"
LOCAL_VERSION="none"
if [ -f "$VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
fi

# 如果获取失败，回退到本地版本
if [ -z "$LATEST_VERSION" ]; then
    if [ "$LOCAL_VERSION" != "none" ]; then
        LATEST_VERSION="$LOCAL_VERSION"
        echo -e "${YELLOW}无法获取 GitHub 最新版本号，使用本地已有版本 ${LATEST_VERSION}${NC}"
    else
        echo -e "${RED}错误: 无法获取 GitHub 版本号，且本地没有已下载的 ko 文件。${NC}"
        echo "请检查网络连接，或设置代理后重试。"
        exit 1
    fi
else
    echo -e "${GREEN}成功获取 GitHub 最新版本: ${LATEST_VERSION}${NC}"
fi

# 输出本地版本与 GitHub 版本
echo "============================"
echo "本地版本: ${LOCAL_VERSION}"
echo "GitHub版本: ${LATEST_VERSION}"
echo "============================"

# 比较版本号，判断是否需要重新下载
DOWNLOAD_SUCCESS=1
if [ "$LATEST_VERSION" != "$LOCAL_VERSION" ]; then
    echo "检测到版本差异，开始更新 ko 文件..."

    for FILE in "${FILES[@]}"; do
        FILE_DOWNLOADED=0

        # 尝试直连和各镜像下载
        for MIRROR in "${DOWNLOAD_MIRRORS[@]}"; do
            DOWNLOAD_URL="${MIRROR}https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${LATEST_VERSION}/${FILE}"

            # 删除已存在的文件
            if [ -f "${KO_DIR}/${FILE}" ]; then
                rm -f "${KO_DIR}/${FILE}"
            fi

            if curl -s -L --connect-timeout 10 --retry 2 --retry-delay 2 -o "${KO_DIR}/${FILE}" "$DOWNLOAD_URL" 2>/dev/null; then
                FILESIZE=$(stat -c%s "${KO_DIR}/${FILE}" 2>/dev/null || stat -f%z "${KO_DIR}/${FILE}" 2>/dev/null)
                if [ "$FILESIZE" -ge 10240 ] 2>/dev/null; then
                    echo -e "${GREEN}下载完成: ${FILE}（${FILESIZE} 字节）${NC}"
                    FILE_DOWNLOADED=1
                    break
                else
                    rm -f "${KO_DIR}/${FILE}"
                fi
            else
                rm -f "${KO_DIR}/${FILE}"
            fi
        done

        if [ "$FILE_DOWNLOADED" -eq 0 ]; then
            echo -e "${RED}下载失败: ${FILE}${NC}"
            DOWNLOAD_SUCCESS=0
        fi
    done

    # 仅在全部下载成功后写入版本号
    if [ "$DOWNLOAD_SUCCESS" -eq 1 ]; then
        echo "$LATEST_VERSION" > "$VERSION_FILE"
        echo -e "${GREEN}所有 ko 文件已更新！${NC}"
    else
        echo -e "${YELLOW}部分文件下载失败，未更新版本号，下次运行将重新尝试下载。${NC}"
    fi
else
    echo -e "${GREEN}当前版本已是最新版本，跳过更新。${NC}"
fi

# 选择 GKI 版本
echo ""
echo "GKI 版本选择，依据系统内核显示版本号"
echo "  1. android 12-5.10"
echo "  2. android 13-5.10"
echo "  3. android 13-5.15"
echo "  4. android 14-5.15"
echo "  5. android 14-6.1"
echo "  6. android 15-6.6"
echo "  7. android 16-6.12"
echo "________________________________"
read -p "请选择 (1-7): " choice

# 执行补丁操作
execute_patch() {
    local boot_img="$1"
    local ko_file="$2"
    local kmi_version="$3"

    if [ ! -f "$boot_img" ]; then
        echo -e "${RED}错误: 未找到 ${boot_img} 文件！${NC}"
        echo "请将你的启动镜像放入 img 目录后重试。"
        exit 1
    fi

    echo "正在执行补丁操作..."
    "${BIN_DIR}/ksud" boot-patch -b "$boot_img" -m "$KO_DIR/$ko_file" --kmi "$kmi_version"

    # 检查执行结果
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 补丁操作执行失败！${NC}"
        echo "可能的原因:"
        echo "  1. ksud 版本不兼容"
        echo "  2. 启动镜像文件损坏"
        echo "  3. ko 文件与内核版本不匹配"
        exit 1
    fi
}

case "$choice" in
    1) execute_patch "${IMG_DIR}/boot.img" "android12-5.10_kernelsu.ko" "android12-5.10" ;;
    2) execute_patch "${IMG_DIR}/init_boot.img" "android13-5.10_kernelsu.ko" "android13-5.10" ;;
    3) execute_patch "${IMG_DIR}/init_boot.img" "android13-5.15_kernelsu.ko" "android13-5.15" ;;
    4) execute_patch "${IMG_DIR}/init_boot.img" "android14-5.15_kernelsu.ko" "android14-5.15" ;;
    5) execute_patch "${IMG_DIR}/init_boot.img" "android14-6.1_kernelsu.ko" "android14-6.1" ;;
    6) execute_patch "${IMG_DIR}/init_boot.img" "android15-6.6_kernelsu.ko" "android15-6.6" ;;
    7) execute_patch "${IMG_DIR}/init_boot.img" "android16-6.12_kernelsu.ko" "android16-6.12" ;;
    *)
        echo -e "${RED}无效的选择: ${choice}${NC}"
        exit 1
        ;;
esac

# 等待文件生成
echo ""
echo "等待补丁文件生成..."
for i in {1..30}; do
    if ls "${SCRIPT_DIR}"/*.img 1>/dev/null 2>&1; then
        echo -e "${GREEN}检测到镜像文件已生成。${NC}"
        break
    fi
    sleep 1
done

# 找出最新修改的 .img 文件并重命名
NEWEST_FILE=$(ls -t "${SCRIPT_DIR}"/*.img 2>/dev/null | head -1)
if [ -n "$NEWEST_FILE" ]; then
    NEW_NAME="KernelSU.img"
    COUNTER=1
    while [ -f "${SCRIPT_DIR}/${NEW_NAME}" ]; do
        COUNTER=$((COUNTER + 1))
        NEW_NAME="KernelSU${COUNTER}.img"
    done

    mv "$NEWEST_FILE" "${SCRIPT_DIR}/${NEW_NAME}"
    echo -e "${GREEN}生成的文件已重命名为 ${NEW_NAME}${NC}"
else
    echo -e "${YELLOW}未找到生成的 .img 文件，无法重命名。${NC}"
fi

# 询问是否删除 img 目录中的文件
echo ""
read -p "是否删除 img 文件夹中的所有文件? (y/n): " del_choice

if [ "$del_choice" = "y" ] || [ "$del_choice" = "Y" ]; then
    if [ -d "$IMG_DIR" ] && [ "$(ls -A "$IMG_DIR" 2>/dev/null)" ]; then
        find "$IMG_DIR" -type f ! -name "*.txt" -delete
        echo -e "${GREEN}img 文件夹中的镜像文件已删除${NC}"
    else
        echo "img 文件夹已为空或不存在"
    fi
else
    echo "img 文件夹中的文件未删除"
fi

echo ""
echo "========================================"
echo -e "${GREEN}操作已完成！${NC}"
echo "========================================"
