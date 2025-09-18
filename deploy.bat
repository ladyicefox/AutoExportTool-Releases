@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ===== AutoExportTool 发布工具 =====
echo.

:: 检查 GitHub Token 环境变量
if "%GITHUB_TOKEN%"=="" (
    echo [错误] 未找到 GITHUB_TOKEN 环境变量
    echo 请设置 GITHUB_TOKEN 环境变量或使用以下命令：
    echo set GITHUB_TOKEN=您的Token
    pause
    exit /b 1
)

:: 检查是否在正确的目录中
if not exist ".git" (
    echo [错误] 当前目录不是Git仓库
    echo 正在检查是否在AutoExportTool-Releases目录中...
    
    if exist "AutoExportTool-Releases" (
        cd "AutoExportTool-Releases"
        if not exist ".git" (
            echo [错误] AutoExportTool-Releases目录也不是Git仓库
            echo 正在克隆远程仓库...
            cd ..
            git clone https://github.com/ladyicefox/AutoExportTool-Releases.git
            if !errorlevel! neq 0 (
                echo [错误] 克隆仓库失败
                pause
                exit /b 1
            )
            cd AutoExportTool-Releases
        )
    ) else (
        echo [信息] 克隆远程仓库...
        git clone https://github.com/ladyicefox/AutoExportTool-Releases.git
        if !errorlevel! neq 0 (
            echo [错误] 克隆仓库失败
            pause
            exit /b 1
        )
        cd AutoExportTool-Releases
    )
)

:: 获取当前版本
set CURRENT_VERSION=1.09
if exist "releases\latest\version.txt" (
    for /f "usebackq delims=" %%i in ("releases\latest\version.txt") do set CURRENT_VERSION=%%i
)

:: 显示当前版本并获取新版本号
echo 当前版本: !CURRENT_VERSION!
set /p NEW_VERSION="请输入新版本号 (当前: !CURRENT_VERSION!): "

:: 拉取最新更改
echo [更新] 拉取最新更改...
git fetch origin
git pull origin master
if !errorlevel! neq 0 (
    echo [警告] 拉取远程更改失败，继续本地操作
)

:: 智能差异检测系统 - 检测本地所有更改
echo [检测] 正在分析本地更改...
set "CHANGE_FOUND=0"
set "NEW_FILES=0"

:: 生成变更列表
git status --porcelain > changes.tmp

:: 处理变更文件
for /f "tokens=1,* delims= " %%a in (changes.tmp) do (
    set "change_type=%%a"
    set "file_path=%%b"
    
    if "!change_type!"=="??" (
        set "change_type=新增"
        set "NEW_FILES=1"
    ) else if "!change_type!"=="M" (
        set "change_type=修改"
    ) else if "!change_type!"=="D" (
        set "change_type=删除"
    ) else if "!change_type!"=="A" (
        set "change_type=添加"
    ) else if "!change_type!"=="R" (
        set "change_type=重命名"
    ) else if "!change_type!"=="C" (
        set "change_type=复制"
    )
    
    if not "!file_path!"=="" (
        set "CHANGE_FOUND=1"
        echo   !change_type!: !file_path!
    )
)

:: 如果有更改，自动提交
if !CHANGE_FOUND! equ 1 (
    echo [信息] 检测到本地有未提交的更改，正在提交...
    git add .
    git commit -m "自动提交本地更改 [!date! !time!]"
    git push origin master
    if !errorlevel! neq 0 (
        echo [错误] 推送本地更改失败
        echo 这可能是因为GitHub的推送保护功能
        echo 请检查代码中是否包含敏感信息
        pause
        exit /b 1
    )
) else (
    echo [信息] 未检测到本地更改
)

del changes.tmp >nul 2>&1

:: 创建新版本目录
if not exist "releases\v!NEW_VERSION!" (
    mkdir "releases\v!NEW_VERSION!"
)

:: 检查新版本文件是否存在，如果不存在则从本地构建目录复制
if not exist "releases\v!NEW_VERSION!\AutoExportTool_Pro_V!NEW_VERSION!.ms" (
    if exist "..\AutoExportTool_Pro_V!NEW_VERSION!.ms" (
        echo [复制] 从本地构建目录复制新版本文件...
        copy "..\AutoExportTool_Pro_V!NEW_VERSION!.ms" "releases\v!NEW_VERSION!\"
    ) else (
        echo [错误] 未找到新版本文件: AutoExportTool_Pro_V!NEW_VERSION!.ms
        echo 请确保文件已构建并放置在正确位置
        pause
        exit /b 1
    )
)

:: 创建发布说明文件
echo [文件] 创建 release_notes_v!NEW_VERSION!.txt 文件
(
echo 版本 !NEW_VERSION! 更新说明
echo ========================
echo.
echo 更新内容:
echo - 修复了已知问题
echo - 优化了性能
echo - 更新了用户界面
) > "releases\v!NEW_VERSION!\release_notes_v!NEW_VERSION!.txt"

:: 更新latest目录
echo [更新] 更新 latest 目录...
if not exist "releases\latest" mkdir "releases\latest"
copy "releases\v!NEW_VERSION!\AutoExportTool_Pro_V!NEW_VERSION!.ms" "releases\latest\AutoExportTool_Pro_Latest.ms" >nul
echo !NEW_VERSION! > "releases\latest\version.txt"

:: 更新版本清单
echo [更新] 更新版本清单...
if not exist "versions.json" (
    echo {^"versions^": []} > versions.json
)

:: 使用 PowerShell 更新 JSON 文件
powershell -Command "
$json = Get-Content -Path 'versions.json' -Raw | ConvertFrom-Json
$newVersion = @{ 
    'version' = '!NEW_VERSION!'; 
    'releaseDate' = Get-Date -Format 'yyyy-MM-dd'; 
    'releaseNotes' = 'releases/v!NEW_VERSION!/release_notes_v!NEW_VERSION!.txt';
    'downloadUrl' = 'https://github.com/ladyicefox/AutoExportTool-Releases/releases/download/v!NEW_VERSION!/AutoExportTool_Pro_V!NEW_VERSION!.ms'
}
if ($json.versions -eq $null) { $json | Add-Member -Name 'versions' -Value @() -MemberType NoteProperty }
$json.versions = @($json.versions | Where-Object { $_.version -ne '!NEW_VERSION!' })
$json.versions += $newVersion
$json.versions = $json.versions | Sort-Object { [version]$_.version } -Descending
$json | Add-Member -Name 'latest_version' -Value '!NEW_VERSION!' -MemberType NoteProperty -Force
$json | ConvertTo-Json -Depth 10 | Set-Content -Path 'versions.json'
"

:: 提交更改到Git
echo [提交] 提交更改到 Git...
git add .
git commit -m "发布新版本 v!NEW_VERSION!"
if !errorlevel! neq 0 (
    echo [警告] 提交更改失败，可能没有变化需要提交
)

:: 推送到远程仓库
echo [推送] 推送到远程仓库...
git push origin master
if !errorlevel! neq 0 (
    echo [错误] 推送到远程仓库失败
    echo 这可能是因为GitHub的推送保护功能
    echo 请检查代码中是否包含敏感信息
    pause
    exit /b 1
)

:: 创建标签（如果已存在则强制更新）
echo [标签] 创建版本标签 v!NEW_VERSION!...
git tag -f "v!NEW_VERSION!"
git push -f origin "v!NEW_VERSION!"
if !errorlevel! neq 0 (
    echo [错误] 创建标签失败
    pause
    exit /b 1
)

:: 创建GitHub Release
echo [发布] 创建 GitHub Release...

:: 使用curl创建Release
set RELEASE_NOTES=releases\v!NEW_VERSION!\release_notes_v!NEW_VERSION!.txt
set RELEASE_BODY=

for /f "usebackq delims=" %%i in ("!RELEASE_NOTES!") do (
    set "line=%%i"
    set "line=!line:"=\"!"
    set "line=!line:\=\\!"
    set "RELEASE_BODY=!RELEASE_BODY!!line!\n"
)

curl -s -X POST -H "Authorization: token %GITHUB_TOKEN%" ^
    -H "Content-Type: application/json" ^
    -d "{\"tag_name\": \"v!NEW_VERSION!\", \"name\": \"v!NEW_VERSION!\", \"body\": \"!RELEASE_BODY!\", \"draft\": false, \"prerelease\": false}" ^
    "https://api.github.com/repos/ladyicefox/AutoExportTool-Releases/releases"

if !errorlevel! neq 0 (
    echo [警告] 使用API创建Release失败，请手动创建
)

:: 上传文件到Release
echo [上传] 上传文件到GitHub Release...
for /f "tokens=2 delims=:" %%i in ('curl -s -H "Authorization: token %GITHUB_TOKEN%" "https://api.github.com/repos/ladyicefox/AutoExportTool-Releases/releases/tags/v!NEW_VERSION!" ^| findstr "upload_url"') do (
    set "UPLOAD_URL=%%i"
    set "UPLOAD_URL=!UPLOAD_URL:"=!"
    set "UPLOAD_URL=!UPLOAD_URL:{%?}=!"
    set "UPLOAD_URL=!UPLOAD_URL: =!"
)

if defined UPLOAD_URL (
    curl -s -X POST -H "Authorization: token %GITHUB_TOKEN%" ^
        -H "Content-Type: application/octet-stream" ^
        --data-binary "@releases\v!NEW_VERSION!\AutoExportTool_Pro_V!NEW_VERSION!.ms" ^
        "!UPLOAD_URL!?name=AutoExportTool_Pro_V!NEW_VERSION!.ms"
)

echo ===== 发布完成 =====
echo [版本] v!NEW_VERSION! 已发布
echo [页面] https://github.com/ladyicefox/AutoExportTool-Releases/releases/tag/v!NEW_VERSION!
echo.

:: 打开发布页面
start "" "https://github.com/ladyicefox/AutoExportTool-Releases/releases/tag/v!NEW_VERSION!"

pause