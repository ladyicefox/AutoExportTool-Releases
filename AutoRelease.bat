@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ===== AutoExportTool 自动发布工具 =====
echo.

:: 检查 GitHub Token 环境变量
if "%GITHUB_TOKEN%"=="" (
    echo [错误] 未找到 GITHUB_TOKEN 环境变量
    echo 请设置 GITHUB_TOKEN 环境变量或使用以下命令：
    echo set GITHUB_TOKEN=您的Token
    pause
    exit /b 1
)

:: 设置仓库信息
set REPO_OWNER=ladyicefox
set REPO_NAME=AutoExportTool-Releases
set REPO_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%.git

:: 检查是否在正确的目录中
if not exist ".git" (
    echo [错误] 当前目录不是Git仓库
    echo 正在检查是否在 %REPO_NAME% 目录中...
    
    if exist "%REPO_NAME%" (
        cd "%REPO_NAME%"
        if not exist ".git" (
            echo [错误] %REPO_NAME% 目录也不是Git仓库
            echo 正在克隆远程仓库...
            cd ..
            git clone %REPO_URL%
            if !errorlevel! neq 0 (
                echo [错误] 克隆仓库失败
                pause
                exit /b 1
            )
            cd %REPO_NAME%
        )
    ) else (
        echo [信息] 克隆远程仓库...
        git clone %REPO_URL%
        if !errorlevel! neq 0 (
            echo [错误] 克隆仓库失败
            pause
            exit /b 1
        )
        cd %REPO_NAME%
    )
)

:: 拉取最新更改
echo [更新] 拉取最新更改...
git fetch origin
git pull origin master
if !errorlevel! neq 0 (
    echo [警告] 拉取远程更改失败，继续本地操作
)

:: 检测本地 MS 文件
echo [检测] 正在检测本地 MS 文件...
set "NEW_MS_FILE="
set "LATEST_VERSION=1.09"

:: 检查 releases/latest 目录中的版本
if exist "releases\latest\version.txt" (
    for /f "usebackq delims=" %%i in ("releases\latest\version.txt") do set LATEST_VERSION=%%i
)

echo 当前最新版本: !LATEST_VERSION!

:: 搜索本地是否有新版本的 MS 文件
for /f "delims=" %%f in ('dir /b /s ..\AutoExportTool_Pro_*.ms 2^>nul') do (
    set "filename=%%~nf"
    for /f "tokens=3 delims=_" %%v in ("!filename!") do (
        set "version=%%v"
        set "version=!version:v=!"
        
        :: 比较版本号
        echo 发现文件: !filename! 版本: !version!
        
        call :compare_versions !LATEST_VERSION! !version!
        if !errorlevel! equ 1 (
            echo [发现] 新版本文件: %%f
            set "NEW_MS_FILE=%%f"
            set "NEW_VERSION=!version!"
        )
    )
)

:: 如果没有找到新版本文件，提示用户输入
if "!NEW_MS_FILE!"=="" (
    echo [信息] 未检测到新版本文件
    set /p NEW_VERSION="请输入新版本号 (当前: !LATEST_VERSION!): "
    
    :: 检查是否有对应版本的 MS 文件
    if exist "..\AutoExportTool_Pro_V!NEW_VERSION!.ms" (
        set "NEW_MS_FILE=..\AutoExportTool_Pro_V!NEW_VERSION!.ms"
    ) else (
        echo [错误] 未找到版本 !NEW_VERSION! 的 MS 文件
        echo 请确保文件已构建并放置在正确位置
        pause
        exit /b 1
    )
) else (
    echo [发现] 自动检测到新版本: !NEW_VERSION!
    set /p CONFIRM="是否发布版本 !NEW_VERSION!? (Y/N): "
    if /i not "!CONFIRM!"=="Y" (
        echo 取消发布
        pause
        exit /b 0
    )
)

:: 创建新版本目录
if not exist "releases\v!NEW_VERSION!" (
    mkdir "releases\v!NEW_VERSION!"
)

:: 复制 MS 文件到发布目录
echo [复制] 复制 MS 文件到发布目录...
copy "!NEW_MS_FILE!" "releases\v!NEW_VERSION!\AutoExportTool_Pro_V!NEW_VERSION!.ms" >nul

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
echo.
echo 发布日期: %date% %time%
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
    'downloadUrl' = 'https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/download/v!NEW_VERSION!/AutoExportTool_Pro_V!NEW_VERSION!.ms'
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

:: 创建标签
echo [标签] 创建版本标签 v!NEW_VERSION!...
git tag -a "v!NEW_VERSION!" -m "Release version !NEW_VERSION!"
if !errorlevel! neq 0 (
    echo [错误] 创建标签失败
    pause
    exit /b 1
)

:: 推送标签到 GitHub
echo [推送] 推送标签到 GitHub...
git push origin "v!NEW_VERSION!"
if !errorlevel! neq 0 (
    echo [错误] 推送标签失败
    pause
    exit /b 1
)

:: 等待 GitHub 同步标签
echo [等待] 等待 GitHub 同步标签 (10秒)...
timeout /t 10 /nobreak >nul

:: 尝试使用 API 创建 Release
echo [发布] 尝试使用 GitHub API 创建 Release...

:: 读取发布说明内容
set "RELEASE_NOTES_FILE=releases\v!NEW_VERSION!\release_notes_v!NEW_VERSION!.txt"
set "RELEASE_BODY="
for /f "usebackq tokens=*" %%i in ("%RELEASE_NOTES_FILE%") do (
    set "line=%%i"
    set "line=!line:"=\"!"
    set "line=!line:&=^&amp;!"
    set "line=!line:<=^&lt;!"
    set "line=!line:>=^&gt;!"
    set "RELEASE_BODY=!RELEASE_BODY!!line!\n"
)

:: 创建 JSON 数据文件
echo {^"tag_name^": ^"v!NEW_VERSION!^", ^"name^": ^"v!NEW_VERSION!^", ^"body^": ^"!RELEASE_BODY!^", ^"draft^": false, ^"prerelease^": false} > release_data.json

:: 创建 Release
curl -s -o release_response.json -X POST -H "Authorization: token %GITHUB_TOKEN%" ^
    -H "Content-Type: application/json" ^
    --data-binary "@release_data.json" ^
    "https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases"

:: 检查 Release 是否创建成功
set "RELEASE_CREATED=0"
for /f "tokens=*" %%i in ('type release_response.json ^| findstr /i "message"') do (
    echo [错误] 创建 Release 失败: %%i
    echo 请检查 release_response.json 文件获取详细信息
    set "RELEASE_CREATED=0"
    goto :check_release
)

:: 获取上传 URL
set "UPLOAD_URL="
for /f "tokens=2 delims=:" %%i in ('type release_response.json ^| findstr "upload_url"') do (
    set "UPLOAD_URL=%%i"
    set "UPLOAD_URL=!UPLOAD_URL:"=!"
    set "UPLOAD_URL=!UPLOAD_URL:{%?}=!"
    set "UPLOAD_URL=!UPLOAD_URL: =!"
)

if not defined UPLOAD_URL (
    echo [错误] 无法获取上传 URL
    type release_response.json
    set "RELEASE_CREATED=0"
    goto :check_release
)

:: 上传文件到 Release
echo [上传] 上传文件到 GitHub Release...
curl -s -o upload_response.json -X POST -H "Authorization: token %GITHUB_TOKEN%" ^
    -H "Content-Type: application/octet-stream" ^
    --data-binary "@releases\v!NEW_VERSION!\AutoExportTool_Pro_V!NEW_VERSION!.ms" ^
    "!UPLOAD_URL!?name=AutoExportTool_Pro_V!NEW_VERSION!.ms"

:: 检查上传是否成功
for /f "tokens=*" %%i in ('type upload_response.json ^| findstr /i "error message"') do (
    echo [错误] 上传文件失败: %%i
    echo 请检查 upload_response.json 文件获取详细信息
    set "RELEASE_CREATED=0"
    goto :check_release
)

echo [成功] 文件上传成功!
set "RELEASE_CREATED=1"

:check_release
:: 清理临时文件
del release_data.json >nul 2>&1
del release_response.json >nul 2>&1
del upload_response.json >nul 2>&1

:: 如果 API 创建 Release 失败，提供手动创建指南
if !RELEASE_CREATED! equ 0 (
    echo.
    echo [信息] GitHub API 创建 Release 失败，请手动创建
    echo [步骤] 1. 访问: https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/new
    echo [步骤] 2. 选择标签: v!NEW_VERSION!
    echo [步骤] 3. 填写标题: v!NEW_VERSION!
    echo [步骤] 4. 添加描述（从 releases\v!NEW_VERSION!\release_notes_v!NEW_VERSION!.txt 复制）
    echo [步骤] 5. 上传文件: releases\v!NEW_VERSION!\AutoExportTool_Pro_V!NEW_VERSION!.ms
    echo [步骤] 6. 点击发布
    echo.
    echo [提示] 标签已创建并推送，只需完成上述步骤即可
)

echo ===== 发布完成 =====
echo [版本] v!NEW_VERSION! 已发布
echo [页面] https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/tag/v!NEW_VERSION!
echo.

:: 打开发布页面
start "" "https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/tag/v!NEW_VERSION!"

pause
exit /b 0

:: 版本比较函数
:compare_versions
setlocal
set "ver1=%~1"
set "ver2=%~2"

:: 将版本号转换为可比较的格式
for /f "tokens=1,2 delims=." %%a in ("%ver1%") do (
    set "major1=%%a"
    set "minor1=%%b"
)
for /f "tokens=1,2 delims=." %%a in ("%ver2%") do (
    set "major2=%%a"
    set "minor2=%%b"
)

:: 比较版本号
if %major2% gtr %major1% exit /b 1
if %major2% equ %major1% if %minor2% gtr %minor1% exit /b 1
exit /b 0