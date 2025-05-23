# KernelSU 自动更新与使用工具
## 一、项目简介
本项目包含一个Windows批处理脚本，旨在便捷地管理KernelSU相关的.ko文件。它能够自动检测KernelSU在GitHub上的最新版本，下载更新，并根据不同的Android系统内核版本对启动镜像进行补丁操作，同时还具备文件管理功能，如重命名和清理镜像文件，帮助用户更高效地使用KernelSU。

## 二、功能特性
1. **自动版本检测与更新**：脚本会定期查询GitHub上`tiann/KernelSU`仓库的最新版本，与本地记录的版本对比。若有新版本，自动下载指定的.ko文件，覆盖旧版本，确保用户使用的是最新的KernelSU功能。
2. **多版本.ko文件下载**：支持同时下载适用于不同Android系统内核版本的.ko文件，如`android12 - 5.10_kernelsu.ko`、`android13 - 5.10_kernelsu.ko`等，满足多种设备需求。
3. **启动镜像补丁处理**：根据用户选择的GKI版本（对应不同系统内核），使用`ksud boot - patch`命令结合`magiskboot.exe`对启动镜像（`boot.img`或`init_boot.img`）进行补丁操作，使系统支持KernelSU。
4. **文件管理**：下载前自动删除本地已存在的同名.ko文件，避免文件冲突。生成的镜像文件会自动重命名，方便用户识别和管理。还提供清理`img`目录文件的选项，保持工作目录整洁。

## 三、使用方法
1. **环境准备**
    - 确保系统已安装`curl`工具，用于与GitHub进行交互获取文件和版本信息。若未安装，可根据系统类型安装对应版本。
    - 准备好待处理的启动镜像文件，放置在脚本同目录下的`img`文件夹中。
2. **运行脚本**
    - 打开命令提示符（CMD），进入脚本所在目录。
    - 运行批处理脚本，脚本开始执行：
        - 首先获取GitHub上KernelSU的最新版本号，与本地存储在`ko\version.txt`中的版本号对比。
        - 若版本不同，开始下载最新的.ko文件到`ko`目录，并删除旧文件。
        - 下载完成后，提示用户选择GKI版本（1 - 6），根据系统内核版本选择对应选项。
        - 脚本根据选择对启动镜像进行补丁处理，处理完成后等待文件生成。
        - 查找并将生成的最新镜像文件重命名，方便管理。
        - 最后询问是否删除`img`目录中的所有文件，输入`y`或`n`确认。

## 四、代码结构与原理
1. **版本检测与下载**
    - 使用`curl`命令访问GitHub API（`https://api.github.com/repos/tiann/KernelSU/releases/latest`）获取最新版本信息。
    - 通过`findstr`命令从API响应中提取版本号，对比本地版本号。
    - 利用`curl`的下载功能，结合构建的下载链接（`https://github.com/tiann/KernelSU/releases/download/{最新版本号}/{文件名}`）下载文件，同时删除本地旧文件。
2. **启动镜像补丁处理**：依据用户选择的GKI版本，调用`ksud boot - patch`命令，传入启动镜像路径、对应的.ko文件路径和`magiskboot.exe`路径等参数，完成补丁操作。
3. **文件管理**：通过`dir`命令查找最新生成的`.img`文件，根据规则重命名。根据用户输入决定是否删除`img`目录下的所有文件。

## 五、问题与解决
1. **下载失败**：可能由于网络问题或GitHub API访问限制导致。检查网络连接，若频繁出现问题，可尝试更换网络环境或等待一段时间后重试。
2. **版本号写入失败**：若`version.txt`文件权限不足或路径错误，会导致写入失败。确保`ko`目录有写入权限，且文件路径正确。
3. **补丁操作失败**：可能是启动镜像文件损坏、.ko文件不兼容或`ksud`、`magiskboot.exe`工具异常。检查文件完整性，确认工具版本与系统兼容，必要时重新下载相关文件和工具。

## 六、参与贡献
1. **代码贡献**：欢迎开发者在GitHub仓库中提交Pull Request，优化代码逻辑、修复漏洞或添加新功能。提交前请确保代码风格一致，遵循项目已有结构。
2. **问题反馈**：使用过程中遇到问题，可在GitHub仓库的Issues板块提交详细问题描述，包括错误信息、操作步骤和系统环境，帮助项目维护者定位和解决问题。 
