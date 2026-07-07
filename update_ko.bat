@echo off
chcp 65001 >nul
set PATH=%PATH%;%~dp0bin
setlocal enabledelayedexpansion

:: GitHub 相关信息
set REPO_OWNER=tiann
set REPO_NAME=KernelSU

:: 代理设置（如果需要代理访问 GitHub，取消下面的注释并填入你的代理地址）
:: set "HTTP_PROXY=http://127.0.0.1:7890"
:: set "HTTPS_PROXY=http://127.0.0.1:7890"

:: GitHub API 镜像（如果直连 GitHub API 失败，依次尝试镜像）
set "API_URL_1=https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest"
set "API_URL_2=https://ghfast.top/https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest"

:: GitHub 下载镜像前缀（留空则直连，否则通过镜像下载）
set "DOWNLOAD_MIRROR=https://ghfast.top/"

:: ko 文件夹（当前目录）
set TARGET_DIR=%CD%\ko

:: 创建 ko 目录（如果不存在）
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

:: 要下载的.ko 文件列表
set "FILES=android12-5.10_kernelsu.ko android13-5.10_kernelsu.ko android13-5.15_kernelsu.ko android14-5.15_kernelsu.ko android14-6.1_kernelsu.ko android15-6.6_kernelsu.ko android16-6.12_kernelsu.ko"

:: 读取本地存储的版本号
set VERSION_FILE=%TARGET_DIR%\version.txt
set "LOCAL_VERSION=none"
if exist "%VERSION_FILE%" (
    set /p LOCAL_VERSION=<%VERSION_FILE%
)
set "LOCAL_VERSION=!LOCAL_VERSION: =!"

:: 获取 GitHub 最新版本号
echo 正在获取 GitHub 最新版本号...

REM 尝试第一个 API 地址
set "TAG_LINE="
for /f "delims=" %%i in ('curl -s -L --connect-timeout 10 "!API_URL_1!" 2^>nul ^| findstr /i "tag_name"') do (
    set "TAG_LINE=%%i"
)

REM 如果第一个失败，尝试镜像地址
if not defined TAG_LINE (
    echo 直连 GitHub API 失败，尝试镜像地址...
    for /f "delims=" %%i in ('curl -s -L --connect-timeout 10 "!API_URL_2!" 2^>nul ^| findstr /i "tag_name"') do (
        set "TAG_LINE=%%i"
    )
)

REM 从 tag_name 行中提取版本号
set "LATEST_VERSION="
if defined TAG_LINE (
    REM 清理 JSON 行：去引号、去逗号、去空格
    set "TAG_LINE=!TAG_LINE:"=!"
    set "TAG_LINE=!TAG_LINE:,=!"
    set "TAG_LINE=!TAG_LINE: =!"
    REM 提取冒号后的版本号
    for /f "tokens=2 delims=:" %%a in ("!TAG_LINE!") do set "LATEST_VERSION=%%a"
)

:: 如果获取失败
if not defined LATEST_VERSION (
    echo 错误: 无法获取 GitHub 版本号。
    echo 请检查网络连接，或设置代理后重试。
    echo 代理设置方法: 编辑 update_ko.bat，取消开头 HTTP_PROXY 行的注释。
    pause
    exit /b 1
)

set "LATEST_VERSION=!LATEST_VERSION: =!"
echo 成功获取 GitHub 最新版本: !LATEST_VERSION!
echo 本地版本: !LOCAL_VERSION!

:: 比较版本号，如果相同则跳过下载
if "!LATEST_VERSION!"=="!LOCAL_VERSION!" (
    echo 当前版本已是最新版本，无需更新。
    pause
    exit /b 0
)

echo 检测到版本差异，开始下载 ko 文件...

:: 下载所有 ko 文件
set "DOWNLOAD_SUCCESS=1"
for %%F in (%FILES%) do (
    set "FILE_NAME=%%F"
    set "DOWNLOAD_URL=!DOWNLOAD_MIRROR!https://github.com/!REPO_OWNER!/!REPO_NAME!/releases/download/!LATEST_VERSION!/!FILE_NAME!"

    REM 删除已存在的文件
    if exist "%TARGET_DIR%\!FILE_NAME!" (
        echo 删除已存在的文件: !FILE_NAME!
        del /f /q "%TARGET_DIR%\!FILE_NAME!"
    )

    echo 下载 !FILE_NAME!...
    curl -L --retry 5 --retry-delay 3 -# -o "%TARGET_DIR%\!FILE_NAME!" "!DOWNLOAD_URL!"
    if errorlevel 1 (
        echo 下载失败: !FILE_NAME!
        set "DOWNLOAD_SUCCESS=0"
    ) else if exist "%TARGET_DIR%\!FILE_NAME!" (
        REM 检查文件大小是否合理（ko 文件应至少 10KB）
        for %%A in ("%TARGET_DIR%\!FILE_NAME!") do set "FILESIZE=%%~zA"
        if !FILESIZE! LSS 10240 (
            echo 下载异常: !FILE_NAME! 文件过小（!FILESIZE! 字节），可能下载失败
            del /f /q "%TARGET_DIR%\!FILE_NAME!"
            set "DOWNLOAD_SUCCESS=0"
        ) else (
            echo 下载完成: !FILE_NAME!（!FILESIZE! 字节）
        )
    ) else (
        echo 下载失败: !FILE_NAME! 文件不存在
        set "DOWNLOAD_SUCCESS=0"
    )
)

:: 仅在全部下载成功后写入版本号
if "!DOWNLOAD_SUCCESS!"=="1" (
    >"%VERSION_FILE%" echo(!LATEST_VERSION!
    echo.
    echo 所有 ko 文件已更新！版本号已更新为 !LATEST_VERSION!
) else (
    echo.
    echo 部分文件下载失败，未更新版本号，下次运行将重新尝试下载。
)

pause
endlocal
