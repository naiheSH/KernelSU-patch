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

:: 获取 GitHub 最新版本号 - 直接使用 v3.0.0，因为 API 访问受限
echo 获取 GitHub 最新版本号...
set "LATEST_VERSION=v3.0.0"
echo 无法获取最新版本号，使用默认版本 !LATEST_VERSION!
echo GitHub 最新版本:!LATEST_VERSION!

:: 读取本地存储的版本号
set VERSION_FILE=%TARGET_DIR%\version.txt
if exist "%VERSION_FILE%" (
    set /p LOCAL_VERSION=<"%VERSION_FILE%"
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

:: 选择 GKI 版本
echo.
echo GKI版本选择，依据系统内核显示版本号
echo       1. android 12-5.10
echo       2. android 13-5.10
echo       3. android 13-5.15
echo       4. android 14-5.15
echo       5. android 14-6.1
echo       6. android 15-6.6
echo       7. android 16-6.12
echo.______________________________
set /p choice= (1-7):

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
) else if "%choice%" == "7" (
    ksud boot-patch -b img\init_boot.img -m ko\android16-6.12_kernelsu.ko --magiskboot bin\magiskboot.exe --kmi android16-6.12
) else (
    echo 无效的选择
    exit /b 1
)

:: 等待一段时间，确保文件生成完毕
timeout /t 3 /nobreak >nul

:: 找出脚本当前目录下最新修改的文件并重命名
set "NEWEST_FILE="
set "NEWEST_TIME=0"
set "RENAME_SUCCESS=0"
for /f "delims=" %%F in ('dir /b /o-d /t:w "*.img" 2^>nul') do (
    for /f "tokens=2 delims=:" %%t in ('echo %%~tF') do (
        set "CURRENT_TIME=%%t"
        if "!CURRENT_TIME!" gtr "!NEWEST_TIME!" (
            set "NEWEST_FILE=%%F"
            set "NEWEST_PATH=%CD%\%%F"
            set "NEWEST_TIME=!CURRENT_TIME!"
        )
    )
)
if defined NEWEST_FILE (
    set "COUNTER=1"
    :CHECK_NAME
    set "NEW_NAME=KernelSU!COUNTER!.img"
    if "!COUNTER!" equ "1" (
        set "NEW_NAME=KernelSU.img"
    )
    if exist "!NEW_NAME!" (
        set /a COUNTER=COUNTER + 1
        goto CHECK_NAME
    )
    if exist "!NEWEST_PATH!" (
        ren "!NEWEST_PATH!" "!NEW_NAME!"
        echo 生成的文件已重命名为 !NEW_NAME!
        set "RENAME_SUCCESS=1"
        goto END_RENAME  :: 重命名成功后直接跳转到结束重命名的标签处
    )
) else (
    echo 未找到生成的文件，无法重命名。
    goto END_RENAME  :: 未找到文件也直接跳转到结束重命名的标签处
)
:END_RENAME
if "!RENAME_SUCCESS!" equ "0" (
    echo 未成功重命名文件，可能存在其他问题。
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

echo.
echo ========================================
echo 操作已完成！
echo 按任意键退出...
echo ========================================
echo.
pause
endlocal