@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: GitHub 相关信息
set REPO_OWNER=tiann
set REPO_NAME=KernelSU

:: ko 文件夹（当前目录）
set TARGET_DIR=%CD%\ko

:: 创建 ko 目录（如果不存在）
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

:: 要下载的.ko 文件列表
set "FILES=android12-5.10_kernelsu.ko android13-5.10_kernelsu.ko android13-5.15_kernelsu.ko android14-5.15_kernelsu.ko android14-6.1_kernelsu.ko android15-6.6_kernelsu.ko android16-6.12_kernelsu.ko"

:: 获取 GitHub 最新版本号 - 直接使用 v3.0.0，因为 API 访问受限
echo 获取 GitHub 最新版本号...
set "LATEST_VERSION=v3.0.0"
echo 无法获取最新版本号，使用默认版本 !LATEST_VERSION!
echo GitHub 最新版本:!LATEST_VERSION!

:: 读取本地存储的版本号
set VERSION_FILE=%TARGET_DIR%\version.txt
if exist "%VERSION_FILE%" (
    set /p LOCAL_VERSION=<%VERSION_FILE%
) else (
    set "LOCAL_VERSION=none"
)

:: 清理版本号中的多余空格
set LOCAL_VERSION=!LOCAL_VERSION: =!
set LATEST_VERSION=!LATEST_VERSION: =!

:: 输出本地版本与GitHub版本
echo ============================
echo 本地版本:!LOCAL_VERSION!
echo GitHub版本:!LATEST_VERSION!
echo ============================

:: 比较版本号，判断是否需要重新下载
if not "!LATEST_VERSION!"=="!LOCAL_VERSION!" (
    echo 检测到版本差异（GitHub版本:!LATEST_VERSION! vs 本地版本:!LOCAL_VERSION!），开始更新 ko 文件...

    for %%F in (%FILES%) do (
        set "FILE_NAME=%%F"
        set "DOWNLOAD_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/download/%LATEST_VERSION%/!FILE_NAME!"
        
        :: 删除已存在的文件
        if exist "%TARGET_DIR%\!FILE_NAME!" (
            echo 删除已存在的文件:!FILE_NAME!
            del /f /q "%TARGET_DIR%\!FILE_NAME!"
        )

        echo 下载!FILE_NAME!...
        curl -L --retry 5 --retry-delay 3 -# -o "%TARGET_DIR%\!FILE_NAME!" "!DOWNLOAD_URL!"
        if exist "%TARGET_DIR%\!FILE_NAME!" (
            echo 下载完成！
        ) else (
            echo 下载失败！
        )
    )
    
    REM 写入最新版本号到文件
    >"%VERSION_FILE%" echo(!LATEST_VERSION!
    if errorlevel 1 (
        echo 写入版本号到文件失败！
    ) else (
        echo 所有 ko 文件已更新！
    )
) else (
    echo 当前版本已是最新版本，本地版本:!LOCAL_VERSION!，GitHub版本:!LATEST_VERSION!
    echo 所有 ko 文件已是最新版本，跳过更新。
)

endlocal