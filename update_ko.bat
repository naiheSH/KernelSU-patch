@echo off
chcp 65001 >nul
set PATH=%PATH%;%~dp0bin
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

:: 获取 GitHub 最新版本号
echo 获取 GitHub 最新版本号...
timeout /t 1 >nul
for /f "delims=" %%i in ('curl -s -L -k "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest" ^| findstr /i "tag_name"') do (
    set "TAG_LINE=%%i"
    set "LATEST_VERSION=!TAG_LINE:~15,-2!"
)

:: 如果获取失败，使用默认版本
if not defined LATEST_VERSION (
    set "LATEST_VERSION=v3.0.0"
    echo 无法获取最新版本号，使用默认版本 !LATEST_VERSION!
) else (
    echo 成功获取 GitHub 最新版本:!LATEST_VERSION!
)

:: 写入最新版本号到文件
>"%TARGET_DIR%\version.txt" echo(!LATEST_VERSION!

:: 下载所有 ko 文件
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

echo 所有 ko 文件已更新！
echo 版本号已更新为 !LATEST_VERSION!
endlocal