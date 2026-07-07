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

:: GitHub Release 页面地址（按优先级排列，解析页面获取版本号，不依赖 API）
set "RELEASE_URL_1=https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/latest"
set "RELEASE_URL_2=https://ghfast.top/https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/latest"

:: GitHub 下载镜像前缀（留空则直连，否则通过镜像下载）
set "DOWNLOAD_MIRROR=https://ghfast.top/"

:: ko 文件夹（当前目录）
set TARGET_DIR=%CD%\ko

:: 创建 ko 目录（如果不存在）
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

:: 要下载的.ko 文件列表
set "FILES=android12-5.10_kernelsu.ko android13-5.10_kernelsu.ko android13-5.15_kernelsu.ko android14-5.15_kernelsu.ko android14-6.1_kernelsu.ko android15-6.6_kernelsu.ko android16-6.12_kernelsu.ko"

:: 获取 GitHub 最新版本号
echo 正在获取 GitHub 最新版本号...

REM 方法1: 尝试直连 Release 页面
set "LATEST_VERSION="
for /f "delims=" %%i in ('curl -s -L --connect-timeout 10 "!RELEASE_URL_1!" 2^>nul ^| findstr /i "releases/tag/v"') do (
    if not defined LATEST_VERSION (
        set "RAW_LINE=%%i"
        REM 从 URL 中提取版本号 (releases/tag/vX.X.X)
        for /f "tokens=3 delims=/" %%a in ("!RAW_LINE!") do set "LATEST_VERSION=%%a"
    )
)

REM 方法2: 通过镜像访问 Release 页面
if not defined LATEST_VERSION (
    echo 直连失败，尝试镜像地址...
    for /f "delims=" %%i in ('curl -s -L --connect-timeout 10 "!RELEASE_URL_2!" 2^>nul ^| findstr /i "releases/tag/v"') do (
        if not defined LATEST_VERSION (
            set "RAW_LINE=%%i"
            for /f "tokens=3 delims=/" %%a in ("!RAW_LINE!") do set "LATEST_VERSION=%%a"
        )
    )
)

:: 读取本地存储的版本号
set VERSION_FILE=%TARGET_DIR%\version.txt
set "LOCAL_VERSION=none"
if exist "%VERSION_FILE%" (
    set /p LOCAL_VERSION=<%VERSION_FILE%
)
set "LOCAL_VERSION=!LOCAL_VERSION: =!"

:: 如果获取失败，回退到本地版本
if not defined LATEST_VERSION (
    if not "!LOCAL_VERSION!"=="none" (
        set "LATEST_VERSION=!LOCAL_VERSION!"
        echo 无法获取 GitHub 最新版本号，使用本地已有版本 !LATEST_VERSION!
    ) else (
        echo 错误: 无法获取 GitHub 版本号，且本地没有已下载的 ko 文件。
        echo 请检查网络连接，或设置代理后重试。
        echo 代理设置方法: 编辑 patch.bat，取消开头 HTTP_PROXY 行的注释。
        pause
        exit /b 1
    )
) else (
    echo 成功获取 GitHub 最新版本: !LATEST_VERSION!
)

set "LATEST_VERSION=!LATEST_VERSION: =!"

:: 输出本地版本与GitHub版本
echo ============================
echo 本地版本: !LOCAL_VERSION!
echo GitHub版本: !LATEST_VERSION!
echo ============================

:: 比较版本号，判断是否需要重新下载
set "DOWNLOAD_SUCCESS=1"
if not "!LATEST_VERSION!"=="!LOCAL_VERSION!" (
    echo 检测到版本差异（GitHub版本:!LATEST_VERSION! vs 本地版本:!LOCAL_VERSION!），开始更新 ko 文件...

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

    REM 仅在全部下载成功后写入版本号
    if "!DOWNLOAD_SUCCESS!"=="1" (
        >"%VERSION_FILE%" echo(!LATEST_VERSION!
        if errorlevel 1 (
            echo 写入版本号到文件失败！
        ) else (
            echo 所有 ko 文件已更新！
        )
    ) else (
        echo 部分文件下载失败，未更新版本号，下次运行将重新尝试下载。
    )
) else (
    echo 当前版本已是最新版本，本地版本: !LOCAL_VERSION!，GitHub版本: !LATEST_VERSION!
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
echo ______________________________
set /p choice= 请选择 (1-7):

if "%choice%" == "1" (
    if not exist "img\boot.img" (
        echo 错误: 未找到 img\boot.img 文件！
        echo 请将你的 boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\boot.img -m ko\android12-5.10_kernelsu.ko --kmi android12-5.10
) else if "%choice%" == "2" (
    if not exist "img\init_boot.img" (
        echo 错误: 未找到 img\init_boot.img 文件！
        echo 请将你的 init_boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\init_boot.img -m ko\android13-5.10_kernelsu.ko --kmi android13-5.10
) else if "%choice%" == "3" (
    if not exist "img\init_boot.img" (
        echo 错误: 未找到 img\init_boot.img 文件！
        echo 请将你的 init_boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\init_boot.img -m ko\android13-5.15_kernelsu.ko --kmi android13-5.15
) else if "%choice%" == "4" (
    if not exist "img\init_boot.img" (
        echo 错误: 未找到 img\init_boot.img 文件！
        echo 请将你的 init_boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\init_boot.img -m ko\android14-5.15_kernelsu.ko --kmi android14-5.15
) else if "%choice%" == "5" (
    if not exist "img\init_boot.img" (
        echo 错误: 未找到 img\init_boot.img 文件！
        echo 请将你的 init_boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\init_boot.img -m ko\android14-6.1_kernelsu.ko --kmi android14-6.1
) else if "%choice%" == "6" (
    if not exist "img\init_boot.img" (
        echo 错误: 未找到 img\init_boot.img 文件！
        echo 请将你的 init_boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\init_boot.img -m ko\android15-6.6_kernelsu.ko --kmi android15-6.6
) else if "%choice%" == "7" (
    if not exist "img\init_boot.img" (
        echo 错误: 未找到 img\init_boot.img 文件！
        echo 请将你的 init_boot.img 放入 img 目录后重试。
        pause
        exit /b 1
    )
    echo 正在执行补丁操作...
    ksud boot-patch -b img\init_boot.img -m ko\android16-6.12_kernelsu.ko --kmi android16-6.12
) else (
    echo 无效的选择: %choice%
    echo 请输入 1-7 之间的数字。
    pause
    exit /b 1
)

:: 检查 ksud 执行结果
if errorlevel 1 (
    echo.
    echo 错误: 补丁操作执行失败！
    echo 可能的原因:
    echo   1. ksud 版本不兼容
    echo   2. 启动镜像文件损坏
    echo   3. ko 文件与内核版本不匹配
    pause
    exit /b 1
)

:: 等待文件生成完毕（轮询检测而非固定等待）
echo.
echo 等待补丁文件生成...
set "WAIT_COUNT=0"
set "FOUND_IMG=0"
:WAIT_LOOP
if !WAIT_COUNT! GEQ 30 (
    echo 等待超时，未检测到生成的镜像文件。
    goto AFTER_WAIT
)
REM 检查当前目录是否有新的 .img 文件
for %%F in (*.img) do (
    set "FOUND_IMG=1"
)
if "!FOUND_IMG!"=="0" (
    set /a WAIT_COUNT+=1
    timeout /t 1 /nobreak >nul
    goto WAIT_LOOP
)
echo 检测到镜像文件已生成。
:AFTER_WAIT

:: 找出脚本当前目录下最新修改的文件并重命名
set "NEWEST_FILE="
set "NEWEST_PATH="
set "RENAME_SUCCESS=0"
:: dir /o-d 已按修改时间降序排列，取第一个即为最新文件
for /f "delims=" %%F in ('dir /b /o-d /t:w "*.img" 2^>nul') do (
    if not defined NEWEST_FILE (
        set "NEWEST_FILE=%%F"
        set "NEWEST_PATH=%CD%\%%F"
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
        set /a COUNTER+=1
        goto CHECK_NAME
    )
    if exist "!NEWEST_PATH!" (
        ren "!NEWEST_PATH!" "!NEW_NAME!"
        echo 生成的文件已重命名为 !NEW_NAME!
        set "RENAME_SUCCESS=1"
        goto END_RENAME
    )
) else (
    echo 未找到生成的 .img 文件，无法重命名。
    goto END_RENAME
)
:END_RENAME
if "!RENAME_SUCCESS!"=="0" (
    echo 未成功重命名文件，可能存在其他问题。
)

:: 询问是否删除 img 目录中的文件
echo.
echo 是否删除 img 文件夹中的所有文件? (y/n)
set /p del_choice=

if /i "!del_choice!"=="y" (
    if exist img\* (
        REM 删除 img 目录中的文件，但保留 git 占位文件
        set "DEL_COUNT=0"
        for %%f in (img\*) do (
            if /i not "%%~nxf"=="img目录.txt" (
                del /Q "%%f"
                set /a DEL_COUNT+=1
            )
        )
        echo 已删除 !DEL_COUNT! 个文件。
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
