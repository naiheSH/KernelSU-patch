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

:: 要下载的 .ko 文件列表
set "FILES=android12-5.10_kernelsu.ko android13-5.10_kernelsu.ko android13-5.15_kernelsu.ko android14-5.15_kernelsu.ko android14-6.1_kernelsu.ko android15-6.6_kernelsu.ko"

:: 获取 GitHub 最新版本号
for /f "tokens=2 delims=:, " %%i in ('curl -s "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest" ^| findstr /i "tag_name"') do (
    set "LATEST_VERSION=%%i"
    set "LATEST_VERSION=!LATEST_VERSION:~1,-1!"
)
echo 最新版本: !LATEST_VERSION!

:: 读取本地存储的版本号
set VERSION_FILE=%TARGET_DIR%\version.txt
if exist "%VERSION_FILE%" (
    set /p LOCAL_VERSION=<"%VERSION_FILE%"
) else (
    set "LOCAL_VERSION=none"
)

:: 比较版本号，判断是否需要重新下载
if not "!LATEST_VERSION!"=="!LOCAL_VERSION!" (
    echo 检测到新版本，开始更新 ko 文件...
    
    for %%F in (%FILES%) do (
        set "FILE_NAME=%%F"
        set "DOWNLOAD_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/download/%LATEST_VERSION%/!FILE_NAME!"
        
        echo 下载 !FILE_NAME!...
        curl -L --retry 5 --retry-delay 3 -o "%TARGET_DIR%\!FILE_NAME!" "!DOWNLOAD_URL!"
        echo 下载完成！
    )
    
    echo !LATEST_VERSION! > "%VERSION_FILE%"  :: 更新本地版本号
    echo 所有 ko 文件已更新！
) else (
    echo 当前已是最新版本，无需更新。
)

:: 选择 GKI 版本
echo.
echo GKI版本选择，依据系统内核显示版本号
echo       1. android 12-5.10
echo       2. android 13-5.10
echo       3. android 13-5.15
echo       4. android 14-5.15
echo       5. android 14-6.1
echo       6. android 15-6.6
echo.______________________________
set /p choice= (1-6):

if "%choice%" == "1" (
    ksud boot-patch -b img\boot.img -m ko\android12-5.10_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android12-5.10
) else if "%choice%" == "2" (
    ksud boot-patch -b img\init_boot.img -m ko\android13-5.10_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android13-5.10
) else if "%choice%" == "3" (
    ksud boot-patch -b img\init_boot.img -m ko\android13-5.15_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android13-5.15
) else if "%choice%" == "4" (
    ksud boot-patch -b img\init_boot.img -m ko\android14-5.15_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android14-5.15
) else if "%choice%" == "5" (
    ksud boot-patch -b img\init_boot.img -m ko\android14-6.1_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android14-6.1
) else if "%choice%" == "6" (
    ksud boot-patch -b img\init_boot.img -m ko\android15-6.6_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android15-6.6
) else (
    echo 无效的选择
    exit /b 1
)

:: 询问是否删除 img 目录中的文件
echo 是否删除 img 文件夹中的所有文件? (y/n)
set /p del_choice=

if /i "%del_choice%" == "y" (
    if exist img\* (
        del /Q img\*
        echo img 文件夹中的所有文件已删除
    ) else (
        echo img 文件夹已为空或不存在
    )
) else (
    echo img 文件夹中的文件未删除
)

pause
endlocal
