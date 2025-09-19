--Maxscript
--rollout AutoExportTool_Pro ;批量导出FBX/Bip动作资源-Pro"//专业版文件浏览器/批量处理max文件（FBX；BIP--批量导出导入;一键换皮（批量导入 BIP ,xaf)

--@Author1: Bullet.S 子弹（灵感以及核心代码）BsOpenTools （参考功能布局联动思路，UI功能框架等）ps :推荐 子弹的 工具集 （适合 动画师 日常 核心 K 帧 ）
--@Author2: 天晴 / NDTools （灵感以及核心代码）批量导出_FBX动作资源_v3.0 （参考框架）

--@author3: 叶秋丶zZ / AutoExportTool_Pro_V1.0 / Email：240811498@qq.com 
 --Last Design Time : 2025.08.24 / Designed By Fchen ;

-- 全局变量定义 ================================================================
-- 全局函数定义（放在 rollout 外部..
--FBXExportTools_Config.ini（常用路径-目录/写入保存读取--true--功能测试OK-/2025.03
--FBXExportTools_UI.ini （列表颜色设置，勾选项状态记录，部分UI 状态记录 ----true--功能测试OK-/2025.03
--RecentDocuments.xml（最近打开文件/写入保存读取--true--功能测试OK-/2025.03
--processSkinReplacement (核心换皮功能函数;一键换皮)--true--功能测试OK-/2025.05
--列表文件可编辑性功能：右键选中OR框选单个/批量删除，复制，剪切，粘贴文件或者文件夹，打开/运行/导入，查看文件属性（文件夹不支持查看属性！） ; 便捷双击打开/导入  各种 格式的文件等..

--详细核心功能概括以及使用说明书-见--（AutoExportTool.text or 功能介绍+使用说明）https://ladyicefox.github.io/autoexporttool-docs/  （常用插件-个人觉得无需看说明书...）

----------------------------------------------------------------
-- ===================== 新增功能模块 ===========================
----------------------------------------------------------------
--独立函数必须声明为全局；局部函数放在 rollout 内部（相同的函数一般先执行局部的函数）全局函数语法例子：global xxx = fn xxx = (...
----------------------------------------------------------------
----------------------------------------------------------------

--开发者日志：-- false (沉淀代码/备用)
--global g_debugMode = true  -- 在全局变量区域添加
--fn logDebug msg = (
    --if g_debugMode do (
        --format "DEBUG: %\n" msg
        --flushListener()
    --)
--)
--版本记录 V1.0;V1.01；V1.02 ,V1.02-1/ V1.03；V1.03-1 ；V1.04..V1.04-1 ;V1.05,V1.05-1；V1.06，V1.06-1；V1.07，V1.07-1；V1.08 ； V1.09 ；V1.10
-- ===== 在脚本开头定义全局变量 =====
-- 初始化管理器//FBX属性初始化-------------------------------------
FbxExporterSetParam "ResetExport"         -- 重置FBX导出设置
----------------------------------------------------------------
-- 全局变量定义 / 批量合并列表的公共挂点文件 目标 到 列表的 所有文件和文件夹内的所有文件，合并文件内所有以及选择集，挂点各自对齐链接到对应的目标骨骼并保存新文件覆盖到目标文件夹
----------------------------------------------------------------AutoExportTool_Pro.
-- 版本信息 / 热更正式版本 AutoExportTool_Pro / 全局

global g_currentVersion = "1.09"
global g_latestVersion = g_currentVersion
global g_updateAvailable = false 
global g_autoCheckUpdate = false -- 默认关闭自动检查，避免启动卡顿

-- 直接获取版本信息（备选方案）
global getVersionInfoDirect = fn getVersionInfoDirect = (
    try (
        -- 直接从固定格式的 URL 获取最新版本
        local latestVersion = "1.09" -- 硬编码最新版本号
        
        -- 构建下载 URL
        local downloadUrl = "https://github.com/ladyicefox/AutoExportTool-Releases/releases/download/v" + 
                           latestVersion + "/AutoExportTool_Pro_V" + latestVersion + ".ms"
        
        -- 构建更新说明
        local changelog = "版本 " + latestVersion + " 更新说明\n" +
                         "======================\n\n" +
                         "更新内容:\n" +
                         "- 修复了已知问题\n" +
                         "- 优化了性能\n" +
                         "- 更新了用户界面"
        
        return #(latestVersion, downloadUrl, changelog)
    )
    catch (
        format "[直接获取错误] %\n" (getCurrentException())
    )
    undefined
)

-- 处理版本信息 / 热更 / 版本检测
global processVersionInfo = fn processVersionInfo versionInfo silent:false = (
    local latestVersion = versionInfo[1]
    local downloadUrl = versionInfo[2]
    local changelog = versionInfo[3]
    
    g_latestVersion = latestVersion
    
    -- 简单版本比较
    fn compareVersions v1 v2 = (
        local v1Parts = filterString v1 "."
        local v2Parts = filterString v2 "."
        
        for i = 1 to (amax v1Parts.count v2Parts.count) do (
            local part1 = if i <= v1Parts.count then (execute v1Parts[i]) else 0
            local part2 = if i <= v2Parts.count then (execute v2Parts[i]) else 0
            
            if part2 > part1 do return true
            if part2 < part1 do return false
        )
        false
    )
    
    g_updateAvailable = compareVersions g_currentVersion latestVersion
    
    -- 更新菜单项文本
    local updateText = if g_updateAvailable then "🔄 检测更新 NEW❗ |【CheckUpdate】" else "🔄 检测更新 |【CheckUpdate】"
    
    if g_updateAvailable and not silent do (
        local msg = "当前版本: v" + g_currentVersion + "\n最新版本: v" + latestVersion
        
        if changelog != "" and changelog != undefined do (
            msg += "\n\n更新内容:\n" + changelog
        )
        
        msg += "\n\n是否要更新到最新版本？"
        
        local result = queryBox msg title:"发现新版本"
        if result do (
            -- 执行更新
            downloadAndUpdate downloadUrl
        )
    )
    
    if not g_updateAvailable and not silent do (
        messageBox "当前已经是最新版本。" title:"更新检查"
    )
    
    -- 返回更新状态
    g_updateAvailable
)

-- 下载并更新插件 / 热更 / 版本检测
global downloadAndUpdate = fn downloadAndUpdate downloadUrl = (
    try (
        -- 创建备份目录
        local backupDir = (getDir #userScripts) + "\\AutoExportTool_Backup\\"
        makeDir backupDir all:true
        
        -- 备份当前版本
        local currentScript = getSourceFileName()
        local backupFile = backupDir + "AutoExportTool_Pro_V" + g_currentVersion + ".ms"
        copyFile currentScript backupFile
        
        -- 下载新版本
        local webClient = dotNetObject "System.Net.WebClient"
        local tempFile = (getDir #temp) + "\\AutoExportTool_Pro_V" + g_latestVersion + ".ms"
        
        -- 显示下载进度
        format "[下载] 开始下载新版本: %\n" downloadUrl
        webClient.DownloadFile downloadUrl tempFile
        
        -- 验证下载的文件
        if doesFileExist tempFile and (getFileSize tempFile) > 0 then (
            format "[下载] 文件下载成功，大小: % 字节\n" (getFileSize tempFile)
            
            -- 关闭当前对话框
            try (
                if (isDialogVisible AutoExportTool_Pro) do (
                    destroyDialog AutoExportTool_Pro
                )
            ) catch ()
            
            -- 替换当前文件
            deleteFile currentScript
            copyFile tempFile currentScript
            
            -- 更新自启动脚本（如果启用）
            if g_autoStartEnabled do (
                local startupScripts = getDir #userStartupScripts
                local scriptPath = startupScripts + "\\AutoExportTool_Pro_AutoStart.ms"
                
                if doesFileExist scriptPath do (
                    deleteFile scriptPath
                )
                
                -- 创建新的自启动脚本
                local loadCmd = "fileIn @\"" + currentScript + "\""
                local autoStartScript = 
                    "global g_autoStartPluginLoaded = true\n" +
                    "try ( \n" + 
                    "   " + loadCmd + " \n" + 
                    "   if (isDialogVisible AutoExportTool_Pro) do (destroyDialog AutoExportTool_Pro) \n" +
                    "   createDialog AutoExportTool_Pro \n" +
                    ") catch ( \n" +
                    "   format \"[插件加载失败] %\\\\n\" (getCurrentException()) \n" +
                    ")"
                
                local f = createFile scriptPath
                format "%\n" autoStartScript to:f
                close f
            )
            
            -- 重新加载插件
            fileIn currentScript
            createDialog AutoExportTool_Pro
            
            messageBox "更新成功！已更新到 v" + g_latestVersion title:"更新完成"
            return true
        )
        else (
            messageBox "下载的文件无效，更新失败。" title:"更新错误"
            return false
        )
    )
    catch (
        format "[更新错误] %\n" (getCurrentException())
        messageBox "更新过程中发生错误: " + (getCurrentException()) title:"更新错误"
        return false
    )
)

-- 简化版本检测函数 / 热更 / 版本检测
global checkForUpdates = fn checkForUpdates silent:false = (
    try (
        format "[版本检查] 开始检查更新...\n"
        
        -- 使用直接获取版本信息的方法
        format "[版本检查] 使用直接获取方法\n"
        local versionInfo = getVersionInfoDirect()
        
        if versionInfo != undefined do (
            format "[版本检查] 获取到版本信息: %\n" versionInfo
            -- 比较版本并提示更新
            return processVersionInfo versionInfo silent:silent
        )
        
        if versionInfo == undefined and not silent do (
            format "[版本检查] 无法获取版本信息\n"
            messageBox "无法检查更新，请稍后重试。" title:"更新错误"
        )
    )
    catch (
        if not silent do (
            format "[版本检查错误] %\n" (getCurrentException())
            messageBox "检查更新时发生错误: " + (getCurrentException()) title:"更新错误"
        )
    )
    
    false
)

-- 添加版本缓存功能（可选）
global g_versionCacheFile = (getDir #temp) + "\\AutoExportTool_VersionCache.txt"
global g_versionCacheTime = 24 * 60 * 60 * 1000 -- 24小时缓存

global getCachedVersionInfo = fn getCachedVersionInfo = (
    if doesFileExist g_versionCacheFile and ((getFileModDate g_versionCacheFile) + g_versionCacheTime > currentTime) then (
        try (
            local f = openFile g_versionCacheFile
            local versionInfo = readValue f
            close f
            return versionInfo
        )
        catch (
            format "[缓存读取错误] %\n" (getCurrentException())
        )
    )
    undefined
)

global cacheVersionInfo = fn cacheVersionInfo versionInfo = (
    try (
        local f = createFile g_versionCacheFile
        writeValue versionInfo to:f
        close f
    )
    catch (
        format "[缓存写入错误] %\n" (getCurrentException())
    )
)

-- 增强版本检测函数（带缓存）
global checkForUpdatesEnhanced = fn checkForUpdatesEnhanced silent:false = (
    try (
        format "[版本检查] 开始检查更新（增强版）...\n"
        
        -- 首先尝试从缓存获取
        local versionInfo = getCachedVersionInfo()
        
        if versionInfo == undefined then (
            -- 缓存不存在或已过期，使用直接获取方法
            format "[版本检查] 缓存未命中，使用直接获取方法\n"
            versionInfo = getVersionInfoDirect()
            
            -- 缓存结果
            if versionInfo != undefined do (
                cacheVersionInfo versionInfo
            )
        )
        else (
            format "[版本检查] 使用缓存版本信息\n"
        )
        
        if versionInfo != undefined do (
            format "[版本检查] 获取到版本信息: %\n" versionInfo
            -- 比较版本并提示更新
            return processVersionInfo versionInfo silent:silent
        )
        
        if versionInfo == undefined and not silent do (
            format "[版本检查] 无法获取版本信息\n"
            messageBox "无法检查更新，请稍后重试。" title:"更新错误"
        )
    )
    catch (
        if not silent do (
            format "[版本检查错误] %\n" (getCurrentException())
            messageBox "检查更新时发生错误: " + (getCurrentException()) title:"更新错误"
        )
    )
    
    false
)

-- 初始化时不自动检查更新，避免卡顿
-- 用户可以通过菜单手动检查更新

-- 全局函数：高亮显示当前打开的文件（优化版）
global highlightCurrentFile = fn highlightCurrentFile = (
    try (
        if AutoExportTool_Pro.Lv_model != undefined and not AutoExportTool_Pro.Lv_model.IsDisposed do (
            -- 清除所有现有高亮
            for i = 0 to (AutoExportTool_Pro.Lv_model.Items.Count - 1) do (
                local item = AutoExportTool_Pro.Lv_model.Items.Item[i]
                item.BackColor = AutoExportTool_Pro.Lv_model.BackColor  -- 恢复默认背景色
            )
            
            -- 获取当前打开的文件名
            local currentFileName = maxFileName
            if currentFileName != undefined and currentFileName != "" do (
                -- 在列表中查找当前文件
                for i = 0 to (AutoExportTool_Pro.Lv_model.Items.Count - 1) do (
                    local item = AutoExportTool_Pro.Lv_model.Items.Item[i]
                    local itemPath = item.Tag as String
                    
                    -- 检查是否是文件（不是文件夹）并且文件名匹配
                    if not (matchPattern itemPath pattern:"*[DIR]*") and (filenameFromPath itemPath) == currentFileName do (
                        -- 选中该项
                        item.Selected = true
                        item.Focused = true
                        
                        -- 确保该项可见（滚动到视图）
                        item.EnsureVisible()
                        
                        -- 设置高亮颜色
                        item.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 70 130 180 -- 钢蓝色
                        
                        format "[自动高亮] 当前文件: %\n" currentFileName
                        exit -- 找到后退出循环
                    )
                )
            )
        )
    )
    catch (
        format "[高亮错误] %\n" (getCurrentException())
    )
)

-- 创建文件打开回调函数，在文件打开后自动更新钢印
global setupFileOpenCallback = fn setupFileOpenCallback = (
    -- 保存原始的文件打开函数
    global originalFileOpen = fileOpen
    
    -- 重写文件打开函数
    fn newFileOpen filename useFileUnits:false quiet:false = (
        local result = originalFileOpen filename useFileUnits:useFileUnits quiet:quiet
        
        -- 文件打开后，延迟一段时间然后更新钢印
        if result do (
            dotNet.invokeMethod (dotNetClass "System.Threading.Thread") "Sleep" 300
            highlightCurrentFile()
        )
        
        return result
    )
    
    -- 替换原始函数
    fileOpen = newFileOpen
)

----------------------------------------------------------------
-- 全局变量：存储合并文件路径
global g_mergeFilePath = undefined

-- 结构体：存储挂点对齐信息
struct SocketAlignmentInfo (
    socketNode,
    targetBone,
    originalTransform,
    originalParent
)
----------------------------------------------------------------
--全局变量声明 / 常用目录自动填充相关 
global g_tempPathForManager = ""
global g_pathManagerDialogOpen = false
----------------------------------------------------------------
-- 在全局变量区域添加角色映射表 / 导出到引擎 / 备用 / 沉淀代码 （ 当前版本V1.0 实际 不用 ）
struct CharacterMapping (name, dir)
global g_characterMappings = #()  -- 存储 #(localName, engineName) 的数组
global g_characterMappingPath = (getDir #plugcfg) + "\\CharacterMappings.ini"
global g_engineProjectPath = ""
global g_exportToEngine = false
----------------------------------------------------------------
-- 加载角色映射
global loadCharacterMappings = fn loadCharacterMappings = (
    g_characterMappings = #()
    if doesFileExist g_characterMappingPath do (
        local count = getINISetting g_characterMappingPath "Mappings" "Count" as integer
        for i = 1 to count do (
            local name = getINISetting g_characterMappingPath ("Mapping" + i as string) "Local"
            local dir = getINISetting g_characterMappingPath ("Mapping" + i as string) "Engine"
            if name != "" and dir != "" do (
                append g_characterMappings (CharacterMapping name:name dir:dir)
            )
        )
    )
)
----------------------------------------------------------------
-- 在全局区域添加备份路径变量
global g_pluginPath = getSourceFileName()  -- 自动获取当前脚本路径
global g_backupPluginPath = (getDir #userScripts) + "\\AutoExportTool_Backup\\" + filenameFromPath g_pluginPath + getFilenameType g_pluginPath
global g_backupPluginPath1 = (getDir #userScripts) 
global g_autoStartEnabled = false
------------------------------------------------------------
-- 插件窗口的拖动功能 / 功能测试 = true
-- ====== 全局变量 ======
global g_dragging = false
global g_dragStartPos = [0,0]
global g_windowStartPos = [0,0]
----------------------------------------------------------------
-- 新增全局变量 / 功能测试 = true
global g_clipboard = #()  -- 存储复制的文件/文件夹路径
global g_clipboardType = "copy" -- "copy" 或 "cut" = 复制状态 *2
global g_autoStartEnabled = false  -- 是否随3ds Max自启
global g_toolbarAdded = false  -- 工具栏是否已添加

--左键单击触发重命名
global g_lastClickItem = undefined   -- 点击列表文件/操作项
global g_lastClickTime = 0            -- 点击列表文件/时间项

----------------------------------------------------------------
-- 全局变量存储编辑状态
global g_editingItem = undefined      -- 右键文件 / 菜单 重命名 （原地编辑列表文件+文件夹）
global g_editTextBox = undefined        -- 右键文件 / 菜单 重命名 （原地编辑添加+编辑框/列表文件+文件夹）
global g_UIConfigPath = (getDir #plugcfg) + "\\AutoExportTool_Pro.ini"
-- 初始化时读取自启状态/初始化 读取 记录 自启 菜单 勾选 / 持久化 设定 / 功能测试 = true
global initAutoStartSetting = fn initAutoStartSetting = (
    g_autoStartEnabled = (getINISetting g_UIConfigPath "Settings" "AutoStart") == "true"
)

-- 初始化工具栏状态
global initToolbarSetting = fn initToolbarSetting = (
    try (
        local setting = getINISetting g_UIConfigPath "Settings" "ToolbarAdded"
        if setting == "" then (
            setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "false"
            g_toolbarAdded = false
        ) else (
            g_toolbarAdded = setting == "true"
        )
    )
    catch (
        format "[工具栏设置初始化错误] %\n" (getCurrentException())
        g_toolbarAdded = false
    )
)
-- 工具栏-卸载函数 / 备用1
global removeToolbarFromMax1 = fn removeToolbarFromMax1 = (
    try (
        local mainMenu = menuMan.getMainMenuBar()
        local subMenu = menuMan.findMenu "AutoExportTool"
        
        if subMenu != undefined do (
            menuMan.unRegisterMenu subMenu
            menuMan.updateMenuBar()
            g_toolbarAdded = false
            setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "false"
            messageBox "工具栏已成功移除" title:"成功"
        )
      -- 更新工具栏状态
        g_toolbarAdded = false
        setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "false"
    ) catch (
        format "[工具栏移除错误] %\n" (getCurrentException())
        messageBox ("工具栏移除失败: " + (getCurrentException())) title:"错误"
    )
)
-- 工具栏-卸载函数 / 外部 菜单 栏 工具宏  
global removeToolbarFromMax = fn removeToolbarFromMax = (
    try (
        local mainMenu = menuMan.getMainMenuBar()
        local subMenu = menuMan.findMenu "AutoExportTool"
        
        if subMenu != undefined do (
            menuMan.unRegisterMenu subMenu
            menuMan.updateMenuBar()
            messageBox "工具栏已成功移除" title:"成功"
        )
      
        -- 更新工具栏状态
        g_toolbarAdded = false
        setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "false"
        
        -- 同时移除自启动脚本（如果存在）
        local startupScripts = getDir #userStartupScripts
        local scriptPath = startupScripts + "\\AutoExportTool_Pro_AutoStart.ms"
        if doesFileExist scriptPath do (
            deleteFile scriptPath
            format "[自启脚本] 已移除: %\n" scriptPath
        )
    ) catch (
        format "[工具栏移除错误] %\n" (getCurrentException())
        messageBox ("工具栏移除失败: " + (getCurrentException())) title:"错误"
    )
)

--工具栏-自启跟随 MAX / 外部 菜单 栏 工具宏 + 内部Roullout
global toggleAutoStart = fn toggleAutoStart = (
    g_autoStartEnabled = not g_autoStartEnabled
    setINISetting g_UIConfigPath "Settings" "AutoStart" (g_autoStartEnabled as string)
    
    local startupScripts = getDir #userStartupScripts
    local scriptPath = startupScripts + "\\AutoExportTool_Pro_AutoStart.ms"
    
    if g_autoStartEnabled then (
        AutoExportTool_Pro.addToolbarToMax()
        -- 创建自启脚本
        local loadCmd = "fileIn @\"" + g_pluginPath + "\""
        
        local autoStartScript = 
            "global g_autoStartPluginLoaded = true\n" +
            "try ( \n" + 
            "   " + loadCmd + " \n" + 
            "   if (isDialogVisible AutoExportTool_Pro) do (destroyDialog AutoExportTool_Pro) \n" +
            "   createDialog AutoExportTool_Pro \n" +
            ") catch ( \n" +
            "   format \"[插件加载失败] %\\\\n\" (getCurrentException()) \n" +
            ")"
        
        try (
            local f = createFile scriptPath
            format "%\n" autoStartScript to:f
            close f
            format "[自启脚本] 已创建: %\n" scriptPath
        ) catch (
            format "[自启脚本创建失败] %\n" (getCurrentException())
        )
    ) else (
        -- 只禁用自启但不删除文件，保持工具栏可用 
        try (
            removeToolbarFromMax1()
            g_toolbarAdded = false
           -- 不删除自启动脚本，而是修改其内容为禁用状态
            local disableScript = 
                "-- 自启功能已禁用\n" +
                "-- 如需重新启用，请使用AutoExportTool插件设置\n" +
                "format \"AutoExportTool自启功能当前已禁用\\n\"\n" +
                "-- 但仍然保留工具栏功能\n" +
                "try (\n" +
                "   fileIn (getDir #userScripts + \"\\\\AutoExportTool_Backup\\\\\" + (getFiles (getDir #userScripts + \"\\\\AutoExportTool_Backup\\\\AutoExportTool_Pro*.ms\"))[1])\n" +
                "   if not (isDialogVisible AutoExportTool_Pro) do createDialog AutoExportTool_Pro\n" +
                ") catch (\n" +
                "   format \"[工具栏加载失败] %\\\\n\" (getCurrentException())\n" +
                ")"
            
            local f = createFile scriptPath
            
            format "%\n" disableScript to:f
            close f
            format "[自启脚本] 已禁用但工具栏保持可用\n"
        ) catch (
            format "[自启脚本禁用失败] %\n" (getCurrentException())
        )
    )
    
    -- 更新状态
    if (isKindOf AutoExportTool_Pro rolloutClass) and (isDialogVisible AutoExportTool_Pro) do (
        g_lastAction = "自启设置: " + (if g_autoStartEnabled then "开启" else "关闭")
        AutoExportTool_Pro.updateModeStatus()
    )
)

-- 帮助菜单功能/功能测试OK- true( 对接 外部宏菜单/工具栏链接 ，需设定为全局函数！！！)
global openHelpLink = fn openHelpLink url = (
    try (
        if url == undefined or url == "" then (
            messageBox "链接未设置" title:"提示"
        ) else (
            shellLaunch "explorer.exe" url
        )
    ) catch (
        format "[链接打开错误] %\n" (getCurrentException())
    )
)

-- ===================== MAX  文件整理模块 =====================
-- 文件归档//在全局结构体定义区域添加
struct FileGroup (
    baseName,      -- 基础文件名（不含版本标识）
    originalFile,  -- 原始文件（无数字后缀）
    latestFile,    -- 最新版本文件
    maxNumber      -- 最大版本号
)
----------------------------------------------------------------
--添加全局变量记录最后操作 ----------------------------------------
global g_lastAction = "🦾待命⌘💤"
----------------------------------------------------------------
-- 在全局变量区域//一键换皮-文件转存路径/文件夹创建名称..
-- 全局变量记录插件路径
global g_pluginPath = getSourceFileName()  -- 自动获取当前脚本路径
global g_skinExportPath = ""
global g_skinNewFolderName = "SkinReplace_Output"  --  一键换皮储存 // 文件夹 / 名称 
global g_rotationMode = #tcb  -- #tcb或#euler
global g_useCustomRotation = false
global g_excludePrefix = "v_"  -- 排除前缀
----------------------------------------------------------------
-- 配置文件路径/BIP 批量导入（通用进度条更新）
global g_currentBipProgress = 0
-- 进度定时器（保持与其他模块一致） -- 沉淀函数 -false (一般false 表示 可能没有引用 或者 沉淀函数 作备用,or 功能未实现)
global g_bipProgressTimer = dotNetObject "System.Windows.Forms.Timer"
g_bipProgressTimer.Interval = 500
dotNet.addEventHandler g_bipProgressTimer "Tick" (
    fn updateBipProgress = (
        if g_currentBipProgress > 0 and g_currentBipProgress < 100 do (
            pbProgress.value = g_currentBipProgress
            lblProgressInfo.text += "."
            if lblProgressInfo.text.count > 50 do lblProgressInfo.text = substring lblProgressInfo.text 1 50
        )
    )
)

-- 版本兼容的Biped创建（扩展版）
global createCompatibleBiped = fn createCompatibleBiped = (
    case (maxVersion())[1] of (
        24000: BipedSys.createBiped showMenu:false  -- 2023+
        23000: BipedSys.createBiped()              -- 2022
        21000: BipedSys.createBiped()              -- 2021
        default: BipedSys.CreateBipedNode "Bip001" -- 2018及以下
    )
)

-- 在全局变量区域添加BIP版本控制变量
global g_bipImportVersion = 24000 -- 根据当前Max版本设置
global g_sceneSetsCache = #()
global g_processPaused = false

----------------------------------------------------------------
-- 全局函数定义 / 版本兼容（放在 rollout 外部）/ false / 未验证 / 沉淀代码 / 备用
global getConvertUnitParam = fn getConvertUnitParam =  
(
    case (maxVersion())[1] of
    (
        19000: true    -- 2019 (对应代码19000)
        20000: true    -- 2020 (对应代码20000)
        21000: #cm     -- 2021 (代码21000)
        22000: #cm     -- 2022 (代码24000)
        23000: #cm     -- 2023 (代码25000)
        24000: #cm     -- 2024 (代码26000)
        default: #cm   -- 未来版本默认
    )
)
----------------------------------------------------------------
try(global saveConfig = undefined)catch()  -- 强制清除旧定义--保存    
try(global loadConfig = undefined)catch()   -- 强制清除旧定义--读取
----------------------------------------------------------------
-- 在结构体定义区域添加//批量选择集
struct selsetBatchConfig (
    autoCreateDir = true,
    targetFolder = "",
    overwrite = false
)
global g_selsetBatchCfg = selsetBatchConfig()
----------------------------------------------------------------
-- 颜色配置结构//文件/文件夹-颜色设置
struct colorConfig (
    folderNameColor = (dotNetClass "System.Drawing.Color").Yellow,  -- 文件夹名称颜色 -- true = file = set colour/all (文件夹+图标/颜色一起设置)
    --folderIconColor = (dotNetClass "System.Drawing.Color").SlateGray,  -- 文件夹图标颜色 -- false
    fileNameColor = (dotNetClass "System.Drawing.Color").White  -- 文件名称颜色      -- true = file = set colour/all (文件+图标/颜色一起设置)
    --fileIconColor = (dotNetClass "System.Drawing.Color").SteelBlue, -- 文件图标颜色
    --maxFileColor = (dotNetClass "System.Drawing.Color").DarkBlue, -- 暗蓝 false
    --fbxFileColor = (dotNetClass "System.Drawing.Color").DarkGreen  -- 暗绿 false
    --modeAutoColor = (dotNetClass "System.Drawing.Color").Blue,      -- 蓝色 false
    --modeSkinColor = (dotNetClass "System.Drawing.Color").Pink,       -- 绿色 false
    --modeBakeColor = (dotNetClass "System.Drawing.Color").Yellow       -- 橙色 false
)
-- 在颜色配置结构体后添加//最近打开文件 数量上限 ；滚动条上限
struct performanceConfig (
    maxRecentFiles = 10000,  -- 可配置项
    virtualScrollThreshold = 500  -- 超过500条启用虚拟滚动
)
global g_PerfConfig = performanceConfig()
global g_ColorConfig = colorConfig()  -- 全局颜色配置实例
-- 在初始化部分添加全局状态变量
global g_forceCustomLayout = false -- 是否强制保持自定义布局
--lv列表列宽主调整！！！
global LISTVIEW_WIDTH = 500
global COLUMN_CK_WIDTH = 55   -- CK/ICON列基准宽度
global COLUMN_FILE_WIDTH = 305  -- 文件列基准宽度
global COLUMN_TYPE_WIDTH = 100   -- 类型列基准宽度

global g_defaultBgValue = 45  -- 默认灰度值 (LV列表 默认 背景色)
global g_gridLineColor = (dotNetClass "System.Drawing.Color").White -- 默认网格线颜色

global g_defaultFont = dotNetObject "System.Drawing.Font" "微软雅黑" 8 ((dotNetClass "System.Drawing.FontStyle").Bold)
global g_alternateFont = dotNetObject "System.Drawing.Font" "Arial" 8 ((dotNetClass "System.Drawing.FontStyle").Regular)
----------------------------------------------------------------
-- 创建动态右键菜单结构
global g_contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
global g_menuItems = #(
    #("删除文件", "Delete"),
    #("打开文件", "Open"),
    #("导入BIP", "ImportBip"),
    #("运行脚本", "RunScript"),
    #("导入XAF", "ImportXaf"),
    #("属性", "Properties"),
    #("用FBX查看器打开", "FbxViewer")
)
-- 初始化菜单项 / false / 未验证 / 备用 （不影响核心功能）
for itemDef in g_menuItems do (
    local menuItem = g_contextMenu.Items.Add(itemDef[1])
    menuItem.Tag = itemDef[2]
)

-------------------------------------------------------------------------
struct itemsFolder (name,dir)  --File列表文件目录(ini 写入 格式  命名/框架)     
-------------------------------------------------------------------------

-- 文件管理结构体定义（必须前置声明）- 初始化文件管理器
struct stFileManager (

    -- 自然排序算法
    fn pseudoNaturalSort a b = (
        fn getFilesequenceFile f &base &digits = (
            f = getFilenameFile f
            base = trimRight f "0123456789"
            digits = subString f (base.count + 1) -1
        )
        
        local aBase, aDigits, bBase, bDigits
        getFilesequenceFile a &aBase &aDigits
        getFilesequenceFile b &bBase &bDigits
        
        aDigits = subString (( (aDigits as integer)) as string) 2 -1
        bDigits = subString (( (bDigits as integer)) as string) 2 -1
        
        case of (
            (a == b): 0
            (a < b): -1
            (a > b): 1
        )
    ),
    
    -- 修改后的获取文件和目录方法
    public fn getFilesAndDirs root filterType = (
        root = pathConfig.normalizePath root
        local dirs = GetDirectories (root + "\\*")
        local files = getFiles (root + "\\*" + filterType)
        
        -- 使用自然排序
        qsort dirs pseudoNaturalSort
        qsort files pseudoNaturalSort
        
        #(dirs, files)
    ),

    -- 新增层级显示函数
    fn getDisplayName fullPath baseDepth = (
        local arrPath = filterString fullPath "\\"
        local depth = arrPath.count - baseDepth
        local indent = ""
        for i = 1 to depth do indent += "    "
        indent + filenameFromPath fullPath
    ),

    fn refreshFileList path filterType:"*.max" = (
        if not doesDirectoryExist path do return #()
        files = getFiles (path + "\\" + filterType)
        qsort files pseudoNaturalSort
        files
    )
)
----------------------------------------------------------------
-- 全局初始化（必须在结构体之后）
global g_fileManager = stFileManager()
----------------------------------------------------------------
-- 配置管理模块 ---------------------------------------------------------
global g_UIConfigPath = pathConfig.normalizePath ((getDir #maxData) + "\\AutoExportTool.pro_UI.ini")
global g_ConfigPath = pathConfig.normalizePath ((getDir #maxData) + "\\AutoExportTool.pro_Config.ini")    --ini-目录路径保存文件 
global g_likedFolders = #()                      -- ini 写入 常用路径文件夹-名称/路径-命名+储存
global g_maxRecentFiles = 10000                    -- 将最大限制改为10000 // --最近打开最大文件数
global g_recentFiles = #()                           --写入 最近打开文件夹-名称/文件名-记录/动态记忆/2025--false---- 改为存储二维数组 [#(路径, 是否存在), ...]
----------------------------------------------------------------
global g_showRecentFiles = false -- 新增：标记是否处于“最近打开”模式
----------------------------------------------------------------
global g_cyclePath = undefined -- 循环路径记录
----------------------------------------------------------------
----------------------------------------------------------------
--特殊文件夹列表双击/导航并正确设置文件类型帅选（max ,fbx,bip,ms,xaf = 1 2 3 4 5 / 支持 普通 文件夹 名称/文件类型筛选-导航设置 和 特殊名称 文件夹 名称/文件类型筛选-导航设置
-- 添加类型缓存机制
global g_fileTypeCache = #()
global g_fileTypes = #("*.max", "*.fbx", "*.ms;*.mse", "*.bip", "*.mzp") -- 支持的文件类型数组
global g_fileTypeCache = #()
--特殊文件夹列表双击/导航并正确设置文件类型帅选（max ,fbx,bip,ms,xaf = 1 2 3 4 5
global cacheFileTypes folderPath = fn cacheFileTypes folderPath = (
    g_fileTypeCache = #()
    local allFiles = getFiles (folderPath + "\\*.*")
    for f in allFiles do (
        append g_fileTypeCache (toLower (getFilenameType f))
    )
    g_fileTypeCache
)
----------------------------------------------------------------

----------------------------------------------------------------
--特殊文件夹列表双击/导航并正确设置文件类型帅选（max ,fbx,bip,ms,mzp,xaf = 1 2 3 4 5 6..
-- 新增模式匹配语法 / 双击点击文件夹（根据文件夹名称文件类型智能筛选显示）
struct PatternSettings (
    
    script = #("*script*","*maxscript*","*Startup*","*ms*","*mzp*","*mcr*","*tool*"),  -- 扩展脚本相关关键词
    maxFiles = #("*max*","*ani*","*csanim*","*scene*","*animation*"),  -- 包含更多max相关关键词
    bip = #("*bip*","*biped*","*rig*","*csbiped*"),
    fbx = #("*fbx*","*mesh*","*model*","*asset*"),
    xaf = #("*xaf*","*bone*","*anim*","*attach*")
)
--特殊文件夹列表双击/导航并正确设置文件类型筛选（max ,fbx,bip,ms,xaf = 1 2 3 4 5..
fn getFilterPattern = (
    case rdoFileFilter.state of (
        1: "*.max"                   -- Max场景
        2: "*.fbx"                   -- FBX资源
        3: "*.ms;*.mse"  -- Max脚本/加密脚本/宏脚本   
        4: "*.bip"                   -- Biped数据
        5: "*.mzp"                   -- 宏脚本
        6: "*.xaf"                   -- 附件数据
        default: "*"                 -- 默认全显示 
        
        --default: rdoFileFilter.state -- 保持原状态  false
    )
)

global g_patterns = PatternSettings()

-- 优化特殊文件夹检测函数
fn isSpecialFolder folderName patternType = (
    local patterns = case patternType of (
        
        #script: g_patterns.script  -- 新增script处理
        #max: g_patterns.max
        #bip: g_patterns.bip
        #fbx: g_patterns.fbx
        #xaf: g_patterns.xaf
        default: #()
    )
    
    for p in patterns where (matchPattern folderName pattern:p) do return true
    false
)

-- 重构智能类型检测逻辑
fn autoDetectFilterType path = (
    local folderName = toLower (filenameFromPath path)
    
    case of (
        (isSpecialFolder folderName #script): 3   -- 脚本类型优先/-- 最高优先级
        (isSpecialFolder folderName #xaf): 6      -- 附件数据
        (isSpecialFolder folderName #bip): 4      -- Biped数据
        (isSpecialFolder folderName #fbx): 2      -- FBX资源
        (isSpecialFolder folderName #maxFiles): 1 -- MAX场景/使用新成员名称
        default: 1  -- 未匹配时默认MAX类型          --default: rdoFileFilter.state -- 保持原状态/false
        --default: rdoFileFilter.state
    )
)
----------------------------------------------------------------
----------------------------------------------------------------
global g_bipExportPath = ""     -- BIP 导出 目录地址
global g_bipImportPath = ""     -- BIP 导入 目录地址
global g_bipProcessMode = 1     -- BIP 模式（1:导出 2:导入）
global g_autoCreateBip = true   -- 自动创建Biped开关
----------------------------------------------------------------
-- 列表文件类型名称自动判断标注/可拓展-多类型文件右键打开 or 双击可打开..
global getFileType fPath = fn getFileType fPath = (

    if classOf fPath != String do return "无效路径"
    if not doesFileExist fPath do return "文件不存在"
    
    case (toLower (getFilenameType fPath)) of (
        ".max": (
            local fName = toLower (getFilenameFile fPath)
            case of (
                (findString fName "skin" != undefined): "角色模型"
                (findString fName "ani" != undefined): "动画文件"
                (findString fName "scene" != undefined): "场景文件"
                
                (findString fName "merge" != undefined): "合并文件"
                (findString fName "socket" != undefined): "挂点文件"
                (findString fName "挂点" != undefined): "挂点文件"
                
                (findString fName "start" != undefined): "分段(起始)"
                (findString fName "loop" != undefined): "分段(循环)"
                (findString fName "end" != undefined): "分段(结束)"
                
                default: "Max文件"
            )
        )
        ".fbx": "FBX资源" 
        ".ms": "Max脚本"
        ".mzp": "宏脚本z"
		".mcr": "宏脚本c"
        ".mse": "加密脚本"
        ".bip": "Biped数据"
        ".xaf": "附件数据"
        ".png": "PNG图像"
        ".jpg": "JPEG图像g"
        ".jpeg": "JPEG图像eg"
        ".txt": "文本文件"
        ".doc": "Word文档c"
        ".docx": "Word文档cx"
        ".xls": "Excel表格s"
        ".xlsx": "Excel表格sx"
        ".pdf": "PDF文档"
        ".zip": "ZIP压缩包"
        ".rar": "RAR压缩包"
        ".7z": "7-Zip压缩包"
        ".ini": "配置文件"
        ".json": "JSON文件"
        ".xml": "XML文件"
        default: "其他文件"
    )
)
----------------------------------------------------------------
-- 添加自动保存路径监控 - 实测 功能稳定 true
global g_autoSavePath = pathConfig.normalizePath (getDir #autoback) -- 自动保存路径
global g_autoSaveWatcher = undefined                                   -- 文件监控对象
global g_autoSaveWatcher = dotNetObject "System.IO.FileSystemWatcher"
----------------------------------------------------------------
-- 使用闭包封装INI操作函数避免污染全局作用域-- true --（验证实现）
-- 新增全局变量：常用目录/存储结构
----------------------------------------------------------------
--记录常用目录/ POS-插件位置 /Main ini ( 核心 ini /config-记录保存 ) --  实测 功能稳定 true
-- ========== 配置保存函数 (中文兼容) ==========
global saveConfig = fn saveConfig = (
    try (
        -- 创建配置目录
        makeDir (getFilenamePath g_ConfigPath) all:true
        
        -- 清除旧配置
        delINISetting g_ConfigPath "LikedFolders"  -- 删除整个区块
        
        -- 存储目录数量
        setINISetting g_ConfigPath "LikedFolders" "Count" (g_likedFolders.count as string)
        
        -- 循环存储每个目录
        for i=1 to g_likedFolders.count do (
            setINISetting g_ConfigPath "LikedFolders" ("Name" + i as string) g_likedFolders[i].name
            setINISetting g_ConfigPath "LikedFolders" ("Dir" + i as string) g_likedFolders[i].dir
        )
        true  -- 返回成功
    ) 
    catch (false)  -- 返回失败
)
----------------------------------------------------------------
-- 新增全局变量：常用目录/读取结构
-- 加载配置函数-- true --（验证实现）
----------------------------------------------------------------
--记录常用目录/ POS-插件位置 /Main ini ( 核心 ini /config-读取加载 ) --  实测 功能稳定 true
-- ========== 配置加载函数 (中文兼容) ==========
-- ========== 配置加载函数 (使用独立函数) ==========
global loadConfig = fn loadConfig = (
    g_likedFolders = #()  -- 清空当前目录
    
    if doesFileExist g_ConfigPath do (
        -- 读取目录数量
        local count = (getINISetting g_ConfigPath "LikedFolders" "Count") as integer
        
        -- 循环加载目录
        for i=1 to count do (
            local name = getINISetting g_ConfigPath "LikedFolders" ("Name" + i as string)
            local dir = getINISetting g_ConfigPath "LikedFolders" ("Dir" + i as string)
            
            if name != "" and dir != "" do (
                append g_likedFolders (itemsFolder name:name dir:dir)
            )
        )
    )
    
    -- 默认目录（首次运行时）
    if g_likedFolders.count == 0 do (
        append g_likedFolders (itemsFolder name:"默认场景" dir:(getDir #scene))
    )
)
----------------------------------------------------------------
----------------------------------------------------------------

--日期显示- true -（验证实现）
global DateTime = (dotNetClass "System.DateTime").Now
global arrDayWeek = #("日", "一", "二", "三", "四", "五", "六")                --需要确保arrDayWeek数组正确定义（日期）
global g_refreshTimer = undefined  -- 显式声明定时器变量
----------------------------------------------------------------
--窗口位置记忆-- true --（验证实现）
global g_WindowPosPath = (getDir #scripts) + "\\AutoExportTool.pro_pos.ini"       -- 记忆窗口位置配置（pos-remember)
global g_lastError = ""
try (
    -- 主脚本内容（包括 rollout 定义和 CreateDialog）
) catch (
    g_lastError = getCurrentException()
    format "[致命错误] 插件初始化失败：%\n" g_lastError
    messageBox "插件启动失败，请联系开发者！" title:"错误" beep:true
)
global g_lastDialogPos = [100, 100]  -- 默认位置-- 全局变量用于保存窗口位置-- true --（验证实现）
----------------------------------------------------------------
global g_exportAbortFlag = false -- 全局中断标志 Esc-中断导出进程-- true -- (验证实现） 
----------------------------------------------------------------
global g_sceneSetsCache = #()                  --true--验证实现
----------------------------------------------------------------
global g_exportTypes = #("skin", "ani", "animrange") -- 文件类型
global g_autoOpenFolder = true                   -- 自动打开目录开关（新增）
global g_lastExportPath = undefined              -- 最后导出路径记录（新增）
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- FBX 导出 三个 模式参数 实测 功能稳定 true
global refreshModeDisplay = fn refreshModeDisplay = (
    try (
     
        -- 状态获取（带错误回退）
        local fbxState = try(rdo_exportMode.state)catch(1)
        local bipState = try(rdo_bipMode.state)catch(1)
        
        -- 模式名称映射
        local modeMap = #(
            #("Auto默认", "Skin模型", "Bake动画"),  -- FBX模式
            #("导出BIP", "导入BIP")                -- BIP模式
        )
        --lblModeStatus.text = infoText - false / 沉淀代码 
        -- 构建显示文本
        local infoText = "FBX模式：" + modeMap[1][fbxState] + \  -- true
                       "  |  BIP模式：" + modeMap[2][bipState]   -- false (此部分改成了 Last Action : 按钮点击执行操作名称显示=执行事件名称提示具体状态！)
        
        -- 带有效性检查的控件更新
        if isValidNode ModeStatus do (
            ModeStatus.caption = infoText
            format "[界面更新] 当前状态：%\n" infoText
        )
    )
    catch (
        format "[严重错误] 状态更新失败：%\n" (getCurrentException())
    )
)

-- 表情符号库  -- false / 沉淀代码 / 未验证 / 备用
global emojiLib = #(
    "♓",  -- 默认
    "☽",  -- 悬停时
    "♛"   -- 点击时
)

-- 在全局区域添加骨骼检测/函数
global isBoneObject = fn isBoneObject obj = (
    if obj == undefined do return false
    local objClass = classOf obj
    return (objClass == BoneGeometry or objClass == Biped_Object)
)
-- 全局XAF设置函数
global saveXAFSettings = fn saveXAFSettings boneList = (
    try (
        local boneNames = ""
        for bone in boneList do (
            boneNames += bone + ","
        )
        setINISetting g_UIConfigPath "XAFSettings" "SelectedBones" boneNames
        format "[XAF设置保存成功] 已保存 % 个骨骼\n" boneList.count
        true
    )
    catch (
        format "[XAF设置保存错误] %\n" (getCurrentException())
        false
    )
)

global loadXAFSettings = fn loadXAFSettings = (
    try (
        local savedBones = getINISetting g_UIConfigPath "XAFSettings" "SelectedBones"
        if savedBones != "" then (
            return filterString savedBones ","
        )
        #()
    )
    catch (
        format "[XAF设置加载错误] %\n" (getCurrentException())
        #()
    )
)

----------------------------------------------------------------
----------------------------------------------------------------
--对话框创建前销毁旧实例 / true
try (
    loadConfig() -- 确保在创建UI前加载配置
    format "[常用路径初始化] 配置加载完成，共 % 个路径\n" g_likedFolders.count
) catch (
    format "[初始化错误] %\n" (getCurrentException())
)

--try(AutoExportTool_Pro.ddlLikedPaths.selection = 1) catch()  -- 可选：重置选中项 -- false / 沉淀代码 / 未验证
----------------------------------------------------------------
----------------------------------------------------------------
try(destroyDialog rolXAFEditor)catch()
try(destroyDialog rolCharacterMapping)catch()
try(destroyDialog rolPathManager)catch()
try(destroyDialog AutoExportTool_Pro)catch()
----------------------------------------------------------------
----------------------------------------------------------------
-- XAF骨骼选择集编辑器 // rolXAFEditor 
rollout rolXAFEditor "XAF骨骼选择集编辑器" width:500 height:620
(
    dotNetControl lvBones "System.Windows.Forms.ListView" width:460 height:350 align:#center offset:[0,10]
    
    -- 新增筛选按钮
    group "骨骼类型筛选"
    (
        button btnBones "Bones" width:60 height:22 across:5 tooltip:"只显示标准骨骼"
        button btnBipeds "Bipeds" width:60 height:22 tooltip:"只显示Biped骨骼"
        button btnPoints "Points" width:60 height:22 tooltip:"只显示Point辅助对象"
        button btnDummies "Dummies" width:60 height:22 tooltip:"只显示Dummy虚拟体"
        button btnAll "All" width:60 height:22 tooltip:"显示所有类型"
    )
    -- 新增事件按钮
    group "XAF操作执行"
    (
    button btnSelectAll "✅ 全选" width:60 height:25 across:4 tooltip:"全勾选骨骼"
    button btnDeselectAll "❌ 全不选" width:60 height:25 tooltip:"不勾选骨骼"
    button btnSave "💾 保存" width:60 height:25 tooltip:"保存骨骼配置"
    button btnClose "关闭" width:60 height:25 tooltip:"关闭编辑器"
    
    -- 新增同步按钮
    button btnSyncSelection "同步选择" width:80 height:25 across:2 offset:[0,5] tooltip:"将场景中选择的骨骼同步到列表"
    button btnRefresh "🔄 刷新" width:70 height:25  offset:[0,5] tooltip:"刷新列表 "
    button btnSyncSelectionSet "选择集同步" width:80 height:25 tooltip:"将选择集中的骨骼同步到列表"
    )
    label lblBoneCount "骨骼总数: 0 | 已选择: 0" align:#center offset:[0,10]
    
    label lblStatus "准备就绪..." align:#center offset:[0,5]  -- 新增状态标签
    
    label edtUserExPath "˖⁩ ℳ ❀ ͜♡︎ ›ヽ(●´∀●)ﾉ`-骨骼XAF编辑器/-XAF Bone Selection Set Editor！" width:475 align:#center offset:[75,5]  
    
    local boneList = #()
    local selectedBones = #()
    local currentFilter = "All" -- 当前筛选类型
    local g_selSetName = "" -- 全局变量存储选择集名称
    
    -- 初始化骨骼列表视图
    fn initBoneListView = (
        lvBones.View = (dotNetClass "System.Windows.Forms.View").Details
        lvBones.CheckBoxes = true
        lvBones.FullRowSelect = true
        lvBones.MultiSelect = true
        lvBones.GridLines = true
        lvBones.HideSelection = false
        
        -- 添加列
        lvBones.Columns.Add "选择" 50
        lvBones.Columns.Add "骨骼名称" 250
        lvBones.Columns.Add "类型" 100
        
        -- 加载保存的设置
        selectedBones = loadXAFSettings()
    )
    
    -- 刷新骨骼列表（带筛选功能）
    fn refreshBoneList filterType:currentFilter = (
        lvBones.Items.Clear()
        boneList = #()
        
        -- 根据筛选类型收集骨骼
        case filterType of (
            "Bones": (
                boneList = for obj in objects where (classOf obj == BoneGeometry) collect obj
            )
            "Bipeds": (
                boneList = for obj in objects where (classOf obj == Biped_Object) collect obj
            )
            "Points": (
                boneList = for obj in objects where (classOf obj == Point) collect obj
            )
            "Dummies": (
                boneList = for obj in objects where (classOf obj == Dummy) collect obj
            )
            "All": (
                boneList = for obj in objects where (isBoneObject obj or classOf obj == Dummy or classOf obj == Point) collect obj
            )
        )
        
        local selectedCount = 0
        
        for bone in boneList do (
            local isSelected = (findItem selectedBones bone.name) > 0
            if isSelected do selectedCount += 1
            
            local li = dotNetObject "System.Windows.Forms.ListViewItem" ""
            li.Checked = isSelected
            li.SubItems.Add(bone.name)
            li.SubItems.Add((classOf bone) as string)
            li.Tag = bone.name
            lvBones.Items.Add(li)
        )
        
        -- 更新骨骼计数标签
        lblBoneCount.text = "骨骼总数: " + (boneList.count as string) + " | 已选择: " + (selectedCount as string)
        currentFilter = filterType
    )
    
    -- 更新骨骼计数
    fn updateBoneCount = (
        local selectedCount = 0
        for i = 0 to (lvBones.Items.Count - 1) do (
            if lvBones.Items.Item[i].Checked do selectedCount += 1
        )
        lblBoneCount.text = "骨骼总数: " + (boneList.count as string) + " | 已选择: " + (selectedCount as string)
    )
    
    -- 同步场景选择到列表
    fn syncSelectionToXAFList = (
        local sel = getCurrentSelection()
        -- 先切换到所有骨骼显示
        refreshBoneList filterType:"All"
        
        for i = 0 to (lvBones.Items.Count - 1) do (
            local item = lvBones.Items.Item[i]
            local boneName = item.Tag as string
            local found = false
            
            for obj in sel while not found do (
                if obj.name == boneName do (
                    item.Checked = true
                    found = true
                )
            )
            
            if not found do item.Checked = false
        )
        updateBoneCount()
    )
    
    -- 同步选择集到列表 - 使用全局变量修复
    fn syncSelectionSetToXAFList = (
        local selSets = #()
        for i = 1 to (getNumNamedSelSets()) do (
            append selSets (getNamedSelSetName i)
        )
        
        if selSets.count > 0 then (
            -- 使用全局变量存储选择集名称
            g_selSetName = selSets[1] -- 默认使用第一个选择集
            
            if selSets.count > 1 do (
                -- 如果有多个选择集，弹出选择对话框
                try (
                    -- 创建选择集选择对话框
                    rollout selSetDialog "选择选择集" width:200 height:100
                    (
                        dropdownlist ddlSets "选择集:" items:selSets width:180
                        button btnOK "确定" width:80 across:2
                        button btnCancel "取消" width:80
                        
                        on btnOK pressed do (
                            -- 使用全局变量存储选择
                            g_selSetName = ddlSets.selected
                            destroyDialog selSetDialog
                        )
                        on btnCancel pressed do (
                            g_selSetName = undefined
                            destroyDialog selSetDialog
                        )
                    )
                    
                    createDialog selSetDialog modal:true
                )
                catch (
                    format "[选择集对话框错误] %\n" (getCurrentException())
                    g_selSetName = undefined
                )
            )
            
            if g_selSetName != undefined do (
                try (
                    local selSetObjs = selectionSets[g_selSetName]
                    -- 先切换到所有骨骼显示
                    refreshBoneList filterType:"All"
                    
                    for i = 0 to (lvBones.Items.Count - 1) do (
                        local item = lvBones.Items.Item[i]
                        local boneName = item.Tag as string
                        local found = false
                        
                        for obj in selSetObjs while not found do (
                            if obj.name == boneName do (
                                item.Checked = true
                                found = true
                            )
                        )
                        
                        if not found do item.Checked = false
                    )
                    updateBoneCount()
                )
                catch (
                    format "[选择集处理错误] %\n" (getCurrentException())
                    messageBox ("处理选择集时出错: " + (getCurrentException())) title:"错误"
                )
            )
        ) else (
            messageBox "场景中没有选择集!" title:"提示"
        )
    )
    
    on rolXAFEditor open do (
        initBoneListView()
        refreshBoneList()
    )
    
    on btnRefresh pressed do refreshBoneList()
    
    on btnSelectAll pressed do (
        for i = 0 to (lvBones.Items.Count - 1) do (
            lvBones.Items.Item[i].Checked = true
        )
        updateBoneCount()
    )
    
    on btnDeselectAll pressed do (
        for i = 0 to (lvBones.Items.Count - 1) do (
            lvBones.Items.Item[i].Checked = false
        )
        updateBoneCount()
    )
    
    -- 修改保存按钮事件处理（使用状态标签）
    on btnSave pressed do (
        -- 收集选中的骨骼
        selectedBones = #()
        for i = 0 to (lvBones.Items.Count - 1) do (
            if lvBones.Items.Item[i].Checked do (
                append selectedBones (lvBones.Items.Item[i].Tag as string)
            )
        )
        
        -- 保存设置
        saveXAFSettings selectedBones
        local saveResult = saveXAFSettings selectedBones
        
        if saveResult then (
            local selectedCount = selectedBones.count as string
            lblBoneCount.text = "骨骼总数: " + (boneList.count as string) + " | 已选择: " + selectedCount
            lblStatus.text = "XAF设置已保存: " + selectedCount + " 个骨骼"
        ) else (
            lblStatus.text = "XAF设置保存失败"
        )
    )
    
    on btnClose pressed do destroyDialog rolXAFEditor
    
    -- 添加复选框状态改变事件
    on lvBones ItemChecked arg do (
        updateBoneCount()
    )
    
    on rolXAFEditor open do (
        initBoneListView()
        refreshBoneList()
        lblStatus.text = "准备就绪"
    )
    
    on btnRefresh pressed do (
        refreshBoneList()
        lblStatus.text = "列表已刷新"
    )
    
    on btnSelectAll pressed do (
        for i = 0 to (lvBones.Items.Count - 1) do (
            lvBones.Items.Item[i].Checked = true
        )
        updateBoneCount()
        lblStatus.text = "已全选所有骨骼"
    )
    
    on btnDeselectAll pressed do (
        for i = 0 to (lvBones.Items.Count - 1) do (
            lvBones.Items.Item[i].Checked = false
        )
        updateBoneCount()
        lblStatus.text = "已取消所有选择"
    )
    
    -- 修改保存按钮事件处理（使用状态标签）
    on btnSave pressed do (
        -- 收集选中的骨骼
        selectedBones = #()
        for i = 0 to (lvBones.Items.Count - 1) do (
            if lvBones.Items.Item[i].Checked do (
                append selectedBones (lvBones.Items.Item[i].Tag as string)
            )
        )
        
        -- 保存设置
        local saveResult = saveXAFSettings selectedBones
        
        if saveResult then (
            local selectedCount = selectedBones.count as string
            lblBoneCount.text = "骨骼总数: " + (boneList.count as string) + " | 已选择: " + selectedCount
            lblStatus.text = "XAF设置已保存: " + selectedCount + " 个骨骼"
        ) else (
            lblStatus.text = "XAF设置保存失败"
        )
    )
    
    on btnClose pressed do destroyDialog rolXAFEditor
    
    -- 添加复选框状态改变事件
    on lvBones ItemChecked arg do (
        updateBoneCount()
    )
    
    -- 新增筛选按钮事件
    on btnBones pressed do (
        refreshBoneList filterType:"Bones"
        lblStatus.text = "显示标准骨骼"
    )
    on btnBipeds pressed do (
        refreshBoneList filterType:"Bipeds"
        lblStatus.text = "显示Biped骨骼"
    )
    on btnPoints pressed do (
        refreshBoneList filterType:"Points"
        lblStatus.text = "显示Point辅助对象"
    )
    on btnDummies pressed do (
        refreshBoneList filterType:"Dummies"
        lblStatus.text = "显示Dummy虚拟体"
    )
    on btnAll pressed do (
        refreshBoneList filterType:"All"
        lblStatus.text = "显示所有类型"
    )
    
    -- 新增同步按钮事件
    on btnSyncSelection pressed do (
        lblStatus.text = "正在同步选择..."
        syncSelectionToXAFList()
        lblStatus.text = "选择已同步到列表"
    )
    on btnSyncSelectionSet pressed do (
        lblStatus.text = "正在同步选择集..."
        syncSelectionSetToXAFList()
        lblStatus.text = "选择集已同步到列表"
    )
)

-- 角色映射管理对话框
rollout rolCharacterMapping "角色名称映射" width:300 height:300 (
    listbox lbMappings "当前映射:" height:10 width:280
    edittext edtLocal "本地名称:" width:280
    edittext edtEngine "引擎名称:" width:280
    button btnAdd "添加/更新" width:80 across:2
    button btnRemove "删除" width:80
    button btnClose "关闭" width:80 align:#center offset:[0,10]
    
    fn refreshList = (
        lbMappings.items = for map in g_characterMappings collect map.name + " -> " + map.dir
    )
    
    on rolCharacterMapping open do (
        refreshList()
    )
    
    on btnAdd pressed do (
        if edtLocal.text != "" and edtEngine.text != "" do (
            -- 更新或添加映射
            local found = false
            for i in g_characterMappings do (
                if i.name == edtLocal.text do (
                    i.dir = edtEngine.text
                    found = true
                    exit
                )
            )
            
            if not found do (
                append g_characterMappings (CharacterMapping name:edtLocal.text dir:edtEngine.text)
            )
            
            -- 保存到INI
            setINISetting g_characterMappingPath "Mappings" "Count" (g_characterMappings.count as string)
            for i = 1 to g_characterMappings.count do (
                setINISetting g_characterMappingPath ("Mapping" + i as string) "Local" g_characterMappings[i].name
                setINISetting g_characterMappingPath ("Mapping" + i as string) "Engine" g_characterMappings[i].dir
            )
            
            refreshList()
            edtLocal.text = ""
            edtEngine.text = ""
        )
    )
    
    on btnRemove pressed do (
        if lbMappings.selection > 0 do (
            deleteItem g_characterMappings lbMappings.selection
            refreshList()
            
            -- 更新INI
            setINISetting g_characterMappingPath "Mappings" "Count" (g_characterMappings.count as string)
            for i = 1 to g_characterMappings.count do (
                setINISetting g_characterMappingPath ("Mapping" + i as string) "Local" g_characterMappings[i].name
                setINISetting g_characterMappingPath ("Mapping" + i as string) "Engine" g_characterMappings[i].dir
            )
        )
    )
    
    on btnClose pressed do (
        destroyDialog rolCharacterMapping
    )
)
----------------------------------------------------------------
--  ==============================-rollout-批量文件改名工具--区域-================================
-- 批量文件改名工具 Rollout
rollout RenameToolRollout "批量文件改名神⚚剑🗡️Batch Rename​​ Tool_V1.01" width:1000 height:780
(
    -- UI 控件定义
    group "路径设置" 
    (
        edittext edtCurrentPath "当前路径:" width:690 height:18 labelOnTop:true align:#left across:3
        button btnOpenExportPath "打开文件夹" width:100 height:20 align:#center offset:[300,18] toolTip:"打开当前目录文件夹"
        button btnSyncPath "同步主插件路径" width:100 height:20 align:#right offset:[0,18] toolTip:"从主插件同步当前路径" tooltip:"同步主插件的列表文件"
    )
        
    group "改名设置" 
    (
        edittext edtSuffix "添加后缀:" width:200 across:2 labelOnTop:false offset:[-5,0] tooltip:"默认自动添加文件后缀 _ "
        button btnAddSuffix "执行后缀修改" width:100 height:22 offset:[-370,-2] align:#center tooltip:"开始处理/修改文件后缀"
        
        edittext edtFindText "查找文本:" width:200 across:2 labelOnTop:false offset:[-5,0]
        edittext edtReplaceText "替换为:" width:200 labelOnTop:false offset:[-250,-2]
        button btnReplace "替换文本" width:80 height:22 offset:[-128,-2] tooltip:"开始处理/替换文件名称字符"
        
        button btnRevert "恢复命名" width:100 height:30 offset:[0,5] tooltip:"从默认备份的文件获取文件原始名称并恢复"
        
        --button btnSortByExtension "按扩展名排序" width:100 height:22 offset:[10,0] tooltip:"按文件扩展名排序列表" 
        
        button btnCleanBackup "清理备份" width:85 height:22 tooltip:"清理所有备份文件"
        
        button btnBackup "备份文件" width:80 height:22 across:3 offset:[-50,0] tooltip:"首次修改自动备份"
        
        button btnRefreshList "刷新列表" width:70 height:22 offset:[0,0]
        button btnClearList "清空列表" width:80 height:22 offset:[50,0] tooltip:"清空列表ClearAll"
    )
    
    group "文件列表" 
    (
        dotNetControl lvFiles "System.Windows.Forms.ListView" width:960 height:350 offset:[-5,0]
        button btnBrowse "浏览文件夹" width:100 height:22 across:3 offset:[-50,0] tooltip:"浏览并选择需要的文件夹目录"
        button btnAddFiles "添加文件" width:100 height:22 offset:[0,0] tooltip:"添加需要改名的文件到列表"
        button btnRemoveSelected "移除选中" width:100 height:22 offset:[50,0] tooltip:"仅从列表移除/非真实删除文件"
    )
    
    group "状态信息" 
    (
        label lblStatus "准备就绪..." align:#left
        progressbar pbRename width:960 height:20
    )
    
    label edtUserExPath "˖⁩ ℳ ❀ ͜♡︎ ›ヽ(●´∀●)ﾉ`修改-列表文件⇝后缀or替换/名称-renamedFiles！" offset:[0,0] width:980 align:#center
    
    -- 内部变量
    local originalFiles = #()
    local renamedFiles = #()
    local backupPath = ""
    local mainPlugin = undefined
    local backupCreated = false
        
        
    -- 移除选中文件 / 非真实删除 /移除选中的列表文件
    fn removeSelectedItemsFromList = 
        (
            local selItems = lvFiles.SelectedItems
            if selItems.Count == 0 do return false
            
            for i = selItems.Count - 1 to 0 by -1 do
            (
                local item = selItems.Item[i]
                local index = lvFiles.Items.IndexOf(item)
                
                deleteItem originalFiles (index + 1)
                deleteItem renamedFiles (index + 1)
                lvFiles.Items.Remove(item)
            )
            -- 更新文件计数
            local fileCount = 0
            for i = 0 to (lvFiles.Items.Count - 1) do
            (
                if lvFiles.Items.Item[i].SubItems.Item[2].Text != "文件夹" do fileCount += 1
            )
            --lblStatus.text = "已移除！" 
            lblStatus.text = "当前列表已加载" + (lvFiles.Items.Count as string) + " 个文件"
            true
        )
    
    -- 打开选中文件所在文件夹
    fn openSelectedFileFolder = 
    (
        local selItems = lvFiles.SelectedItems
        if selItems.Count == 0 do 
        (
            messageBox "请先选择文件!" title:"提示"
            return false
        )
        
        for i=0 to selItems.Count-1 do (
            local itemPath = selItems.Item[i].Tag as String
            if doesFileExist itemPath or doesDirectoryExist itemPath then (
                shellLaunch "explorer.exe" ("/select," + itemPath)
            )
        )
        true
    )
    -- 删除选中文件 / 系统文件 真实 删除 
        fn deleteSelectedFiles = 
        (
            local selItems = lvFiles.SelectedItems
            if selItems.Count == 0 do 
            (
                messageBox "请先选择要删除的文件!" title:"提示"
                return false
            )
            
            -- 构建文件列表字符串
            local fileList = ""
            for i=0 to selItems.Count-1 do (
                local path = selItems.Item[i].Tag as String
                fileList += filenameFromPath path + "\n"
            )
            
            -- 确认对话框
            local msg = "确定永久删除以下项目？此操作不可恢复！\n\n" + fileList
            if not (queryBox msg title:"危险操作" beep:true) do return false
            
            -- 删除所有选中的项目
            local deletedItems = #()
            local failedItems = #()
            
            for i=selItems.Count-1 to 0 by -1 do (
                local path = selItems.Item[i].Tag as String
                local isNetworkPath = matchPattern path pattern:"\\\\*"
                local success = false
                local isDir = doesDirectoryExist path
                
                try (
                    if isDir then (
                        -- 删除文件夹
                        if isNetworkPath then (
                            -- 服务器路径使用DOS命令
                            local cmd = "cmd /c rmdir /s /q \"" + path + "\""
                            hiddenDOSCommand cmd
                        ) else (
                            -- 本地路径使用.NET方法
                            local dir = dotNetClass "System.IO.Directory"
                            dir.Delete path true
                        )
                    ) else (
                        -- 删除文件
                        if isNetworkPath then (
                            -- 服务器路径使用DOS命令
                            local cmd = "cmd /c del /f /q \"" + path + "\""
                            hiddenDOSCommand cmd
                        ) else (
                            deleteFile path
                        )
                    )
                    
                    -- 验证删除
                    if (isDir and not doesDirectoryExist path) or (not isDir and not doesFileExist path) then (
                        success = true
                    )
                ) catch (
                    success = false
                )
                
                -- 记录结果
                if success then (
                    append deletedItems path
                    lvFiles.Items.Remove(selItems.Item[i])
                ) else (
                    append failedItems path
                )
            )
            
            -- 显示操作结果
            local resultMsg = ""
            if deletedItems.count > 0 then (
                resultMsg = "已删除 " + (deletedItems.count as string) + " 个项目\n"
            )
            if failedItems.count > 0 then (
                resultMsg += "删除失败 " + (failedItems.count as string) + " 个项目:\n"
                for i=1 to (amin 5 failedItems.count) do (  -- 最多显示5个失败项
                    resultMsg += failedItems[i] + "\n"
                )
                if failedItems.count > 5 do resultMsg += "......\n"
            )
            
            if resultMsg != "" do messageBox resultMsg title:"删除结果"
            lblStatus.text = resultMsg
            true
        )
        
-- 初始化函数
fn initListView = 
(
    lvFiles.View = (dotNetClass "System.Windows.Forms.View").Details
    lvFiles.FullRowSelect = true
    lvFiles.MultiSelect = true
    lvFiles.GridLines = true
    lvFiles.HideSelection = false
    lvFiles.AllowDrop = true
    
    -- 添加列
    lvFiles.Columns.Add "原文件名" 380
    lvFiles.Columns.Add "新文件名" 400
    lvFiles.Columns.Add "处理状态" 90
    lvFiles.Columns.Add "文件类型" 100
    
    -- 设置右键菜单
    local contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
    local deleteItem = contextMenu.Items.Add("❌ 删除选中文件")
    local openFolderItem = contextMenu.Items.Add("🔜→ 打开所在文件夹")
    
    -- 使用正确的函数引用
    dotNet.addEventHandler deleteItem "Click" (fn s e = (deleteSelectedFiles()))
    dotNet.addEventHandler openFolderItem "Click" (fn s e = (openSelectedFileFolder()))
    
    lvFiles.ContextMenuStrip = contextMenu
)
    -- 创建带时间戳的备份目录
    fn createBackupDir = 
    (
        local timeArray = getLocalTime()
        local dateStamp = formattedPrint timeArray[1] format:"04d" +  
                          formattedPrint timeArray[2] format:"02d" +   
                          formattedPrint timeArray[4] format:"02d"
        backupPath = (getDir #temp) + "\\RenameBackup_" + dateStamp + "\\"
        makeDir backupPath all:true
        return backupPath
    )
    
    -- 确保备份目录存在
    fn ensureBackupDir = 
    (
        if not backupCreated do
        (
            backupPath = createBackupDir()
            backupCreated = true
            format "[备份目录] 已创建: %\n" backupPath
        )
        backupPath
    )
    
-- 更新文件列表显示 - 确保只显示原始文件和最新修改的文件
fn updateFileList = 
(
    lvFiles.Items.Clear()
    renamedFiles = #() -- 清空重命名文件数组
    
    for i = 1 to originalFiles.count do
    (
        local filePath = originalFiles[i]
        if doesFileExist filePath then
        (
            local fileName = filenameFromPath filePath
            local fileType = getFilenameType filePath
            
            local li = dotNetObject "System.Windows.Forms.ListViewItem" fileName
            li.SubItems.Add(fileName)  -- 新文件名初始与原文件名相同
            li.SubItems.Add("未处理")
            li.SubItems.Add(fileType)
            li.Tag = filePath
            
            lvFiles.Items.Add(li)
            append renamedFiles fileName -- 初始化为原始文件名
        )
    )
    
    -- 更新文件计数
    local fileCount = 0
    for i = 0 to (lvFiles.Items.Count - 1) do
    (
        if lvFiles.Items.Item[i].SubItems.Item[2].Text != "文件夹" do fileCount += 1
    )
    
    lblStatus.text = "已加载 " + (fileCount as string) + " 个文件"
)
    
    fn OpenExportFromRenameTool = 
    (
        local path = edtCurrentPath.text
        if doesDirectoryExist path then
        (
            ShellLaunch "explorer.exe" path
        )
        else
        (
            messageBox "当前路径不存在！" title:"错误"
        )
    )
    
    fn clearList = 
    (
        originalFiles = #()
        renamedFiles = #()
        lvFiles.Items.Clear()
        lblStatus.text = "列表已清空，0 个文件"
    )
    -- 从主插件同步文件
    fn syncFilesFromMainPlugin = 
    (
        if isDialogVisible AutoExportTool_Pro and isProperty AutoExportTool_Pro #model_files_array then
        (
            mainPlugin = AutoExportTool_Pro
            originalFiles = for f in mainPlugin.model_files_array where not matchPattern f pattern:"*[DIR]*" collect f
            
            -- 同步路径
            if isProperty mainPlugin #edtExportPath then
            (
                edtCurrentPath.text = mainPlugin.edtExportPath.text
            )
            
            updateFileList()
        )
        else
        (
            messageBox "主插件未打开或不可用!" title:"警告"
        )
    )
    
    -- 从当前路径加载文件
    fn loadFilesFromCurrentPath = 
    (
        if edtCurrentPath.text != "" and doesDirectoryExist edtCurrentPath.text then
        (
            originalFiles = #()
            local fileTypes = #("*.max", "*.fbx", "*.bip", "*.xaf", "*.ms", "*.mse")
            
            for ft in fileTypes do
            (
                local files = getFiles (edtCurrentPath.text + "\\" + ft)
                join originalFiles files
            )
            
            updateFileList()
            
            -- 更新文件计数
            local fileCount = 0
            for i = 0 to (lvFiles.Items.Count - 1) do
            (
                if lvFiles.Items.Item[i].SubItems.Item[2].Text != "文件夹" do fileCount += 1
            )
            
            lblStatus.text = "已加载 " + (fileCount as string) + " 个文件"
        )
        else
        (
            messageBox "当前路径无效或不存在!" title:"错误"
        )
    )
    
-- 添加后缀处理 - 始终基于原始文件名
fn addSuffix = 
(
    local suffix = edtSuffix.text
    if suffix == "" do 
    (
        messageBox "请输入后缀!" title:"提示"
        return false
    )
    
    -- 确保备份目录存在
    ensureBackupDir()
    
    local successCount = 0
    pbRename.value = 0
    
    for i = 0 to (lvFiles.Items.Count - 1) do
    (
        local item = LvFiles.Items.Item[i]
        local originalPath = item.Tag as String
        local originalName = item.Text  -- 始终使用原始文件名
        
        -- 从原始文件名构建新名称（不基于当前显示的名称）
        local baseName = getFilenameFile originalName
        local fileType = getFilenameType originalPath
        local newName = baseName + "_" + suffix + fileType
        local dirPath = getFilenamePath originalPath
        local newPath = dirPath + newName
        
        try
        (
            -- 备份原文件（只在第一次操作时备份）
            if not doesFileExist (backupPath + filenameFromPath originalPath) do
            (
                local backupFile = backupPath + filenameFromPath originalPath
                copyFile originalPath backupFile
            )
            
            -- 执行重命名
            renameFile originalPath newPath
            
            -- 更新列表显示
            item.SubItems.Item[1].Text = newName
            item.SubItems.Item[2].Text = "成功"
            successCount += 1
            
            -- 更新重命名文件数组
            renamedFiles[i+1] = newName
            
            -- 更新主插件列表（如果存在）
            if mainPlugin != undefined and isProperty mainPlugin #model_files_array then
            (
                local index = findItem mainPlugin.model_files_array originalPath
                if index > 0 do
                (
                    mainPlugin.model_files_array[index] = newPath
                )
            )
        )
        catch
        (
            item.SubItems.Item[2].Text = "失败: " + (getCurrentException())
        )
        
        pbRename.value = i + 1  -- 更新进度条
        windows.processPostedMessages()  -- 确保UI更新
    )
    
    lblStatus.text = "添加后缀完成! 成功: " + (successCount as string) + " / " + (LvFiles.Items.Count as string)
    true
)
    
-- 替换文本处理 - 也基于原始文件名
fn replaceText = 
(
    local findText = edtFindText.text
    local replaceText = edtReplaceText.text
    if findText == "" do 
    (
        messageBox "请输入要查找的文本!" title:"提示"
        return false
    )
    
    -- 确保备份目录存在
    ensureBackupDir()
    
    local successCount = 0
    pbRename.value = 0
    
    for i = 0 to (LvFiles.Items.Count - 1) do
    (
        local item = LvFiles.Items.Item[i]
        local originalPath = item.Tag as String
        local originalName = item.Text  -- 使用原始文件名
        
        if findString originalName findText != undefined then
        (
            local newName = substituteString originalName findText replaceText
            local dirPath = getFilenamePath originalPath
            local newPath = dirPath + newName
            
            try
            (
                -- 备份原文件（只在第一次操作时备份）
                if not doesFileExist (backupPath + filenameFromPath originalPath) do
                (
                    local backupFile = backupPath + filenameFromPath originalPath
                    copyFile originalPath backupFile
                )
                
                -- 执行重命名
                renameFile originalPath newPath
                
                item.SubItems.Item[1].Text = newName
                item.SubItems.Item[2].Text = "成功"
                successCount += 1
                
                -- 更新重命名文件数组
                renamedFiles[i+1] = newName
                
                -- 更新主插件列表（如果存在）
                if mainPlugin != undefined and isProperty mainPlugin #model_files_array then
                (
                    local index = findItem mainPlugin.model_files_array originalPath
                    if index > 0 do
                    (
                        mainPlugin.model_files_array[index] = newPath
                    )
                )
            )
            catch
            (
                item.SubItems.Item[2].Text = "失败: " + (getCurrentException())
            )
        )
        else
        (
            item.SubItems.Item[2].Text = "未找到匹配"
        )
        
        pbRename.value = i + 1
    )
    
    lblStatus.text = "替换文本完成! 成功: " + (successCount as string) + " / " + (LvFiles.Items.Count as string)
    true
)
    
    
-- 清理备份文件 - 只保留原始文件备份

fn cleanBackupFiles = 
(
    try
    (
        -- 增强路径验证
        local isValidBackupPath = (
            backupPath != undefined and 
            backupPath != "" and 
            doesDirectoryExist backupPath
        )
        
        if not isValidBackupPath do
        (
            messageBox "没有可清理的备份或备份路径无效!" title:"提示"
            return false
        )
        
        -- 获取备份目录中的所有文件
        local backupFiles = getFiles (backupPath + "\\*")
        
        if backupFiles.count == 0 do
        (
            messageBox "备份目录为空，没有文件需要清理!" title:"提示"
            return false
        )
        
        local deletedCount = 0
        
        for f in backupFiles do
        (
            try
            (
                deleteFile f
                deletedCount += 1
            )
            catch
            (
                format "[删除文件失败] %: %\n" f (getCurrentException())
            )
        )
        
        -- 删除备份目录
        try
        (
            deleteDir backupPath
        )
        catch
        (
            format "[删除目录失败] %: %\n" backupPath (getCurrentException())
            -- 即使目录删除失败，也继续执行
        )
        
        -- 更新状态
        backupPath = ""
        backupCreated = false
        
        -- 确保UI更新
        lblStatus.text = "备份已清理, 删除了 " + (deletedCount as string) + " 个备份文件"
        windows.processPostedMessages() -- 强制UI刷新
        
        -- 显示完成消息
        messageBox ("备份文件已成功清理, 删除了 " + (deletedCount as string) + " 个备份文件") title:"完成"
        
        -- 刷新右键菜单绑定
        refreshContextMenu()
        
        true
    )
    catch
    (
        --local errMsg = "清理备份失败: " + (getCurrentException())
        format "%\n" errMsg
        --messageBox errMsg title:"错误"
        false
    )
)
    
-- 恢复命名 - 从备份恢复原始文件
fn revertNames = 
(
    if backupPath == "" or not doesDirectoryExist backupPath do
    (
        messageBox "没有找到备份文件!" title:"错误"
        return false
    )
    
    pbRename.value = 0
    local successCount = 0
    
    for i = 0 to (LvFiles.Items.Count - 1) do
    (
        local item = LvFiles.Items.Item[i]
        local currentPath = item.Tag as String
        local originalName = item.Text
        local dirPath = getFilenamePath currentPath
        
        local backupFile = backupPath + originalName
        
        try
        (
            if doesFileExist backupFile do
            (
                -- 恢复文件
                deleteFile currentPath
                copyFile backupFile currentPath
                
                item.SubItems.Item[1].Text = originalName
                item.SubItems.Item[2].Text = "已恢复"
                successCount += 1
                
                -- 更新重命名文件数组
                renamedFiles[i+1] = originalName
                
                -- 更新主插件列表
                if mainPlugin != undefined and isProperty mainPlugin #model_files_array then
                (
                    local index = findItem mainPlugin.model_files_array currentPath
                    if index > 0 do
                    (
                        mainPlugin.model_files_array[index] = currentPath
                    )
                )
            )
        )
        catch
        (
            item.SubItems.Item[2].Text = "恢复失败: " + (getCurrentException())
        )
        
        pbRename.value = i + 1
    )
    
    lblStatus.text = "恢复完成! 成功恢复: " + (successCount as string) + " 个文件"
    
    -- 询问是否清理备份
    if successCount > 0 and (queryBox "是否清理备份文件?" title:"清理备份") do
    (
        cleanBackupFiles()
    )
    true
)
    
     
    --排序功能优化 / 备用
    fn sortByExtension = 
    (
        local items = for i=0 to (lvFiles.Items.Count-1) collect lvFiles.Items.Item[i]
        
        local folders = #()
        local files = #()
        
        -- 分离文件夹和文件
        for item in items do
        (
            local path = item.Tag as String
            if matchPattern path pattern:"*[DIR]*" or doesDirectoryExist path then
                append folders item
            else
                append files item
        )
        
        -- 对文件夹按名称排序
        fn folderCompare a b = (
            local nameA = a.SubItems.Item[1].Text
            local nameB = b.SubItems.Item[1].Text
            case of (
                (nameA < nameB): -1
                (nameA > nameB): 1
                default: 0
            )
        )
        
        -- 对文件按扩展名排序
        fn fileCompare a b = (
            local pathA = a.Tag as String
            local pathB = b.Tag as String
            local extA = toLower (getFilenameType pathA)
            local extB = toLower (getFilenameType pathB)
            
            -- 先按扩展名排序
            if extA != extB then (
                case of (
                    (extA < extB): -1
                    (extA > extB): 1
                )
            ) 
            -- 扩展名相同则按文件名排序
            else (
                local nameA = filenameFromPath pathA
                local nameB = filenameFromPath pathB
                case of (
                    (nameA < nameB): -1
                    (nameA > nameB): 1
                    default: 0
                )
            )
        )
        
        -- 排序
        qsort folders folderCompare
        qsort files fileCompare
        
        -- 清空并重新添加项目
        lvFiles.BeginUpdate()
        lvFiles.Items.Clear()
        
        for folder in folders do lvFiles.Items.Add folder
        for file in files do lvFiles.Items.Add file
        
        lvFiles.EndUpdate()
        lblStatus.text = "已按文件扩展名排序"
    )
    -- 浏览文件夹
    fn browseFolder = 
    (
        local initialDir = if edtCurrentPath.text != "" then edtCurrentPath.text else (getDir #scene)
        local folderPath = getSavePath caption:"选择文件夹" initialDir:initialDir
        
        if folderPath != undefined do
        (
            edtCurrentPath.text = folderPath
            loadFilesFromCurrentPath()
        )
    )
    
    -- 添加文件
    fn addFiles = 
    (
        local fileTypes = "All Supported Types|*.max;*.fbx;*.bip;*.xaf;*.ms;*.mse|Max Files (*.max)|*.max|FBX Files (*.fbx)|*.fbx|BIP Files (*.bip)|*.bip|XAF Files (*.xaf)|*.xaf|Script Files (*.ms)|*.ms|Encrypted Scripts (*.mse)|*.mse"
        local files = getOpenFileName caption:"选择文件" types:fileTypes multi:true
        
        if files != undefined do
        (
            -- 处理单个或多个文件
            if classOf files == String then
            (
                append originalFiles files
            )
            else if classOf files == Array then
            (
                for f in files do append originalFiles f
            )
            
            updateFileList()
            
            -- 更新文件计数
            local fileCount = 0
            for i = 0 to (lvFiles.Items.Count - 1) do
            (
                if lvFiles.Items.Item[i].SubItems.Item[2].Text != "文件夹" do fileCount += 1
            )
            
            lblStatus.text = "已添加 " + (files.count as string) + " 个文件，总共 " + (fileCount as string) + " 个文件"
        )
    )
    
    -- 创建备份（使用主插件的文件归档逻辑）
    fn createBackupFiles = 
    (
        if originalFiles.count == 0 do
        (
            messageBox "没有文件需要备份!" title:"提示"
            return false
        )
        
        -- 创建带时间戳的备份目录
        local timeArray = getLocalTime()
        local dateStamp = formattedPrint timeArray[1] format:"04d" +  
                          formattedPrint timeArray[2] format:"02d" +   
                          formattedPrint timeArray[4] format:"02d"
        
        -- 使用统一的临时备份目录                  
        local backupDir = (getDir #temp) + "\\RenameBackup_" + dateStamp + "\\"
        makeDir backupDir all:true
        
        local successCount = 0
        
        for i = 1 to originalFiles.count do
        (
            local filePath = originalFiles[i]
            if doesFileExist filePath then
            (
                local fileName = filenameFromPath filePath
                local targetPath = backupDir + fileName
                
                try
                (
                    copyFile filePath targetPath
                    successCount += 1
                )
                catch
                (
                    format "[备份失败] %\n" filePath
                )
            )
        )
        
        lblStatus.text = "备份完成! 成功备份 " + (successCount as string) + " / " + (originalFiles.count as string) + " 个文件到: " + backupDir
        ShellLaunch "explorer.exe" backupDir
        true
    )
    
    -- 事件处理
    on RenameToolRollout open do
    (
        initListView()
        
        -- 安全地获取路径
        local mainPluginPath = ""
        if (isValidObj AutoExportTool_Pro) and (isDialogVisible AutoExportTool_Pro) and (isProperty AutoExportTool_Pro #edtExportPath) then
        (
            mainPluginPath = AutoExportTool_Pro.edtExportPath.text
        )
        else
        (
            mainPluginPath = getDir #scene
        )
        
        edtCurrentPath.text = mainPluginPath
    )
    on btnCleanBackup  pressed do cleanBackupFiles ()
    on btnSortByExtension pressed do sortByExtension()
    on btnOpenExportPath pressed do OpenExportFromRenameTool()
    on btnSyncPath pressed do syncFilesFromMainPlugin()
    on btnAddSuffix pressed do addSuffix()
    on btnReplace pressed do replaceText()
    on btnRevert pressed do revertNames()
    on btnBackup pressed do createBackupFiles()
    on btnRefreshList pressed do loadFilesFromCurrentPath()
    on btnClearList pressed do (originalFiles = #(); updateFileList())
    on btnBrowse pressed do browseFolder()
    on btnAddFiles pressed do addFiles()
    on btnRemoveSelected pressed do removeSelectedItemsFromList()
    
    -- 拖放支持
    on lvFiles DragOver sender args do
    (
        args.Effect = args.Effect.Copy
    )
    
    on lvFiles DragDrop sender args do
    (
        local files = args.Data.GetData((dotNetClass "System.Windows.Forms.DataFormats").FileDrop)
        if files != undefined do
        (
            for f in files do
            (
                if doesFileExist f do
                (
                    append originalFiles f
                )
            )
            updateFileList()
        )
    )
)

--  ==============================-rollout-常用路径-区域-================================
-- 路径添加对话框完整逻辑 / true
-- ========== 目录管理对话框 ==========
rollout rolPathManager "路径管理" width:300 height:130 (
    
    edittext edtPathName "路径名称:" pos:[10,15] width:280 height:20
    edittext edtPathDir "目录路径:" pos:[10,45] width:210 height:20 readOnly:true
    button btnBrowse "浏览..." pos:[225,45] width:65 height:20
    button btnAdd "添加" pos:[10,75] width:135 height:25
    button btnCancel "取消" pos:[155,75] width:135 height:25
    label edtUserExPath "˖⁩ ℳ ❀ ͜♡︎ ›◕‿◕添加-Add-常用路径⇝UserPath！" align:#center
    
    -- 浏览按钮
    on btnBrowse pressed do (
        local initDir = if g_likedFolders.count > 0 then g_likedFolders[1].dir else getDir #scene
        local dir = getSavePath caption:"选择目录" initialDir:initDir
        if dir != undefined do (
            edtPathDir.text = pathConfig.normalizePath dir
        )
    )
    
    -- 添加按钮
    on btnAdd pressed do (
        clearlistener()
        try (
            case of (
                (edtPathName.text == ""): (messageBox "名称不能为空！" title:"错误")
                (edtPathDir.text == ""): (messageBox "路径不能为空！" title:"错误")
                default: (
                    local newName = trimRight (trimLeft edtPathName.text)
                    local newDir = pathConfig.normalizePath edtPathDir.text
                    
                    if not doesDirectoryExist newDir do (
                        messageBox "路径不存在，请选择有效目录！" title:"错误"
                        return undefined
                    )
                    
                    local exists = false
                    for f in g_likedFolders where (
                        stricmp f.name newName == 0 or 
                        (stricmp (pathConfig.normalizePath f.dir) newDir) == 0
                    ) do (exists = true; exit)
               
                    if not exists do (
                        append g_likedFolders (itemsFolder name:newName dir:newDir)
                        
                        -- 使用修复后的保存函数
                        if saveConfig() do (
                            try (
                                -- 刷新主界面下拉列表
                                AutoExportTool_Pro.ddlLikedPaths.items = for f in g_likedFolders collect f.name
                                
                                -- 自动选中新添加的项
                                local newIndex = findItem AutoExportTool_Pro.ddlLikedPaths.items newName
                                if newIndex > 0 do (
                                    AutoExportTool_Pro.ddlLikedPaths.selection = newIndex
                                )
                                
                                destroydialog rolPathManager
                                try (destroydialog rolPathManager) catch ()
                            ) catch (
                                -- 异常处理：添加失败时自动重启插件
                                local scriptPath = getSourceFileName()
                                local pluginDir = getFilenamePath scriptPath
                                append g_likedFolders (itemsFolder name:"FBX_MainScript_Pro" dir:pluginDir)
                                saveConfig()
                                destroyDialog AutoExportTool_Pro
                                fileIn scriptPath
                                createDialog AutoExportTool_Pro
                            )
                        )
                    )
                )
            )
        ) catch (
            format "[路径添加失败] %\n" (getCurrentException())
        )
    )
    
    on rolPathManager open do (
        try (
            if g_tempPathForManager != "" do (
                edtPathDir.text = g_tempPathForManager
                setFocus edtPathName
            )
        )
        catch (
            format "[路径管理初始化错误] %\n" (getCurrentException())
        )
    )
    
    on rolPathManager close do (
        try (
            g_tempPathForManager = ""
            g_pathManagerDialogOpen = false
        ) catch ()
    )
    
    on btnCancel pressed do (destroydialog rolPathManager)
)


----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------


--  ==============================-rollout-主区域-================================

rollout AutoExportTool_Pro "AutoExportTool_Pro" width:500 height:1050 -- width--宽度  在FN定义里修改--( fn updateButtonLayout ; AutoExportTool_Pro.width )

(
    -- ============================UI元素定义==================================

    -- 拖动区域标签（透明背景，位于顶层）
    label lblDragArea "👑 AutoExportTool_Pro" height:15 width:450 align:#center \
        offset:[-20,0] \
        tooltip:"Plugin Title/AutoExportTool/AniTool For Animator​/动画师工具" \
        color:(color 100 100 150) \
        transparent:true  -- 设置为透明背景 / true 
    -- 关闭插件按钮 / 标题 栏 设计 / X / true
    button btnClose "✕" width:18 height:18 align:#right offset:[8,-20] tooltip:"关闭插件"
    
    -- 使用 DotNet 标签作为拖动区域
    dotNetControl lblTitle "System.Windows.Forms.Label" height:22 width:490 align:#center \
    offset:[0,0] \
    tooltip:"左键拖动窗口"
    --transparent:true \ -- 设置为透明背景 / false 
	
    group "🌟 导出路径设置" (
       
        -- 在UI中添加说明
        --label lblEngineNote "注意: 导出到引擎时，角色文件夹将根据映射配置自动转换" align:#left offset:[0,5] \
        --tooltip:"本地中文名 → 引擎英文名"
        --checkbox chkExportToEngine "🍃导出到引擎" checked:false align:#right offset:[3,0] tooltip:"直接导出到引擎项目"
		--edittext edtEnginePath "📡引擎项目路径:" width:350 height:18 labelOnTop:true align:#left across:3 offset:[0,-15]
        --button btnBrowseEngine "..." width:20 height:20 align:#center offset:[127,3] toolTip:"设置引擎项目路径"
        --button btnBrowseEngine1 "🔶" width:20 height:20 align:#center offset:[-5,3] toolTip:"排版占位无功能"
		
		--button btnCharacterMapping "😈角色映射" width:70 height:22 align:#right offset:[0,-26] tooltip:"管理角色名称映射"
        
        
        edittext edtExportPath "🎴保存/FilePath:" width:345 height:18 labelOnTop:true align:#left across:4
        button btnBrowsePath "../+" width:25 height:20 align:#right across:4 offset:[138,18] toolTip:"左键：设置导出路径\n右键：自动填充常用path"
		button btnOpenExportPath "op📨" width:32 height:20 tooltip:"打开当前路径" across:2 align:#right offset:[55,18]
        button btn_resetFBXPath "🧚定位FBX" width:60 tooltip:"自动生成FBX路径" align:#right offset:[2,18]
        
		checkbox chkAutoFolder "Auto" checked:false across:4 align:#left offset:[-100,3] tooltip:"自动生成路径/FBX"  -- UI位移隐藏 / 无关紧要的功能，但有关联/备用
		
		button btnRenameTool "📝ReNm" width:50 checked:false align:#left offset:[-120,3] tooltip:"批量文件改名工具"
		
		checkbox chkAddDateSuffix "🔺.Ext_/" width:60 checked:false align:#left offset:[-185,7] tooltip:"归档时在文件名后添加-年-月-日"
		button btn_resetScene "🦉ℛeset" width:60 height:20 align:#right offset:[3,5] align:#right toolTip:"重置Max场景"
	    
        button btnResetPath "🃏Path⏎" width:52 offset:[145,-25] tooltip:"重置为有效路径" 
        button btnGC "♻️GC清理" width:70 align:#center offset:[-5,-26] tooltip:"清理场景垃圾内存"
        button btnRestartPlugin "💎重启插件" width:70 align:#right offset:[-130,-26] tooltip:"手动重启插件"
        button btnArchive "🧤文件归档" width:65 align:#left offset:[115,-26] tooltip:"按时间筛选最新文件并归档"
        
    ) 

    group "🤖 文件管理" (
        
        label edtmaxfilePath "˖⁩ ♡︎📝 › 拖拽or添加-max/文件//Read/Rslv//-列表更新//-双击打开/导入文件:" offset:[0,-6] align:#left toolTip:"支持大部分文件拖拽到列表，双击即可打开/导入"
		button btnParentPath "⏪" width:25 height:20 offset:[150,-17] tooltip:"返回上一层目录"
	    button btn_autoRead "  ེ🐉ℐRead" width:60 height:18 align:#right offset:[2,-22] toolTip:"读取当前"
		
		colorPicker cpFolder "ℱold-C:" width:80 color:(color 245 245 125) offset:[5,-3] align:#left      -- 默认淡黄 文件夹 /fold
        colorPicker cpFile "ℱile-P:" width:75 color:(color 255 225 255) offset:[100,-25] align:#left      -- 默认白色 文件/file
     
        button btnCleanRecent "🛡️R" width:30 height:18 align:#center offset:[15,-23] tooltip:"左键：设置显示数量为10个\n右键：彻底清空记录文件"
        button btnResetColor "🎭CP" width:30 height:18 align:#center offset:[-23,-23] toolTip:"恢复初始颜色CP"
        
        checkbox chkGridLines "GL" checked:false align:#right offset:[260,-16] across:3 toolTip:"列表网格线显示"
		checkbox chkChangeFont "ℱR" checked:true align:#right offset:[65,-16] toolTip:"切换字体列宽样式"
		slider sldBgColor "" width:75 height:20 range:[0,255,180] offset:[-44,-30] type:#integer  
        label lblBgValue "🌸" width:35 height:15 offset:[162,-25]  
		button btnApplyColor "🎨Set•ℂP " width:55 offset:[208,-23] tooltip:"应用新颜色"
        
        dropdownlist ddlLikedPaths "🔱常用路径🌐♾️:" width:95 height:12 align:#left offset:[0,-10] across:5 toolTip:"常用路径/ListBox" items:(for f in g_likedFolders collect f.name) -- 正确遍历 g_likedFolders
		
        button btnManagePaths "⚔常用目录" width:70 height:22 align:#left offset:[20,8] tooltip:"左-L：添加Add/路径\n右-R：删除Selete/选中\nCtrl+右键=ClearAll-!!!"
        button btnRecentFiles "📅最近打开" width:68 height:22  offset:[145,8] tooltip:"显示最近打开的MAX文件"
        button btnPluginDir "🧩插件目录" width:70 height:22 align:#center offset:[-97,8] tooltip:"L-左键: 插件目录\nR-右键: 备份目录"
        button btnAutoSave "⏱️自动保存" width:65 height:22 offset:[-115,8] tooltip:"监控自动保存目录MAX文件"
        button btnRefreshList "🔄RsLv" width:50 height:22 align:#right offset:[-3,-27] tooltip:"刷新当前路径列表"
        -- 修改文件类型筛选/单选按钮声明
        label rdoFileFilterType "⁎📊⁑›Ftype․⁌⁍•‣" align:#left 
        radiobuttons rdoFileFilter "" \
        labels:#("MAX","FBX","MS","BIP","MZP","XAF","全显示")\
        columns:7 \  -- 7列布局（6/类型+1/全显示）
        align:#center \
        width:480 \  -- 根据实际调整宽度
        offset:[90,-15] \
        tooltip:"文件类型筛选"

        dotNetControl lvHeader "System.Windows.Forms.ListView" width:480 height:22 aelign:#center offset:[-3,0]
        Dotnetcontrol Lv_model "system.windows.forms.listview" Width:480 Height:270 offset:[-3,-6]
        button btnBrowseFolder "📁 添加MAX文件" width:100 height:22 align:#left offset:[15,0] tooltip:"添加文件路径-列表只显示文件"
    
        button btn_removeSelected "❌ 移除选中项" width:90 height:22  offset:[0,-26] tooltip:"移除列表显示项/MoveItems"
        button btn_model_close "🗑️ 清空列表" width:100 height:22 align:#right offset:[-15,-26] tooltip:"清空列表所有/ClearLv.."
		label lblCount "文件：0" align:#right offset:[1000,0] tooltip:"文件总数"
        

        dotNetControl ModeStatus "System.Windows.Forms.ListView" width:480 height:22 aelign:#center offset:[-3,-20]
    )

    group "⚜️ FBX/批量/导出配置⚙️" (
        
        dropDownList selec_set ""  Width:128 labelOnTop:false across:4 offset:[-1,0]
        button btn_reset "⏲️刷新" width:50 height:25 offset:[-8,0]
        button btn_add_set "➕添加"  height:25 offset:[-60,0]
        button btn_del_set "➖移除"  height:25 offset:[-110,0]
        
        button btn_add_all "➕全选" width:60 height:25 offset:[135,-30]
        button btn_clear_all "➖清空" width:60 height:25 align:#right offset:[0,-30]
		
		edittext set_names "🌈选择集导出#☾🥑☽:" fieldWidth:350 readOnly:true offset:[0,5]               
        
		-- 导出模式单选按钮（参数修正）
        radiobuttons rdo_exportMode "💦导出模式 " \
        labels:#("Auto默认", "Skin模型", "Bake动画") \
        default:1 \
        align:#left \
        offset:[0,0] \
        toolTip:"选择FBX导出配置方案" \
        --button btn_selsetBatch "Set选择集" width:60 height:20 align:#right offset:[-15,-25] tooltip:"批量同步选择集到其他MAX文件"  -- false
        --button btnSelSetManager "⚘S/选择集" width:60 offset:[0,0] align:#left tooltip:"打开选择集管理面板"  -- false
		button btnOpenExportPath1 "op/💌" width:42 height:20 tooltip:"打开当前路径" align:#center offset:[0,-25]
        
        button btnExportBip "💾保存BIP" width:60 offset:[65,-25] tooltip:"保存 当前场景 BIP 文件"
        button btnImportBip "🎮加载BIP" width:60 offset:[135,-25] tooltip:"加载 当前场景 BIP 文件"
        button btnBatchSkinReplace "🦊Restyle" width:60 height:20 align:#right offset:[0,-25] tooltip:" 一键换皮 / new (max,bip,xaf) "
        
        checkbox auto_socket "自动挂点归零" across:5 offset:[25,5] tooltip:" 附件挂点 / view轴 (p/xyz:0;r/x:90,y,z:0) "
        button btnBatchMerge "🌸无限归并" width:70 height:20 align:#center offset:[10,3] tooltip:"批量合并挂点文件/挂点对齐链接🔗到骨骼"
		checkbox chk_autoOpenDir "↗ AutoOpen​" width:80 checked:true height:20 align:#center offset:[0,03] tooltip:"完成后自动打开目录"
        button btnBatchSyncSelSets "💠全域归集" width:70 align:#right offset:[-15,3] toolTip:"将当前场景文件的选择集同步更新到列表MAX文件"
		checkbox auto_makedir_set "按选择集分目录" checked:false align:#right offset:[10,7] tooltip:" 默认多个选择集名称作为导出FBX文件夹"
    )
    
    --UI 排版位置 空间有限 / 备用 / 不影响 核心功能 / XAF 导出导入
      --checkBox chk_useRotation "启用旋转模式控制" pos:[20,400]  -- false / 备用 / 未验证
       --radiobuttons rdo_rotation "" labels:#("TCB","Euler") pos:[150,400] visible:false  -- false / 备用 / 未验证
        --editText edt_excludePrefix "排除前缀:" text:"v_" pos:[250,400]  -- false / 备用 / 未验证
    
    group "BIP↹📥导出/入" (
		
        -- BIP模式单选按钮
        radiobuttons rdo_bipMode "BIP模式" 
        labels:#("导出BIP") \
        default:1 \
        align:#left \
        offset:[-100,5] \
        toolTip:"控制BIP文件操作方向" \
        
        --checkbox chkExportBones "↸导出XAF附件" checked:true across:2 offset:[135,-20] - flase
        --checkbox chkExportBip "↸导出Biped骨骼" checked:true align:#center offset:[-50,-20] - flase
        --checkbox chkAutoBip "☈AutoBiped" checked:true offset:[-17,-20] tooltip:"导入时自动创建骨骼系统" - flase
		
        button btn_bipBatchAll "✨ALL-导出BIP" width:80 height:20 align:#left offset:[25,-40] toolTip:"处理列表全部文件//导出Biped动画"
        button btn_bipBatchChecked "🏎️CK-导出BIP" width:80 height:20 align:#center offset:[-45,-25] toolTip:"批量处理勾选文件//导出Biped动画"
        button btnBatchImportBip "🏹批量BIP导入" width:80 align:#right offset:[-145,-25] toolTip:"批量导入列表//全部BIP文件"
        button btnMergeSegments "🧪合并分段动画" width:90 align:#right offset:[-20,-25] toolTip:"将勾选的分段MAX文件合并成一个完整的MAX文件"
        
        --button btn_exportCurrentBIP "🚩SC" width:45 height:20 align:#right offset:[-70,-25] toolTip:"导出当前场景的Biped动画" -- 新增按钮 - flase / 沉淀代码 / 备用
	)                       
    
    group "XAF🏴‍☠️编辑器↹导出/入" (
        button btnBatchExportXAF "🎆批量导出XAF" width:90 height:22 across:5 toolTip:"批量导出列表/全部MAX文件的xaf数据"
        button btnBatchExportXAFChecked "🦾勾选导出XAF" width:90 height:22 toolTip:"批量勾选导出列表/全部MAX文件的xaf数据"
        button btnOpenXAFEditor "🧬XAF编辑器" width:90 height:22 toolTip:"核心操作/xaf骨骼编辑/保存配置-关联xaf导出/入"
        checkbox chkXAFOverwrite "🌪️覆盖文件/XAF" checked:true width:80 offset:[5,5] toolTip:"xaf导入/勾选覆盖MAX原文件;未勾选则新建文件夹"
        button btnBatchImportXAF "🎇批量导入XAF" width:90 height:22 toolTip:"批量导入XAF_Exports/xaf数据到列表MAX文件"
    )
    
    group "FBX 🌙 操作控制" (
        
        --label edtExPath "˖⁩ ེ ҉ ♡︎ ›按-ESC-⇝可中断导出进程！" align:#left
        
        button btn_aotu_model "⚡批量导出" width:180 height:30 across:3 align:#left offset:[25,5] align:#left toolTip:"批量导出列表全部文件/支持文件夹"
        
        button btn_export_checked "🚀导出勾选" width:80 height:30 align:#center offset:[0,5] toolTip:"导出勾选的文件/不支持文件夹"         -- 新增按钮：导出勾选文件     
        
        button btn_exp_M_fbx "🎯导出当前" width:170 height:30 align:#right offset:[70,5] toolTip:"导出当前打开的场景文件"
        
	)
	
    --▶ 批量导出;★ 勾选导出;★ 导出当前;
    -- 进度条控件 ---------------------------------------------------------
    dotNetControl pbProgress "System.Windows.Forms.ProgressBar" width:470 height:20 offset:[0,5]
	label lblProgressInfo "♏准备就绪..." align:#center offset:[0,5] color:(color 200 100 0)
    hyperLink lbl_01 "(•◡•)ꦿ๊🍁ღ͜ ོYQiu_🧰AutoExportToolo-V1.09؄♓╰☆╮" \
    align:#Center \
    offset:[10,0] \
    color:(color 323 178 223) \  -- 主色调 (赛博蓝)
    hoverColor:(color 255 105 180) \  -- 悬停加深--（泡糖粉）
    address:"https://space.bilibili.com/327573825" \
    tooltip:"点击访问开发者的B站主页" \
    
    label lblDateTime "" align:#center offset:[177,-3] --（全显示/时分pos位置）；  

--/* 按钮样式示例 */ colour / 颜色参考 
--泡糖粉--RGB:color( 255 105 180 ) ；樱花粉-- RGB:color ( 255 182 193 ) ； -- 复古蓝 RGB:color( 135 206 250 )；婴儿蓝 RGB:color( 135 206 235 )；
--银灰 RGB:color( 192 192 192) ； --薰衣草紫 RGB:color( 216 191 216 )； -- s赛博蓝 RGB:color( 0 184 255 )；
---- 紫晶色RGB:color( 160 0 255 )  (RGB；-- 霓虹粉 (RGB:(color( 255 95 155 )；-- 亮黄 RGB:color( 255 255 0)
--147 197 253..
--button.btn_aotu_model (
    --foregroundColor: (color 255 255 255)  -- 白色文字
    --images: #("icon_export.png", undefined, 1, 1, 1, 1, 1) -- 可选的图标支持
--)

-- rollout 局部变量 ================================================================

local model_files_array = #()  -- 导出列表-稳定逻辑代码
local sele_set_list = #()       -- 添加选择集-稳定逻辑代码
local export_setsets = #()        -- 导出选择集-稳定逻辑代码

-- 函数定义 ================================================================
-- 批量处理主函数（FBX；BIP - ：默认列表全部/勾选/当前-导出,列表双击导入；一键换皮等...

-- 获取引擎导出路径（带角色映射）/ 备用 / 沉淀代码
fn getEngineExportPath sourcePath = (
    if not g_exportToEngine or g_engineProjectPath == "" do return undefined
    
    -- 提取角色名称（使用文件名或文件夹名）
    local charName = ""
    if matchPattern sourcePath pattern:"*[DIR]*" then (
        -- 文件夹路径
        local dirPath = substring sourcePath 6 -1
        charName = filenameFromPath dirPath
    ) else (
        -- 文件路径
        charName = getFilenameFile sourcePath
    )
    
    -- 移除可能的后缀
    charName = substituteString charName "_skin" ""
    charName = substituteString charName "_anim" ""
    
    -- 在映射表中查找
    local mappedDir = undefined
    for mapping in g_characterMappings do (
        if matchPattern charName pattern:("*" + mapping.name + "*") do (
            mappedDir = mapping.dir
            exit
        )
    )
    
    -- 返回映射路径或默认引擎路径
    if mappedDir != undefined then (
        return pathConfig.appendPath g_engineProjectPath mappedDir
    )
    g_engineProjectPath
)

-- 递归获取文件夹内所有.max文件
fn getAllMaxFilesInFolder folderPath = (
    local maxFiles = #()
    local files = getFiles (folderPath + "\\*.max")
    join maxFiles files
    
    -- 递归子文件夹
    local subDirs = getDirectories (folderPath + "\\*")
    for dir in subDirs do (
        join maxFiles (getAllMaxFilesInFolder dir)
    )
    maxFiles
)

-- 展开列表中的文件夹项
fn expandFolderItems items = (
    local expanded = #()
    for item in items do (
        if matchPattern item pattern:"[DIR]*" then (
            local folderPath = substring item 6 -1
            if doesDirectoryExist folderPath then (
                join expanded (getAllMaxFilesInFolder folderPath)
            )
        ) else (
            append expanded item
        )
    )
    expanded
)

-- 保存插件路径到INI
fn savePluginPath = (
    setINISetting g_UIConfigPath "Plugin" "Path" g_pluginPath
)

-- 重启插件函数
fn restartPlugin = (
    if doesFileExist g_pluginPath do (
        destroyDialog AutoExportTool_Pro  -- 关闭当前窗口
        fileIn g_pluginPath                -- 重新加载插件
    )
)

--在Biped导入/导出后，强制清理无效骨骼节点：在 processBipImport 和 SilentBipedImport 的末尾调用此函数（修复8.12，max2014.2020场景异常删除骨骼/注销)
--fn cleanupBipedNodes = (
    -- 删除所有未链接的Biped骨骼
    --for obj in objects where (classOf obj == Biped_Object and obj.parent == undefined) do (
        --try (delete obj) catch ()
    --)
    --gc()
--)

-- 新增函数：获取安全文件名/-替换所有 loadMaxFile 调用为 loadMaxFile ，规避场景异常，在加载或重置场景前，强制释放当前场景资源并恢复视图状态：
 -- 获取XAF文件中的骨骼列表（用于精确导入）
fn getXAFBoneList xafPath = (
    local boneList = #()
    
    try (
        local xDoc = dotNetObject "System.Xml.XmlDocument"
        xDoc.Load xafPath
        
        local nodes = xDoc.SelectNodes "//Node"
        for i = 0 to (nodes.Count - 1) do (
            local nameAttr = nodes.Item[i].SelectSingleNode "Properties/Property[@name='name']"
            if nameAttr != undefined do (
                append boneList nameAttr.InnerText
            )
        )
    )
    catch (
        format "[读取XAF骨骼列表错误] % : %\n" xafPath (getCurrentException())
    )
    
    boneList
)

-- 批量导出XAF函数 / 使用精确的骨骼收集和处理方法
fn batchExportXAF = (
    -- 检查XAF设置是否配置
    local boneList = loadXAFSettings()
    local exportMode = ""  -- 记录导出模式
    
    -- 确定导出模式
    if boneList.count == 0 then (
        exportMode = "自动收集所有骨骼和虚拟体"
    ) else (
        exportMode = "使用XAF配置的骨骼"
    )
    
    -- 显示导出模式确认对话框
    local confirmMsg = "即将开始XAF导出!\n\n"
    confirmMsg += "导出模式: " + exportMode + "\n"
    confirmMsg += (if boneList.count > 0 then "导出骨骼数量: " + (boneList.count as string) + "\n" else "")
    confirmMsg += "使用MAX原生SaveAnimation方法，确保所有变换数据精准。\n"
    confirmMsg += "是否开始导出?"
    
    if not (queryBox confirmMsg title:"XAF导出确认") do (
        lblProgressInfo.text = "XAF导出已取消"
        return undefined
    )
    
    -- 重置中断标志
    g_exportAbortFlag = false
    clearlistener()
    
    -- 计算总进度（只计算.max文件）
    local maxFileCount = 0
    local maxFiles = #()  -- 存储所有.max文件
    
    for item in model_files_array where not (matchPattern item pattern:"[DIR]*") and (getFilenameType item) == ".max" do (
        maxFileCount += 1
        append maxFiles item
    )
    
    if maxFileCount == 0 do (
        messageBox "文件列表中没有找到.max文件！" title:"操作中止" beep:true
        return undefined
    )
    
    pbProgress.value = 0
    pbProgress.maximum = maxFileCount
    pbProgress.Refresh()
    btnBatchExportXAF.enabled = false
    
    local successCount = 0
    local exportBaseDir = ""  -- 导出基础目录
    
    -- 确定导出基础目录
    if maxFilePath != "" then (
        -- 使用当前打开文件的目录
        exportBaseDir = maxFilePath + "XAF_Exports\\"
    ) else if maxFiles.count > 0 then (
        -- 使用第一个文件的目录
        exportBaseDir = (getFilenamePath maxFiles[1]) + "XAF_Exports\\"
    ) else (
        -- 使用场景目录作为后备
        exportBaseDir = (getDir #scene) + "XAF_Exports\\"
    )
    
    -- 创建导出目录
    if not doesDirectoryExist exportBaseDir do (
        makeDir exportBaseDir all:true
        format "[创建目录] %\n" exportBaseDir
    )
    
    -- 显示导出模式信息
    lblProgressInfo.text = "XAF导出模式: " + exportMode + " | 文件数量: " + (maxFileCount as string)
    windows.processPostedMessages()
    sleep 1.0  -- 短暂显示信息
    
    -- 主处理循环 - 只处理.max文件
    for i = 1 to maxFiles.count where not g_exportAbortFlag do (
        -- ESC键检测
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            format "[用户中断] XAF导出进程已被手动终止\n"
            lblProgressInfo.text = "操作已中断！" 
            windows.processPostedMessages()
            messageBox "XAF导出进程已被用户中断！" title:"操作提示" beep:true
            exit
        )

        -- 处理当前文件
        local currentFile = maxFiles[i]
        local currentMaxFileName = getFilenameFile currentFile
        lblProgressInfo.text = "正在处理文件：" + currentMaxFileName + " (" + (i as string) + "/" + (maxFiles.count as string) + ")"
        
        -- 加载文件
        if (loadMaxFile currentFile quiet:true) then (
            -- 使用精确的骨骼收集方法
            local saveBoneAni = for obj in objects where (
                classof obj == BoneGeometry or 
                classof obj == Dummy or 
                classof obj == Point
            ) collect obj
            
            -- 去除重复骨骼（按名称）- 精确去重逻辑
            local tempArr = #()
            for j = 1 to saveBoneAni.count-1 do (
                for k = j+1 to saveBoneAni.count do (
                    if saveBoneAni[j].name == saveBoneAni[k].name do (
                        append tempArr (if saveBoneAni[k] == undefined then saveBoneAni[k] else saveBoneAni[j])
                    )
                )
            )
            
            -- 删除重复项
            if tempArr.count != 0 do (
                for obj in tempArr do (
                    for p = saveBoneAni.count to 1 by -1 do (
                        if saveBoneAni[p] == obj do deleteItem saveBoneAni p
                    )
                )
            )
            
            -- 如果使用XAF配置，过滤骨骼
            if exportMode == "使用XAF配置的骨骼" and boneList.count > 0 do (
                local filteredBones = #()
                for bone in saveBoneAni do (
                    if findItem boneList bone.name > 0 do append filteredBones bone
                )
                saveBoneAni = filteredBones
                
                -- 选择这些骨骼以便用户验证
                select saveBoneAni
                format "[选择骨骼] 已选择 % 个配置的骨骼进行导出\n" saveBoneAni.count
            )
            
            -- 确保所有对象都有有效的变换控制器（保持原有控制器）
            for obj in saveBoneAni do (
                try (
                    -- 确保位置控制器有效
                    if obj.pos.controller == undefined do (
                        obj.pos.controller = Bezier_Position()
                    )
                    
                    -- 确保旋转控制器有效
                    if obj.rotation.controller == undefined do (
                        obj.rotation.controller = Euler_XYZ()
                    )
                    
                    -- 确保缩放控制器有效
                    if obj.scale.controller == undefined do (
                        obj.scale.controller = Bezier_Scale()
                    )
                ) catch (
                    format "[警告] 无法为 % 设置变换控制器\n" obj.name
                )
            )

            if saveBoneAni.count > 0 then (
                -- 构建XAF文件路径
                local xafPath = exportBaseDir + currentMaxFileName + ".xaf"
                
                -- 使用MAX原生方法保存动画
                local userAttr = #()
                local userVal = #()
                
                try (
                    -- 模拟MAX原生导出选项 - 使用与原生Save Animation相同的参数
                    LoadSaveAnimation.saveAnimation xafPath saveBoneAni &userAttr &userVal
                    
                    -- 验证导出文件
                    if doesFileExist xafPath then (
                        format "[XAF导出成功] 已导出到: % | 骨骼数量: %\n" xafPath saveBoneAni.count
                        successCount += 1
                        
                        -- 保存时间范围信息
                        local timeRangeFile = exportBaseDir + currentMaxFileName + "_time.txt"
                        try (
                            local fs = createFile timeRangeFile
                            local sourceTimeRange = #(animationRange.start, animationRange.end)
                            format "%\n" sourceTimeRange to:fs
                            close fs
                            format "[时间范围保存] %\n" timeRangeFile
                        ) catch (
                            format "[警告] 时间范围保存失败: %\n" (getCurrentException())
                        )
                    ) else (
                        format "[XAF导出错误] 文件创建失败: %\n" xafPath
                    )
                )
                catch (
                    format "[XAF导出错误] 文件: % 错误: %\n" currentFile (getCurrentException())
                )
            )
            else (
                format "[警告] 文件 % 中没有找到可导出的骨骼或虚拟体\n" currentMaxFileName
            )
            
            -- 重置场景
            resetMaxFile #noPrompt
        )
        else (
            format "[错误] 无法加载文件：%\n" currentFile
        )
        
        -- 更新进度
        pbProgress.value = i
        
        -- 更新进度显示
        local progressPercent = (i as float / maxFiles.count * 100) as integer
        lblProgressInfo.text = "进度：" + (progressPercent as string) + "% | 成功：" + (successCount as string)
        windows.processPostedMessages()
    )
    
    -- 刷新文件列表
    AutoExportTool_Pro.refreshFileListView()
    
    -- 完成处理 - 确保进度条满格
    pbProgress.value = pbProgress.maximum
    
    local completionMsg = "XAF批量导出完成！成功导出 " + (successCount as string) + " 个文件"
    lblProgressInfo.text = completionMsg
    btnBatchExportXAF.enabled = true
    
    -- 显示完成消息
    messageBox ("XAF导出完成！\n\n导出模式: " + exportMode + "\n成功导出: " + (successCount as string) + " 个文件\n导出目录: " + exportBaseDir) title:"XAF导出完成"
    
    if chk_autoOpenDir.checked do ShellLaunch "explorer.exe" exportBaseDir
)

-- 批量XAF导出勾选文件 / 使用精确的骨骼收集和处理方法
fn batchExportXAFChecked = (
    -- 检查是否有勾选的文件
    local checkedFiles = #()
    for i = 0 to (Lv_model.Items.Count - 1) do (
        if Lv_model.Items.Item[i].Checked and not (matchPattern (Lv_model.Items.Item[i].Tag as String) pattern:"[DIR]*") then (
            append checkedFiles (Lv_model.Items.Item[i].Tag as String)
        )
    )
    
    -- 过滤出.max文件
    local maxFiles = for f in checkedFiles where (getFilenameType f) == ".max" collect f
    
    if maxFiles.count == 0 do (
        messageBox "请先勾选要导出的.max文件！" title:"操作提示"
        return false
    )
    
    -- 临时替换全局文件列表，然后调用主导出函数
    local originalFiles = model_files_array
    model_files_array = maxFiles
    batchExportXAF()
    model_files_array = originalFiles  -- 恢复原始列表
)

-- 清除骨骼上的动画数据 /   提升 xaf 导入 数据 精准度 移除 旧数据 （对应的 xaf数据 相关 骨骼 动画帧的删除，导入前做一次精准导入）

fn clearBoneAnimation boneObjects = (
    try (
        for bone in boneObjects do (
            if isValidNode bone do (
                -- 清除变换控制器上的所有关键帧
                if bone.transform.controller != undefined do (
                    try (
                        deleteKeys bone.transform.controller #allKeys
                    )
                    catch (
                        format "[清除关键帧错误] %: %\n" bone.name (getCurrentException())
                    )
                )
                
                -- 对于Biped骨骼，需要特殊处理
                if classOf bone == Biped_Object do (
                    try (
                        biped.deleteKeys bone.controller #allKeys
                    )
                    catch (
                        format "[清除Biped关键帧错误] %: %\n" bone.name (getCurrentException())
                    )
                )
            )
        )
        true
    )
    catch (
        format "[清除动画错误] %\n" (getCurrentException())
        false
    )
)

-- 从XAF文件中提取骨骼名称列表（新函数，避免名称冲突）
fn extractBoneNamesFromXAF xafPath = (
    local boneNames = #()
    
    try (
        -- 保存当前场景状态
        local holdState = holdMaxFile()
        
        -- 创建一个临时场景来读取XAF信息
        resetMaxFile #noPrompt
        
        -- 创建几个临时骨骼来读取XAF信息
        local tempBones = #()
        for i = 1 to 5 do (
            local tempBone = BoneSys.createBone [i*20,0,0] [(i+1)*20,0,0] [0,0,1]
            tempBone.name = "TempBoneForXAFRead_" + (i as string)
            append tempBones tempBone
        )
        
        -- 尝试加载XAF文件
        local userAttr = #()
        local userVal = #()
        LoadSaveAnimation.loadAnimation xafPath tempBones relative:true insert:true
        
        -- 获取XAF文件中的骨骼信息
        -- 这里我们假设XAF文件会修改临时骨骼的名称或属性
        -- 但实际上，我们需要更直接的方法来读取XAF内容
        
        -- 删除临时骨骼
        for bone in tempBones do (
            try (delete bone) catch ()
        )
        
        -- 恢复原始场景
        fetchMaxFile quiet:true
    )
    catch (
        format "[XAF读取错误] %: %\n" xafPath (getCurrentException())
    )
    
    boneNames
)

-- 替代方案：直接从XAF配置获取骨骼名称（更可靠的方法）
fn getBoneNamesFromXAFConfig = (
    local boneNames = loadXAFSettings()
    if boneNames.count == 0 do (
        -- 如果没有配置，尝试从场景中获取所有骨骼名称
        boneNames = for obj in objects where (
            classof obj == BoneGeometry or 
            classof obj == Dummy or 
            classof obj == Point or
            classof obj == Biped_Object
        ) collect obj.name
    )
    boneNames
)

-- 改进的批量导入XAF函数 / 结合 xaf 编辑器
fn batchImportXAF = (
    -- 重置中断标志
    g_exportAbortFlag = false
    clearlistener()
    
    -- 检查XAF设置是否配置
    local boneList = loadXAFSettings()
    local importMode = if boneList.count == 0 then "全部导入" else "XAF配置导入"
    
    -- 确定文件保存模式
    local saveMode = if chkXAFOverwrite.checked then "覆盖原文件" else "新建文件(XAF_Import)"
    
    -- 显示导入模式确认对话框
    local confirmMsg = "即将开始XAF导入!\n\n"
    confirmMsg += "导入模式: " + importMode + "\n"
    confirmMsg += "文件保存模式: " + saveMode + "\n"
    confirmMsg += (if boneList.count > 0 then "导入骨骼数量: " + (boneList.count as string) + "\n" else "")
    confirmMsg += "使用MAX原生LoadAnimation方法，确保所有变换数据精准。\n"
    confirmMsg += "是否开始导入?"
    
    if not (queryBox confirmMsg title:"XAF导入确认") do (
        lblProgressInfo.text = "XAF导入已取消"
        return undefined
    )
    
    -- 初始化进度控制
    pbProgress.value = 0
    
    -- 计算总进度（只计算.max文件）
    local maxFileCount = 0
    local maxFiles = #()
    
    for item in model_files_array where not (matchPattern item pattern:"[DIR]*") and (getFilenameType item) == ".max" do (
        maxFileCount += 1
        append maxFiles item
    )
    
    if maxFileCount == 0 do (
        messageBox "文件列表中没有找到.max文件！" title:"操作中止" beep:true
        return undefined
    )
    
    pbProgress.maximum = maxFileCount
    pbProgress.Refresh()
    btnBatchImportXAF.enabled = false
    
    local successCount = 0
    
    -- 主处理循环
    for i = 1 to maxFiles.count where not g_exportAbortFlag do (
        -- ESC键检测
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            format "[用户中断] XAF导入进程已被手动终止\n"
            lblProgressInfo.text = "操作已中断！" 
            windows.processPostedMessages()
            messageBox "XAF导入进程已被用户中断！" title:"操作提示" beep:true
            exit
        )

        -- 处理当前文件
        local currentFile = maxFiles[i]
        local currentFileName = getFilenameFile currentFile
        lblProgressInfo.text = "正在处理文件：" + currentFileName + " (" + (i as string) + "/" + (maxFiles.count as string) + ")"
        
        -- 确定XAF文件路径
        local xafPath = ""
        
        -- 首先尝试在XAF_Exports目录中查找
        local exportDir = (getFilenamePath currentFile) + "XAF_Exports\\"
        local xafFile1 = exportDir + currentFileName + ".xaf"
        
        -- 其次尝试在当前目录查找
        local xafFile2 = (getFilenamePath currentFile) + currentFileName + ".xaf"
        
        if doesFileExist xafFile1 then (
            xafPath = xafFile1
        ) else if doesFileExist xafFile2 then (
            xafPath = xafFile2
        ) else (
            format "[警告] 找不到XAF文件: %\n" currentFileName
            pbProgress.value = i
            continue
        )
        
        -- 确定目标文件路径
        local targetFilePath = currentFile
        if not chkXAFOverwrite.checked do (
            -- 创建新文件夹并保存文件
            local importDir = (getFilenamePath currentFile) + "XAF_Import\\"
            if not doesDirectoryExist importDir do (
                makeDir importDir all:true
                format "[创建目录] %\n" importDir
            )
            
            -- 创建新文件名
            local newFileName = currentFileName + ".max"
            targetFilePath = importDir + newFileName
            
            -- 检查文件是否已存在，如果存在则添加序号
            local counter = 1
            while doesFileExist targetFilePath do (
                newFileName = currentFileName + "_" + (counter as string) + ".max"
                targetFilePath = importDir + newFileName
                counter += 1
            )
        )
        
        -- 加载MAX文件
        if (loadMaxFile currentFile quiet:true) then (
            -- 收集要导入动画的骨骼
            local importBones = #()
            
            if importMode == "XAF配置导入" and boneList.count > 0 then (
                -- 使用XAF配置的骨骼列表
                for boneName in boneList do (
                    local boneObj = getNodeByName boneName
                    if isValidNode boneObj do append importBones boneObj
                )
                
                -- 选择这些骨骼以便用户验证
                select importBones
                format "[选择骨骼] 已选择 % 个配置的骨骼进行导入\n" importBones.count
            ) else (
                -- 自动收集所有骨骼和虚拟体
                importBones = for obj in objects where (
                    classof obj == BoneGeometry or 
                    classof obj == Dummy or 
                    classof obj == Point or
                    classof obj == Biped_Object
                ) collect obj
                
                -- 尝试从XAF文件中提取骨骼名称（使用新函数）
                local xafBoneNames = extractBoneNamesFromXAF xafPath
                if xafBoneNames.count > 0 do (
                    -- 如果成功从XAF文件中提取到骨骼名称，过滤骨骼列表
                    local filteredBones = #()
                    for bone in importBones do (
                        if findItem xafBoneNames bone.name > 0 do append filteredBones bone
                    )
                    if filteredBones.count > 0 do importBones = filteredBones
                )
            )
            
            if importBones.count > 0 do (
                -- 清除骨骼上的原有动画
                if clearBoneAnimation importBones then (
                    format "[清除动画成功] 已清除 % 个骨骼的动画数据\n" importBones.count
                ) else (
                    format "[清除动画失败] 可能无法完全清除所有骨骼的动画\n"
                )
                
                -- 导入XAF
                try (
                    local userAttr = #()
                    local userVal = #()
                    
                    LoadSaveAnimation.loadAnimation xafPath importBones relative:true insert:true
                    format "[XAF导入成功] 已导入: %\n" xafPath
                    
                    -- 保存文件
                    saveMaxFile targetFilePath
                    successCount += 1
                    
                    -- 显示保存信息
                    if not chkXAFOverwrite.checked do (
                        format "[文件保存] 已保存到: %\n" targetFilePath
                    )
                )
                catch (
                    format "[XAF导入错误] 文件: % 错误: %\n" xafPath (getCurrentException())
                )
            )
            
            -- 重置场景
            resetMaxFile #noPrompt
        )
        else (
            format "[错误] 无法加载文件：%\n" currentFile
        )
        
        -- 更新进度
        pbProgress.value = i
        
        -- 更新进度显示
        local progressPercent = (i as float / maxFiles.count * 100) as integer
        lblProgressInfo.text = "进度：" + (progressPercent as string) + "% | 成功：" + (successCount as string)
        windows.processPostedMessages()
    )
    
    -- 完成处理
    lblProgressInfo.text = "XAF批量导入完成！成功导入 " + (successCount as string) + " 个文件"
    btnBatchImportXAF.enabled = true
    
    -- 显示完成消息
    local completionMsg = "XAF导入完成！\n\n"
    completionMsg += "导入模式: " + importMode + "\n"
    completionMsg += "文件保存模式: " + saveMode + "\n"
    completionMsg += "成功导入: " + (successCount as string) + " 个文件"
    
    messageBox completionMsg title:"XAF导入完成"
)

-- 一键换皮- 安全获取/skin 名称字符串形式识别-/定义/ 识别 带 skin 的 文件 不作处理 
fn getSafeSkinName fPath = (
    local baseName = getFilenameFile fPath
    -- 移除了对"@"的替换，只替换空格
    substituteString baseName " " "_"
    baseName
)

-- 一键换皮/修正后的报告生成函数（保持stringStream结构）
fn generateReplacementReport processFiles outputDir = (
    local reportData = stringStream "" -- 保持stringStream类型
    
    try (
        -- 参数校验增强
        if classOf processFiles != Array OR processFiles.count == 0 do (
            format "[报告错误] 无效的文件列表参数\n"
            return reportData
        )
        
        if not doesDirectoryExist outputDir do (
            makeDir outputDir all:true -- 自动创建目录
            format "[报告提示] 已创建输出目录：%\n" outputDir
        )

        -- 报告头信息（使用标准格式）
        format "====== 批量换皮操作报告 ======\n" to:reportData
        format "生成时间：%\n" (localTime as string) to:reportData
        format "皮肤模板文件：%\n" (maxFilePath + maxFileName) to:reportData
        format "处理文件总数：%\n\n" processFiles.count to:reportData

        -- 全局统计
        local totalOldBones = 0
        local totalNewBones = 0
        local totalDiffBones = 0
        local versionInfo = #()

        -- 安全处理每个文件
        for i=1 to processFiles.count do (
            local oldFile = processFiles[i]
            if not doesFileExist oldFile do (
                format "[跳过] 文件不存在：%\n" oldFile
                continue
            )
            
            try (
                -- 文件基础信息
                local oldFileName = getFilenameFile oldFile
                local newFilePath = pathConfig.appendPath outputDir (oldFileName + "_Replaced.max")
                
                -- 版本信息采集
                local fileVersion = try(getFileVersion oldFile)catch("未知版本")
                append versionInfo #(oldFileName, fileVersion)

                -- 骨骼信息对比
                local oldBones = #()
                local newBones = #()
                local diffBones = #()

                -- 旧文件骨骼收集
                if loadMaxFile oldFile quiet:true do (
                    oldBones = for obj in objects where isAttachmentBone obj collect obj.name
                    resetMaxFile #noPrompt
                )

                -- 新文件骨骼收集
                if doesFileExist newFilePath AND loadMaxFile newFilePath quiet:true do (
                    newBones = for obj in objects where isAttachmentBone obj collect obj.name
                    resetMaxFile #noPrompt
                )

                -- 差异计算
                diffBones = for b in newBones where findItem oldBones b == 0 collect b

                -- 更新统计
                totalOldBones += oldBones.count
                totalNewBones += newBones.count
                totalDiffBones += diffBones.count

                -- 写入报告
                format "\n=== 文件：% ===\n" oldFileName to:reportData
                format "MAX版本：%\n" (fileVersion as string) to:reportData
                format "旧骨骼数：% | 新骨骼数：% | 差异骨骼数：%\n" \
                    oldBones.count \
                    newBones.count \
                    diffBones.count \
                    to:reportData
                
                if diffBones.count > 0 do (
                    format "差异骨骼列表：%\n" (diffBones as string) to:reportData
                )
            )
            catch (
                format "[文件处理错误] % : %\n" oldFile (getCurrentException()) to:reportData
            )
        )

        -- 全局统计（添加容错处理）
        format "\n====== 全局统计 ======\n" to:reportData
        format "总处理文件：%\n" processFiles.count to:reportData
        if processFiles.count > 0 do (
            format "平均旧骨骼数：%.1f\n" (totalOldBones as float / processFiles.count) to:reportData
            format "平均新骨骼数：%.1f\n" (totalNewBones as float / processFiles.count) to:reportData
        )
        format "总差异骨骼数：%\n" totalDiffBones to:reportData

        -- 版本信息输出
        format "\n====== 文件版本信息 ======\n" to:reportData
        for entry in versionInfo do (
            format "文件：% | 版本：%\n" entry[1] (entry[2] as string) to:reportData
        )
    )
    catch (
        format "\n[报告生成致命错误] %\n" (getCurrentException()) to:reportData
    )
    
    reportData -- 返回stringStream对象
)

-- 一键换皮/在结构体定义后添加附件骨骼过滤器
fn isAttachmentBone obj = (
    classOf obj == BoneGeometry or 
    classOf obj == Dummy or 
    classOf obj == Point
)

-- 一键换皮/使用版本无关的Biped接口
fn getBipedRoot = (
    try(biped.getRootNode selection[1])catch(
        try(BipedSys.getRootNode())catch(undefined)
    )
)

-- 一键换皮/添加文件保存重试逻辑
fn safeSaveFile path retry = (
    for i=1 to retry do (
        try (
            saveMaxFile path
            return true
        ) catch (
            format "保存失败(尝试%次)，等待重试...\n" i
            sleep 1.0
        )
    )
    false
)

-- 一键换皮//文件整理函数
fn organizeXafFiles outputDir = (
    local xafDir = pathConfig.appendPath outputDir "SkinReplace_Xaf"
    makeDir xafDir all:true
    
    -- 搜索所有层级的XAF文件（包括错误嵌套的情况）
    local allXafFiles = getFiles (pathConfig.appendPath outputDir "**/*.xaf") 
    
    for f in allXafFiles do (
        -- 提取纯文件名
        local fileName = filenameFromPath f
        local targetPath = pathConfig.appendPath xafDir fileName
        
        -- 强制覆盖已存在文件
        if copyFile f targetPath then (
            deleteFile f
            format "[文件整理] 迁移：% ➔ %\n" f targetPath
        )
    )
    
    -- 清理空目录（增强版）
    local subDirs = getDirectories (pathConfig.appendPath outputDir "*")
    for d in subDirs where d != xafDir do (
        try (deleteDir d all:true) catch (
            format "[警告] 无法删除目录：%\n" d
        )
    )
)

fn exportAttachmentBones fPath exportDir = (
    try (
        -- 确保导出目录存在
        if not doesDirectoryExist exportDir do (
            makeDir exportDir all:true
            format "[创建目录] %\n" exportDir
        )
        
        -- 加载文件
        if not (loadMaxFile fPath quiet:true) do return false
        
        -- 使用与batchExportXAF相同的骨骼收集方法
        local saveBoneAni = for obj in objects where (
            classof obj == BoneGeometry or 
            classof obj == Dummy or 
            classof obj == Point or
            classof obj == Biped_Object
        ) collect obj
        
        -- 去除重复骨骼（按名称）- 精确去重逻辑
        local tempArr = #()
        for j = 1 to saveBoneAni.count-1 do (
            for k = j+1 to saveBoneAni.count do (
                if saveBoneAni[j].name == saveBoneAni[k].name do (
                    append tempArr (if saveBoneAni[k] == undefined then saveBoneAni[k] else saveBoneAni[j])
                )
            )
        )
        
        -- 删除重复项
        if tempArr.count != 0 do (
            for obj in tempArr do (
                for p = saveBoneAni.count to 1 by -1 do (
                    if saveBoneAni[p] == obj do deleteItem saveBoneAni p
                )
            )
        )
        
        -- 确保所有对象都有有效的变换控制器
        for obj in saveBoneAni do (
            try (
                -- 确保位置控制器有效
                if obj.pos.controller == undefined do (
                    obj.pos.controller = Bezier_Position()
                )
                
                -- 确保旋转控制器有效
                if obj.rotation.controller == undefined do (
                    obj.rotation.controller = Euler_XYZ()
                )
                
                -- 确保缩放控制器有效
                if obj.scale.controller == undefined do (
                    obj.scale.controller = Bezier_Scale()
                )
            ) catch (
                format "[警告] 无法为 % 设置变换控制器\n" obj.name
            )
        )

        if saveBoneAni.count > 0 do (
            -- 构建XAF文件路径
            local baseName = getFilenameFile fPath
            local xafPath = exportDir + "\\" + baseName + ".xaf"  -- 直接保存到指定目录
            
            -- 使用MAX原生方法保存动画
            local userAttr = #()
            local userVal = #()
            
            try (
                LoadSaveAnimation.saveAnimation xafPath saveBoneAni &userAttr &userVal
                format "[XAF导出成功] 路径：%\n" xafPath
                
                -- 保存时间范围信息
                local timeRangeFile = exportDir + "\\" + baseName + "_time.txt"
                try (
                    local fs = createFile timeRangeFile
                    local sourceTimeRange = #(animationRange.start, animationRange.end)
                    format "%\n" sourceTimeRange to:fs
                    close fs
                    format "[时间范围保存] %\n" timeRangeFile
                ) catch (
                    format "[警告] 时间范围保存失败: %\n" (getCurrentException())
                )
                
                return true
            )
            catch (
                format "[XAF导出错误] 文件: % 错误: %\n" fPath (getCurrentException())
                return false
            )
        )
        
        -- 重置场景
        resetMaxFile #noPrompt
        return false
    )
    catch (
        format "[XAF导出失败] % : %\n" fPath (getCurrentException())
        resetMaxFile #noPrompt
        return false
    )
)

-- 一键换皮 / 使用稳定的XAF导入功能
fn importXafAnimation fPath = (
    try (
        -- 检查XAF设置是否配置
        local boneList = loadXAFSettings()
        local importMode = if boneList.count == 0 then "全部导入" else "XAF配置导入"
        
        -- 收集要导入动画的骨骼
        local importBones = #()
        
        if importMode == "XAF配置导入" and boneList.count > 0 then (
            -- 使用XAF配置的骨骼列表
            for boneName in boneList do (
                local boneObj = getNodeByName boneName
                if isValidNode boneObj do append importBones boneObj
            )
        ) else (
            -- 自动收集所有骨骼和虚拟体
            importBones = for obj in objects where (
                classof obj == BoneGeometry or 
                classof obj == Dummy or 
                classof obj == Point or
                classof obj == Biped_Object
            ) collect obj
        )
        
        if importBones.count == 0 do (
            messageBox "场景中没有找到可用的骨骼或虚拟体！" title:"错误"
            return false
        )
        
        -- 清除骨骼上的原有动画
        if not clearBoneAnimation importBones do (
            format "[警告] 无法完全清除所有骨骼的动画\n"
        )
        
        -- 加载动画
        LoadSaveAnimation.loadAnimation fPath importBones relative:true insert:true
        format "[成功] 已导入XAF动画：%\n" fPath
        return true
    ) catch (
        format "[XAF导入错误] %\n" (getCurrentException())
        return false
    )
)
-- 一键换皮//在BIP导入函数后添加附件/骨骼导入函数

fn importAttachmentBones fPath = (
    try (
        local loadBoneAni = #()
        local regex = (dotnetclass "System.Text.RegularExpressions.Regex")
        
        -- 完全使用new的UI控件引用方式
        local excludePrefix = Bip_batchTool.batchUtil_R.ed_text_name.text
        
        for obj in geometry where (
            classOf obj == BoneGeometry and 
            (
                excludePrefix == "" or 
                not regex.IsMatch obj.name ("^" + excludePrefix) -- new
            )
        ) collect obj
        
        -- 旋转模式控制(保持new逻辑)
        if Bip_batchTool.batchUtil_R.tcbEuler_chk.checked do (
            case Bip_batchTool.batchUtil_R.tcbEulerStyle_rdo.state of (
                1: (for o in loadBoneAni do o.rotation.controller = TCB_Rotation())
                2: (for o in loadBoneAni do o.rotation.controller = Euler_XYZ())
            )
        )

        -- 严格遵循new的加载方式
        LoadSaveAnimation.loadAnimation fPath loadBoneAni relative:true insert:true
        true
    )
    catch (
        format "Error: %\n" (getCurrentException())
        false
    )
)

-- 一键换皮//核心换皮功能函数
fn processSkinReplacement = (
    g_exportAbortFlag = false
    pbProgress.value = 0
    lblProgressInfo.text = "准备开始换皮..."
    
    -- 自动查找根骨骼逻辑
    fn findRootBones = (
        local allBones = for obj in objects where isAttachmentBone obj collect obj
        local rootBones = #()
        
        -- 添加Biped系统检测
        local bipedRoots = for obj in objects where classOf obj == Biped_Object collect obj
        if bipedRoots.count > 0 do (
            append rootBones bipedRoots[1]  -- 优先使用Biped根骨骼
            return rootBones
        )
        
        -- 标准骨骼检测
        for b in allBones do (
            if b.parent == undefined or (findItem allBones b.parent) == 0 do (
                append rootBones b
            )
        )
        
        -- 添加空值保护
        if rootBones.count == 0 do (
            messageBox "未找到任何有效根骨骼！" title:"骨骼错误"
            return #()
        )
        rootBones
    )
    
    -- 验证场景骨骼
    local rootBones = findRootBones()
    if rootBones.count == 0 do (
        return false
    )
    
    -- 获取当前皮肤文件信息（优先使用当前打开的场景作为模板）
    local currentSkinFile = maxFilePath + maxFileName
    local currentSkinName = getFilenameFile currentSkinFile
    
    -- 创建标准目录结构
    local outputDir = pathConfig.appendPath (getDir #scene) g_skinNewFolderName
    local bipDir = pathConfig.appendPath outputDir "SkinReplace_Bip"  -- BIP存储目录
    local boneDir = pathConfig.appendPath outputDir "SkinReplace_Xaf" -- 附件骨骼目录
    makeDir outputDir all:true
    makeDir bipDir all:true
    makeDir boneDir all:true
    
    -- 过滤处理列表：获取所有非skin的max文件
    local processFiles = #()
    for i=0 to (Lv_model.Items.Count-1) do (
        local item = Lv_model.Items.Item[i]
        local rawPath = item.Tag as String
        
        -- 跳过所有目录项
        local isDirectory = matchPattern rawPath pattern:"*[DIR]*" or (getFilenameType rawPath) == ""
        if isDirectory do continue
        
        -- 标准化路径处理
        local filePath = pathConfig.normalizePath rawPath
        
        -- 有效性验证
        if not doesFileExist filePath or (toLower (getFilenameType filePath)) != ".max" do continue
        
        -- 过滤SKIN相关文件（不区分大小写）
        local fileNameCheck = toLower (getFilenameFile filePath)
        local isSkinFile = findString fileNameCheck "skin" != undefined
        
        -- 排除skin文件
        if not isSkinFile do (
            append processFiles filePath
            format "[通过过滤] 有效文件：%\n" filePath
        )
    )
    
    -- 如果当前打开的文件不在列表中，且不是skin文件，则添加到处理列表
    if currentSkinFile != undefined and currentSkinFile != "" and doesFileExist currentSkinFile then (
        local currentFileNameCheck = toLower (getFilenameFile currentSkinFile)
        local isCurrentSkinFile = findString currentFileNameCheck "skin" != undefined
        
        if not isCurrentSkinFile do (
            -- 检查当前打开的文件是否已经在处理列表中
            local found = false
            for f in processFiles do (
                if (pathConfig.normalizePath f) == (pathConfig.normalizePath currentSkinFile) do (
                    found = true
                    exit
                )
            )
            if not found do (
                append processFiles currentSkinFile
                format "[添加当前文件] 有效文件：%\n" currentSkinFile
            )
        )
    )
    
    if processFiles.count == 0 do (
        messageBox "有效文件列表为空！" title:"操作中止"
        return false
    )
    
    -- 设置进度条最大值
    pbProgress.maximum = processFiles.count
    
    local successCount = 0
    local reportData = generateReplacementReport processFiles outputDir
    
    for i=1 to processFiles.count where not g_exportAbortFlag do (
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            lblProgressInfo.text = "用户中断操作！"
            exit
        )

        local oldFile = processFiles[i]
        local oldFileName = getFilenameFile oldFile
        if classOf oldFileName != String do (
            format "[错误] 无效文件名类型：%\n" (classOf oldFileName)
            continue
        )
        lblProgressInfo.text = "处理中：" + oldFileName + " (" + (i as string) + "/" + (processFiles.count as string) + ")"
        
        -- 导出旧文件数据
        if loadMaxFile oldFile quiet:true do (
            -- 导出BIP到统一目录
            local bipRoots = for obj in objects where classOf obj == Biped_Object collect obj
            if bipRoots.count > 0 do (
                local bipPath = bipDir + "\\" + oldFileName + ".bip"
                format "[导出BIP] 路径：%\n" bipPath
                try (
                    biped.saveBipFile bipRoots[1].controller bipPath
                    format "[BIP导出成功] %\n" bipPath
                ) catch (
                    format "[BIP导出失败] %\n" bipPath
                )
            )
            
            -- 导出附件骨骼到统一目录（使用稳定的XAF导出函数）
            try (
                exportAttachmentBones oldFile boneDir  -- 直接导出到boneDir
            ) catch (
                format "[XAF导出失败] %\n" oldFile
            )
            
            resetMaxFile #noPrompt
        )
        
        -- 导入到新皮肤文件（当前打开的场景）
        if loadMaxFile currentSkinFile quiet:true do (
            -- 导入BIP数据
            local targetBip = findRootBones()
            if targetBip.count > 0 do (
                local bipPath = bipDir + "\\" + oldFileName + ".bip"
                if doesFileExist bipPath do (
                    format "[导入BIP] 路径：%\n" bipPath
                    try (
                        biped.loadBipFile targetBip[1].controller bipPath
                        format "[BIP导入成功] %\n" bipPath
                    ) catch (
                        format "[BIP导入失败] %\n" bipPath
                    )
                )
            )
            
            -- 导入附件骨骼（使用稳定的XAF导入函数）
            -- 直接在SkinReplace_Xaf目录中查找XAF文件
            local xafPath = boneDir + "\\" + oldFileName + ".xaf"
            
            if doesFileExist xafPath do (
                try (
                    importXafAnimation xafPath
                    format "[XAF导入成功] %\n" xafPath
                ) catch (
                    format "[XAF导入失败] %\n" xafPath
                )
            )
            
            -- 保存新文件到主目录（使用原文件名，不加前缀）
            local newFileName = oldFileName + "_Replaced.max"
            local newFilePath = outputDir + "\\" + newFileName
            
            -- 检查文件是否已存在，如果存在则添加序号
            local counter = 1
            while doesFileExist newFilePath do (
                newFileName = oldFileName + "_Replaced_" + (counter as string) + ".max"
                newFilePath = outputDir + "\\" + newFileName
                counter += 1
            )
            
            format "[保存文件] 路径：%\n" newFilePath
            try (
                saveMaxFile newFilePath
                successCount += 1
            ) catch (
                format "[文件保存失败] %\n" newFilePath
            )
        )
        
        -- 进度更新
        pbProgress.value = i
        lblProgressInfo.text = "进度：" + ((100.0*i/processFiles.count) as integer) as string + "% | 成功：" + (successCount as string)
        windows.processPostedMessages()
        gc()
    )
    
    -- 保存报告文件
    if classOf reportData == StringStream do (
        try (
            local reportPath = outputDir + "\\Replacement_Report.txt"
            local reportFile = createFile reportPath
            format "%" (reportData as string) to:reportFile
            close reportFile
            format "[报告保存成功] 路径：%\n" reportPath
        )
        catch (
            format "[报告保存失败] 错误：%\n" (getCurrentException())
        )
    )
    
    -- 刷新文件列表
    AutoExportTool_Pro.refreshFileListView()
    
    -- 完成处理
    lblProgressInfo.text = "一键换皮完成！成功处理 " + (successCount as string) + " 个文件"
    if chk_autoOpenDir.checked do ShellLaunch "explorer.exe" outputDir
    
    -- 显示统计信息
    messageBox ("操作完成！\n成功文件: " + (successCount as string) + " 个\n失败文件: " + ((processFiles.count - successCount) as string) + " 个") title:"一键换皮报告"
    -- 不再需要organizeXafFiles，因为XAF文件已经直接保存在SkinReplace_Xaf文件夹
)

-- UI 持久化 / 安全颜色加载函数 
fn loadColorSettings section defaultColor = (
    local col = copy defaultColor
    try (
        col.r = execute (getINISetting g_UIConfigPath section "R")
        col.g = execute (getINISetting g_UIConfigPath section "G")
        col.b = execute (getINISetting g_UIConfigPath section "B")
    ) catch (
        format "[颜色加载错误] 使用默认值：%\n" defaultColor
    )
    col
)

-- UI 持久化 / 安全保存所有UI状态 / 记录 事件按钮勾选状态 
fn saveUIConfig = (
    try (
        -- 保存勾选状态 chkXAFOverwrite
        --setINISetting g_UIConfigPath "Checkboxes" "chkExportToEngine" (chkExportToEngine.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "chkXAFOverwrite" (chkXAFOverwrite.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "chkAddDateSuffix" (chkAddDateSuffix.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "chkAutoFolder" (chkAutoFolder.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "chkChangeFont" (chkChangeFont.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "chkGridLines" (chkGridLines.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "auto_socket" (auto_socket.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "auto_makedir_set" (auto_makedir_set.checked as string)
        setINISetting g_UIConfigPath "Checkboxes" "chk_autoOpenDir" (chk_autoOpenDir.checked as string)
        
        -- 保存颜色分量
        setINISetting g_UIConfigPath "FolderColor" "R" (cpFolder.color.r as string)
        setINISetting g_UIConfigPath "FolderColor" "G" (cpFolder.color.g as string)
        setINISetting g_UIConfigPath "FolderColor" "B" (cpFolder.color.b as string)
        
        setINISetting g_UIConfigPath "FileColor" "R" (cpFile.color.r as string)
        setINISetting g_UIConfigPath "FileColor" "G" (cpFile.color.g as string)
        setINISetting g_UIConfigPath "FileColor" "B" (cpFile.color.b as string)

        -- 保存滑块值（增加范围验证）
        local currentValue = sldBgColor.value
        local bgValue = amax 0 (amin 255 sldBgColor.value)
        setINISetting g_UIConfigPath "Settings" "BgGrayValue" (bgValue as string)
        
        format "[SaveUIConfig] Saved BgValue: %\n" currentValue
    )
    catch (
        format "[SaveUIConfig Error] %\n" (getCurrentException())
    )
)

-- UI 持久化 /辅助函数：安全转换INI值为整数
fn getSafeInteger iniSection iniKey defaultVal = (
    try (
        local valStr = getINISetting g_UIConfigPath iniSection iniKey
        if valStr == "" do return defaultVal
        valInt = valStr as integer
        if classOf valInt != Integer do return defaultVal
        return valInt
    ) catch (return defaultVal)
)
-- UI 持久化 /安全数值转换辅助函数
fn executeSafe str defaultValue = (
    try (execute str) catch (
        try (str as integer) catch defaultValue
    )
)

-- UI 持久化 /智能初始化-..加载-..列表背景灰度值（颜色）/UI/初始化配置
fn setBackgroundColor val = (
    lblBgValue.text = val as string
    Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb val val val
    setINISetting g_UIConfigPath "Settings" "BgGrayValue" (val as string)
)

-- UI 持久化 /智能加载UI配置
fn loadUIConfig = (
    try (
        
        -- 加载勾选状态（带默认值）
        --chkExportToEngine.checked = getINISetting g_UIConfigPath "Checkboxes" "chkExportToEngine" == "true"
        chkXAFOverwrite.checked = getINISetting g_UIConfigPath "Checkboxes" "chkXAFOverwrite" == "true"
        chkAddDateSuffix.checked = getINISetting g_UIConfigPath "Checkboxes" "chkAddDateSuffix" == "true"
        chkAutoFolder.checked = getINISetting g_UIConfigPath "Checkboxes" "chkAutoFolder" == "true"
        chkChangeFont.checked = getINISetting g_UIConfigPath "Checkboxes" "chkChangeFont" == "true"
        chkGridLines.checked = getINISetting g_UIConfigPath "Checkboxes" "chkGridLines" == "true"
        auto_socket.checked = getINISetting g_UIConfigPath "Checkboxes" "auto_socket" == "true"
        auto_makedir_set.checked = getINISetting g_UIConfigPath "Checkboxes" "auto_makedir_set" == "true"
        chk_autoOpenDir.checked = getINISetting g_UIConfigPath "Checkboxes" "chk_autoOpenDir" == "true"
        
        -- 加载颜色
        cpFolder.color = loadColorSettings "FolderColor" (color 245 245 125)
        cpFile.color = loadColorSettings "FileColor" (color 255 255 255)
        
        -- 加载滑块值（带错误处理和范围限制）
        local bgValue = executeSafe (getINISetting g_UIConfigPath "Settings" "BgGrayValue") g_defaultBgValue
        bgValue = amax 0 (amin 255 bgValue)  -- 强制限制在0-255
        
        -- 更新UI组件
        sldBgColor.value = bgValue
        lblBgValue.text = bgValue as string
        
        -- 直接设置背景色
        Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb bgValue bgValue bgValue
        
        format "[LoadUIConfig] BgValue: %\n" bgValue
        ) catch (
        format "[LoadUIConfig Error] %\n" (getCurrentException())
        
        -- 恢复安全默认值
        sldBgColor.value = g_defaultBgValue
        lblBgValue.text = g_defaultBgValue as string
        Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb g_defaultBgValue g_defaultBgValue g_defaultBgValue
        )
)

-- 在工具初始化时增加路径健康检查
fn checkPathHealth path = (
    local retry = 3
    while retry > 0 do (
        if doesDirectoryExist path do return true
        dotNet.invokeMethod (dotNetClass "System.Threading.Thread") "Sleep" 1000
        retry -= 1
    )
    false
)

-- 4. 新增辅助函数
fn getDisplayName fullPath baseDepth = (
    local pathParts = filterString fullPath "\\"
    local depth = pathParts.count - baseDepth
    (substring fullPath (currentPath.count + 2) -1) -- 显示相对路径
)

-- 强化文件获取逻辑 
fn getProcessFiles = (
    local files = #()
    for i = 0 to (Lv_model.Items.Count - 1) where Lv_model.Items.Item[i].Checked do (
        local fPath = Lv_model.Items.Item[i].Tag as String
        if doesFileExist fPath and (getFilenameType fPath) == ".max" do append files fPath
    )
    if files.count == 0 do files = for f in model_files_array where (getFilenameType f) == ".max" and (doesFileExist f) collect f
)

-- BIP模式配置 / 唯一文件名生成器
fn uniqueBipName baseName saveDir = (
    local counter = 1
    while true do (
        local testName = baseName + "_" + (formattedPrint counter format:"03d")
        local targetPath = pathConfig.appendPath saveDir (testName + ".max")
        if not doesFileExist targetPath do return testName
        counter += 1
    )
)

-- BIP模式配置 / 修正的导出BIP逻辑（调用原生保存对话框）
fn exportBipFile = (
    try (
        local bipRoot = getNodeByName "Bip001" exact:true
        if not isValidNode bipRoot do throw "未找到有效的Biped根骨骼"
        
        -- 触发原生保存对话框
        biped.saveBipFile bipRoot.controller
        
        -- 捕获保存对话框
        local mainHWND = windows.getMAXHWND()
        local counter = 0
        local saveDlg = undefined
        while (saveDlg == undefined and counter < 20) do (
            sleep 0.1
            saveDlg = UIAccessor.FindWindow "Save Biped Animation File" ""
            counter += 1
        )
        
        -- 自动设置默认文件名
        if saveDlg != undefined do (
            UIAccessor.SetWindowText (UIAccessor.GetWindowChildByID saveDlg 0x480) "exported_anim.bip"
            UIAccessor.PressButtonByID saveDlg 0x1 -- 确认保存
        )
    )
    catch (
        messageBox ("导出失败:\n" + getCurrentException()) title:"致命错误"
    )
)

-- BIP模式配置 / 独立BIP导出进程
fn processBipExport fPath = (
    try (
        if not (loadMaxFile fPath quiet:true) do return false
        
        -- 获取导出类型
        local exportType = case rdo_bipMode.state of (
            1: #bip
            2: #bone
            default: #none
        )
        
        -- 类型验证
        case exportType of (
            #bip: (
                local bipRoots = for obj in objects where classOf obj == Biped_Object collect obj
                if bipRoots.count == 0 do return false
                outDir = pathConfig.appendPath edtExportPath.text "BIP_Exports"
            )
            #bone: (
                local boneNodes = for obj in objects where 
                    (matchPattern obj.name pattern:"*Bone*") or 
                    (classOf obj == Dummy) collect obj
                if boneNodes.count == 0 do return false
                outDir = pathConfig.appendPath edtExportPath.text "Bone_Exports"
            )
        )
        
        -- 创建输出目录
        makeDir outDir all:true
        
        -- 导出逻辑
        case exportType of (
            #bip: (
                outPath = pathConfig.appendPath outDir (getFilenameFile fPath + ".bip")
                biped.saveBipFile bipRoots[1].controller outPath
            )
            #bone: (
                outPath = pathConfig.appendPath outDir (getFilenameFile fPath + ".xaf")
                exportFile outPath #noPrompt selectedOnly:true using:XAFFormat
            )
        )
        
        format "[成功导出] %\n" outPath
        true
    )
    catch (
        format "[导出失败] % : %\n" fPath (getCurrentException())
        false
    )
)

fn validateExportSettings = (
    -- 检查至少勾选一个导出类型
    if not chkExportBip.checked and not chkExportBones.checked do (
        messageBox "未勾选任何导出类型！" title:"导出配置错误"
        return false
    )
    
    -- 检查模式与勾选框的兼容性
    if rdo_bipMode.state == 1 and not chkExportBip.checked do (
        messageBox "BIP导出模式需要勾选BIP导出项！" title:"模式不匹配"
        return false
    )
    
    true
)

-- 强化文件获取逻辑
fn getBipProcessFiles mode enableCheck = (
    local processFiles = #()
    for i=0 to (Lv_model.Items.Count-1) do (
        local fPath = Lv_model.Items.Item[i].Tag as String
        local isChecked = Lv_model.Items.Item[i].Checked
        local isValid = case mode of (
            1: (getFilenameType fPath == ".max" and doesFileExist fPath)  -- 导出模式检查MAX文件
            2: (getFilenameType fPath == ".bip" and isValidBipFile fPath) -- 导入模式检查BIP文件
        )
        
        case enableCheck of (
            true:  (if isChecked and isValid do append processFiles fPath)
            false: (if isValid do append processFiles fPath)
        )
    )
    processFiles
)

----------------------------------------------------------------

-- 更新进度显示 / 优化进度反馈机制
fn updateProgressInfo current total success = (
    local progressPercent = (100.0 * current / total) as integer
    lblProgressInfo.text = "进度：" + (progressPercent as string) + "% | 成功：" + (success as string)
    pbProgress.value = current
    windows.processPostedMessages()
)

-- 批量BIP导出导入 / 统一处理入口函数（处理勾选或全部文件）
fn processBipFiles mode enableCheck = (
    g_exportAbortFlag = false
    pbProgress.value = 0
    lblProgressInfo.text = "准备开始..."
    
    -- 获取需要处理的文件列表
    local processFiles = getBipProcessFiles mode enableCheck
    if processFiles.count == 0 do (
        messageBox (if enableCheck then "未勾选有效文件！" else "列表中没有有效文件！") title:"操作中止" beep:true
        return false
    )
    
    --pbProgress.maximum = processFiles.count
    local successCount = 0
    
    for i=1 to processFiles.count where not g_exportAbortFlag do (
        -- ESC键中断检测
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            lblProgressInfo.text = "操作已中断！"
            windows.processPostedMessages()
            messageBox "BIP导入进程已被用户中断！" title:"提示" beep:true
            exit
        )
        
        local fPath = processFiles[i]
        lblProgressInfo.text = "处理中：" + filenameFromPath fPath + " (" + (i as string) + "/" + processFiles.count as string + ")"+
        ((100.0*i/processFiles.count) as integer) as string + "% | 成功：" + successCount as string
        
        try (
            case mode of (
                
                1: (if (processBipExport fPath) do successCount += 1)  -- 导出模式
                2: (if (processBipImport fPath) do successCount += 1)  -- 导入模式
            )
        ) catch (
            format "[处理错误] 文件：%\n错误：%\n" fPath (getCurrentException())
        )
        
        -- 更新进度
        pbProgress.value = i
        lblProgressInfo.text = "进度：" + ((100.0*i/processFiles.count) as integer) as string + "% | 成功：" + successCount as string
        
        windows.processPostedMessages()
        
        -- 内存优化
        if mod i 5 == 0 do (gc(); freeSceneBitmaps())
    )
    
    -- 刷新文件列表
    AutoExportTool_Pro.refreshFileListView()
    
    -- 完成处理
    lblProgressInfo.text = case mode of (
        1: ("批量BIP导出列表全部max文件完成！成功：" + successCount as string + "/" + processFiles.count as string)
        2: ("批量BIP导入列表全部bip文件完成！成功：" + successCount as string + "/" + processFiles.count as string)
    )
    
    -- 自动打开目录
    if chk_autoOpenDir.checked and successCount > 0 do (
        ShellLaunch "explorer.exe" (
            case mode of (
                1: (pathConfig.appendPath edtExportPath.text "BIP_Exports")
                2: (pathConfig.appendPath edtExportPath.text "MAX_Imports")
            )
        )
    )
    true
)

----------------------------------------------------------------

-- 核心处理函数 ======================================================
-- 主处理函数（严格区分模式）
-- 安全访问Biped根节点的函数
-- 强化 Biped 根节点检测（兼容 CS 骨骼和版本差异）
fn GetWorkingBipRoot = 
(
    try
    (
        -- 优先从面板获取（兼容旧版工具）
        if isProperty rolBsBipedTools #m_workingBipRoot and 
           rolBsBipedTools.m_workingBipRoot != undefined and 
           not isDeleted rolBsBipedTools.m_workingBipRoot then
        (
            return rolBsBipedTools.m_workingBipRoot
        )
    )
    catch()
    
    -- 强化版骨骼检测（兼容2019-2024）
    local bipRoots = for obj in objects where (classOf obj == Biped_Object) collect obj
    
    if bipRoots.count > 0 then
    (
        -- 版本分支处理
        if (maxVersion())[1] >= 23000 then  -- 2022+ 的CS骨骼需要特殊处理
            return bipRoots[1].controller.rootNode
        else                                -- 2019及更早版本直接返回找到的Biped根节点
            return bipRoots[1]
    )
    
    -- 旧版本备用检测（通过选择获取）
    if selection.count > 0 and classOf selection[1].baseObject == Biped_Object then
    (
        try(return biped.getRootNode selection[1])catch(return undefined)
    )
    
    undefined
)

-- 强化版根节点验证（统一提示信息）
fn BsBipedCheckRoot = 
(
    local rootNode = GetWorkingBipRoot()
    
    if rootNode == undefined do 
    (
        messageBox "未找到有效骨骼！\n请确认场景中存在 Biped/CS 系统" title:"BipedTools"
        return false
    )
    
    if isDeleted rootNode do 
    (
        messageBox "骨骼根节点已被删除！\n请重新打开文件或创建新骨骼" title:"BipedTools"
        return false
    )
    
    true
)

-- 新增辅助函数 ---------------------------------------------------------
--文件保存逻辑
fn GenerateTargetPath bipPath outputDir = (
    local bipName = getFilenameFile bipPath
    local maxName = bipName + ".max"
    pathConfig.appendPath outputDir maxName
)

fn uniqueFileNameFromTemplate basePath = (
        local counter = 1
        local dir = getFilenamePath basePath
        local fileName = getFilenameFile basePath
        local ext = getFilenameType basePath
        
        while true do (
            local testName = dir + fileName + "_" + (formattedPrint counter format:"03d") + ext
            if not doesFileExist testName do return testName
            counter += 1
        )
    )

fn uniqueFileName baseDir baseName ext = (
    local counter = 1
    while true do (
        local testName = baseDir + "\\" + baseName + "_" + (formattedPrint counter format:"03d") + ext
        if not doesFileExist testName do return testName
        counter += 1
    )
)

-- 独立BIP导入函数（无对话框版本）
fn SilentBipedImport bipPath = (
    if not BsBipedCheckRoot() do return false
    
    undo "导入BIP动画" on (
        try (
            root = GetWorkingBipRoot()
            biped.loadBipFile root.controller bipPath
            true
        ) catch (
            format "[错误] 导入失败：%\n" (getCurrentException())
            false
        )
    )
    
)
-- 兼容版BIP导入函数
fn BsBipedImport = 
(
    if not BsBipedCheckRoot() do return false
    
    local rootNode = GetWorkingBipRoot()
    local bipPath = getOpenFileName \
        caption:"BipedTools - 导入BIP动画" \
        filename:(getDir #animations + "\\") \
        types:"Biped动画文件(*.bip)|*.bip|"
    
    if bipPath != undefined do 
    (
        undo "导入BIP动画" on 
        (
            biped.loadBipFile rootNode.controller bipPath
            messageBox ("BIP动画已成功加载:\n" + bipPath) title:"BipedTools" beep:false
        )
    )
)

-- 兼容版BIP导出函数
fn BsBipedExport = 
(
    if not BsBipedCheckRoot() do return false
    
    local rootNode = GetWorkingBipRoot()
    local defaultName = (getFilenameFile maxFileName) + "_Animation.bip"
    local bipPath = getSaveFileName \
        caption:"BipedTools - 导出BIP动画" \
        filename:(getDir #animations + "\\" + defaultName) \
        types:"Biped动画文件(*.bip)|*.bip|"
    
    if bipPath != undefined do 
    (
        biped.saveBipFile rootNode.controller bipPath
        messageBox ("BIP动画已成功保存:\n" + bipPath) title:"BipedTools" beep:false
    )
)

--批量选择集/保存选择集-批量处理应用到文件-保存新文件
-- 新增函数：保存当前选择集到XML
-- 修改后的 batchProcessSelSets 函数
fn batchProcessSelSets = (
    -- 获取处理文件列表
    local processFiles = getProcessFiles()
    if processFiles.count == 0 do (
        messageBox "没有找到有效的MAX文件！" title:"操作中止"
        return undefined
    )

    -- 保存选择集到临时文件
    local tempXml = getDir #temp + "\\CurrentSelSets.xml"
    if selectionSets.count == 0 do (
        messageBox "当前场景没有选择集！" title:"操作中止"
        return undefined
    )

    -- 保存选择集到临时文件（保持原有逻辑）
    local xmlDoc = dotNetObject "System.Xml.XmlDocument"
    local root = xmlDoc.CreateElement "SelectionSets"
    xmlDoc.AppendChild root
    
    for s in selectionSets do (
        local setElem = xmlDoc.CreateElement "Set"
        setElem.SetAttribute "Name" s.name
        for obj in s do (
            local objElem = xmlDoc.CreateElement "Object"
            objElem.InnerText = obj.name
            setElem.AppendChild objElem
        )
        root.AppendChild setElem
    )
    xmlDoc.Save tempXml

    -- 存储配置对话框
    local res = queryBox "是否创建新文件夹保存修改后的文件？\n(选择'否'将覆盖原始文件)" title:"保存选项"
    local targetFolder = if res then (
        pathConfig.appendPath (getFilenamePath processFiles[1]) "SelsetNew_MAX"
    ) else ""
    if res do makeDir targetFolder all:true

    -- 进度控制
    pbProgress.value = 0
    pbProgress.maximum = processFiles.count
    lblProgressInfo.text = "准备开始..."
    local successCount = 0

    -- 主处理循环（确保路径安全）
    for i=1 to processFiles.count where not g_exportAbortFlag do (
        local srcPath = processFiles[i]
        local baseName = getFilenameFile srcPath
        local targetPath = if res then
            pathConfig.appendPath targetFolder (baseName + ".max")
        else
            srcPath

        -- 加载前强制释放内存
        freeSceneBitmaps()
        gc()

        if loadMaxFile srcPath quiet:true then (
            disableSceneRedraw()
            xmlDoc.Load tempXml
            -- 修正后的选择集清理
            for i = (getNumNamedSelSets()) to 1 by -1 do (
                deleteNamedSelSet (getNamedSelSetName i)
            )

            -- 重建选择集
            local sets = xmlDoc.SelectNodes "//Set"
            for s=0 to sets.Count-1 do (
                local setName = sets.Item[s].GetAttribute "Name"
                local objs = #()
                for o=0 to sets.Item[s].ChildNodes.Count-1 do (
                    local objName = sets.Item[s].ChildNodes.Item[o].InnerText
                    local obj = getNodeByName objName
                    if obj != undefined do append objs obj
                )
                if objs.count > 0 do selectionSets[setName] = objs
            )

            -- 保存文件
            saveMaxFile targetPath
            successCount += 1

            resetMaxFile #noPrompt
            enableSceneRedraw()
            completeRedraw()
        )

        pbProgress.value = i
        windows.processPostedMessages()
    )

    -- 在关键循环后增加资源释放
    gc light:true
    freeSceneBitmaps()

    -- 完成处理
    lblProgressInfo.text = "完成！成功处理 " + successCount as string + " 个文件"
    if res do ShellLaunch "explorer.exe" targetFolder
)

-- 确保按钮事件绑定正确版本函数 --  false 
--on btn_selsetBatch pressed do (
    --try(
        --batchProcessSelSets() -- 确保调用的是全局函数版本
    --)catch(
        --format "[ERROR] 批处理失败：%\n" (getCurrentException())
        -- 强制恢复场景
        --resetMaxFile #noPrompt
        --enableSceneRedraw()
        --completeRedraw()
    --)
--)
----------------------------------------------------------------
----------------------------------------------------------------

-- lv-列表/初始化函数设置默认字体，滑条隐藏，// 注意！！！初始lv列表---修改默认列表参数在这里修改，动态刷新需要改变列表参数//则在start_Lv_model 里修改

-- 修改列宽调整函数为可重用模式
fn adjustColumnWidths forceCustom:undefined = (
    if not isKindOf Lv_model dotNetControl do return false
    if classOf Lv_model != dotNetControl do return false
    if Lv_model.Columns.count < 3 do return false
    if forceCustom == undefined do forceCustom = chkChangeFont.checked
    --local scrollbarWidth = 17 -- 垂直滚动条预估宽度 / false 
    --local availableWidth = Lv_model.ClientRectangle.Width - scrollbarWidth / false
    
    try (
        
        Lv_model.SuspendLayout()
        -- 强制应用列宽避免闪烁
        Lv_model.Columns.Item[2].Width = if forceCustom then 145 else 125
        Lv_model.ResumeLayout()
        local actualWidth = Lv_model.ClientRectangle.Width
        
        -- 动态列宽计算
        case forceCustom of (
            true: ( -- 自定义布局
            -- 计算CK列宽（第一列）
        local ckMin = actualWidth * 0.1
        local ckWidth = if ckMin < COLUMN_CK_WIDTH then ckMin else COLUMN_CK_WIDTH
        ckWidth = if ckWidth < 20 then 20 else ckWidth
        Lv_model.Columns.Item[0].Width = ckWidth  -- 修正为[]和=
        
        -- 计算类型列宽（第三列）
        local typeMin = actualWidth * 0.15
        local typeWidth = if typeMin < COLUMN_TYPE_WIDTH then typeMin else COLUMN_TYPE_WIDTH
        typeWidth = if typeWidth < 20 then 20 else typeWidth
        Lv_model.Columns.Item[2].Width = typeWidth  -- 修正为[]和=
        
        -- 计算文件列宽（第二列）
        local remainingWidth = actualWidth - ckWidth - typeWidth - 5
        Lv_model.Columns.Item[1].Width = if remainingWidth > 50 then remainingWidth else 50  -- 修正为=
                local fileWidth = actualWidth - ckWidth - typeWidth - 5
            )
            false: ( -- 默认布局
                ckWidth = COLUMN_CK_WIDTH
                typeWidth = COLUMN_TYPE_WIDTH
                fileWidth = COLUMN_FILE_WIDTH
				--fileWidth = LISTVIEW_WIDTH - ckWidth - typeWidth - 20
            )
        )
        
        -- 应用列宽
        Lv_model.Columns.Item[0].Width = ckWidth
        Lv_model.Columns.Item[1].Width = fileWidth
        Lv_model.Columns.Item[2].Width = typeWidth
            -- 强制禁用水平滚动
        Lv_model.Scrollable = false
        Lv_model.Scrollable = true -- 仅垂直滚动
        Lv_model.ResumeLayout()
        true
    )
    catch (
        format "[ERROR] 列宽调整失败: %\n" (getCurrentException())
        false
    )
)

--默认 通用ListView / ​列定义与配置 / ​​初始化 ListView（列表视图）数据模型​​ 的函数，主要处理 ​​数据加载、格式转换​​ 和 ​​UI 绑定
fn initLvModel = (
    Lv_model.View = (dotNetClass "System.Windows.Forms.View").Details
    Lv_model.LabelEdit = true  -- 启用原地编辑功能
    Lv_model.CheckBoxes = true
    Lv_model.MultiSelect = true
    
    Lv_model.View = (dotNetClass "System.Windows.Forms.View").Details
    Lv_model.Font = g_defaultFont  -- 初始化默认字体-01      --- fr 按钮 执行实现 字体切换（chkChangeFont changed state do...勾选框事件处理）
    g_alternateFont = dotNetObject "System.Drawing.Font" "微软雅黑" 8 ((dotNetClass "System.Drawing.FontStyle").Regular)   --fr切换动态字体-02
    Lv_model.GridLines = false     --隐藏网格线
    Lv_model.Scrollable = false     --下滑条隐藏

    --g_alternateFont = dotNetObject "System.Drawing.Font" "Segoe UI" 9 ((dotNetClass "System.Drawing.FontStyle").Regular)
    -- ...其他初始化代码...
)
--新增lv列表无缝衔接拼装 / 自定义单行listview
fn initlvHeader = (
    lvHeader.View = (dotNetClass "System.Windows.Forms.View").Details
    lvHeader.HeaderStyle = (dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None      --隐藏列头
    lvHeader.FullRowSelect = true
    lvHeader.MultiSelect = false
    lvHeader.GridLines = false
    lvHeader.Scrollable = false
    -- 动态列宽基于复选框状态
    local typeWidth = if chkChangeFont.checked then 145 else 125
    -- 调整列布局：CK/Icon |  文件  | 类型
    lvHeader.Columns.Clear()
    lvHeader.Columns.Add "模式" 150
    lvHeader.Columns.Add "文件" 170  
    lvHeader.Columns.Add "类型" typeWidth  -- 动态宽度
    lvHeader.Columns.Item[0].TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Left
    lvHeader.Columns.Item[1].TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Center  -- 居中
    lvHeader.Columns.Item[2].TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Right
    
    -- 视觉样式
    lvHeader.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 70 70 70
    lvHeader.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 0 255 255 -- 255 105 180 糖粉 / 248 248 255  珍白/0 150 255  赛博蓝
    lvHeader.Font = dotNetObject "System.Drawing.Font" "微软雅黑" 9 ((dotNetClass "System.Drawing.FontStyle").Bold)
    
    -- 初始化数据
    try (
    li = dotNetObject "System.Windows.Forms.ListViewItem" "CK/Ico"
    li.SubItems.Add("⏬📁文件夹/文件📄")  
    li.SubItems.Add(" 类型/Typ")
    lvHeader.Items.Add li
) catch (
    format "初始化错误：%\n" (getCurrentException())
)
    -- 禁用交互
    --lvHeader.Enabled = false              --     有效 但 底色 显示错误 / false 
    --lvHeader.HideSelection = true
)

-- lv-列表/统一的状态更新函数/自定义状态栏/单行listview
fn initModeStatus = (
    ModeStatus.View = (dotNetClass "System.Windows.Forms.View").Details
    ModeStatus.HeaderStyle = (dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None    --隐藏列头
    ModeStatus.FullRowSelect = true
    ModeStatus.MultiSelect = false
    ModeStatus.GridLines = false
    ModeStatus.Scrollable = false
    
    -- 调整列布局：模式状态 | 当前路径 | 文件计数
    ModeStatus.Columns.Clear()
    ModeStatus.Columns.Add "模式" 180
    ModeStatus.Columns.Add "当前路径" 120  -- 新增路径列
    ModeStatus.Columns.Add "计数" 135
    ModeStatus.Columns.Item[0].TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Left
    ModeStatus.Columns.Item[1].TextAlign = (dotNetClass "HorizontalAlignment").Center  -- 居中
	ModeStatus.Columns.Item[2].TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Right
    -- 视觉样式
    ModeStatus.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 70 70 70
    ModeStatus.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 0 255 0 -- 255 105 180 糖粉 / 248 248 255  珍白/0 150 255  赛博蓝
    ModeStatus.Font = dotNetObject "System.Drawing.Font" "微软雅黑" 9 ((dotNetClass "System.Drawing.FontStyle").Bold)
    
    -- 强制创建初始项（带异常处理）
    try (
        if ModeStatus.Items.Count == 0 do (
            local li = dotNetObject "System.Windows.Forms.ListViewItem" "FBX模式-Auto | Action:待命"
            li.SubItems.Add("")
            li.SubItems.Add("文件：0")
            ModeStatus.Items.Add li
        )
    ) catch (
        format "[初始项创建错误] %" (getCurrentException())
    )
)

-- 增强状态更新函数/lv-列表/稳定状态栏显示函数
fn updateModeStatus = (
    try (
        if not (isKindOf ModeStatus dotNetControl) do return false
        if ModeStatus.IsDisposed do return false
        
        -- 构建核心状态文本
        local fbxMode = #("Auto","Skin","Bake")[rdo_exportMode.state]
        local actionText = " | Act:" + g_lastAction
        
        -- 强制创建状态项（防崩溃）
        if ModeStatus.Items.Count == 0 do (
            local li = dotNetObject "System.Windows.Forms.ListViewItem" ""
            li.SubItems.Add("")
            li.SubItems.Add("")
            ModeStatus.Items.Add li
        )
        
        -- 更新第一列（动态按钮状态）
        local item = ModeStatus.Items.Item[0]
        item.Text = "FBX:" + fbxMode + actionText
        
        -- 保持原有路径信息显示
        local validPath = doesDirectoryExist edtExportPath.text
        item.SubItems.Item[1].Text = if validPath then filenameFromPath edtExportPath.text else "最近文件"
        
        -- 保持文件计数逻辑
        local dirCount = if validPath then (getDirectories (edtExportPath.text + "\\*")).count else 0
        item.SubItems.Item[2].Text = "文件：" + (amax 0 (model_files_array.count - dirCount)) as string
        
        ModeStatus.Refresh()
        true
    )
    catch (
        format "[状态更新失败] %\n" (getCurrentException())
        false
    )
)

-- 辅助函数：验证.NET对象
fn isvalidobj obj = (
    try (
        return not (
            obj == undefined or 
            obj.IsDisposed or 
            obj.Equals(undefined) or 
            not (dotNet.isNetObject obj)
        ) -- 补全缺失的闭合括号
    ) catch (
        return false
    )
)

-- 状态更新示例
--fn updateStatus text = (
    --ModeStatus.Items.Item[0].Text = text
    --ModeStatus.Refresh()
--)
----------------------------------------------------------------
----------------------------------------------------------------
-- 全局函数：强制清空最近文件记录
fn clearRecentFilesCompletely = (
    local xmlPath = (getDir #maxData) + "\\RecentDocuments.xml"
    try (
        -- 创建空的XML结构覆盖原文件
        local xDoc = dotNetObject "System.Xml.XmlDocument"
        local root = xDoc.CreateElement("RecentDocuments")
        xDoc.AppendChild(root)
        xDoc.Save(xmlPath)
        
        -- 重置内存记录
        g_recentFiles = #()
        true
    ) catch (
        format "[清空错误] %\n" (getCurrentException())
        false
    )
)

-- 全局函数：立即修改最近文件显示数量
fn setMaxRecentFileCountImmediately count = (
    -- 1. 修改INI文件（核心设置）
    local iniFile = (getDir #maxData) + "\\3dsmax.ini"
    setINISetting iniFile "General" "FileMRUListCount" (count as string)
    
    -- 2. 使用正确的注册表设置方法
    local success = false
    try (
        -- 分解注册表路径
        local rootKey = "HKEY_CURRENT_USER"
        local subPath = "Software\\Autodesk\\3dsMax\\" + (maxVersion() as string) + "\\Preference"
        local valueName = "FileMRUListCount"
        
        -- 使用正确的4参数格式
        setINISetting rootKey subPath valueName (count as string)
        success = true
        format "[注册表设置成功] %\\%\\% = %\n" rootKey subPath valueName count
    ) catch (
        format "[注册表错误] %\n" (getCurrentException())
    )
    
    -- 3. 刷新Max界面
    try (
        actionMan.executeAction 0 "55230"  -- 2022+刷新UI命令
        actionMan.executeAction 0 "40021"  -- 通用刷新命令
    ) catch ()
    
    success
)

-- 从RecentDocuments.xml加载最近文件 / 稳定核心功能实现 /  true /（兼容所有Max版本）
fn loadRecentFilesFromXML = (
    g_recentFiles = #()
    local xmlPath = pathConfig.normalizePath ((getDir #maxData) + "\\RecentDocuments.xml")
    
    if doesFileExist xmlPath do (
        try (
            local xDoc = dotNetObject "System.Xml.XmlDocument"
            xDoc.Load xmlPath
            local entries = xDoc.SelectNodes "//MaxApp.RecentDocument"
            
            /* 倒序加载确保最新在前 */
            for i = (entries.Count-1) to 0 by -1 do (
                local pathNode = entries.Item[i].SelectSingleNode "FilePath"
                if pathNode != undefined do (
                    local filePath = pathConfig.normalizePath pathNode.InnerText
                    local exists = doesFileExist filePath
                    append g_recentFiles #(filePath, exists)
                )
            )
        )
        catch (
            format "[XML加载错误] %\n" (getCurrentException())
        )
        --保持原始排序（下面单行代码-实际/实现文件排序效果：最近的在最上面）-- 目前符合 文件 排序感官 -- 若 显示 排序不正常 则 需 去除 即��
        g_recentFiles = for i = g_recentFiles.count to 1 by -1 collect g_recentFiles[i]
    )
    g_recentFiles
)

-- 强化版姿势复制函数（修复Biped控制器访问）
fn copyPosture = (
    global g_postureCache = #()
    
    -- 获取Biped主接口函数
    fn getBipedMaster obj = (
        if (maxVersion())[1] >= 24000 then (
            try(Interface13.GetBipDriver12Interface obj.TMController)catch(undefined)
        ) else (  -- 修复此处缺少的右括号
            try(Interface13.GetBipMaster12Interface obj.TMController)catch(undefined)
        )
    )  -- 补全getBipedMaster函数结束括号
    
    for obj in objects where (classOf obj == BoneGeometry or classOf obj == Biped_Object or classOf obj == Point) do (
        local isRootBiped = false
        local bipData = undefined
        local isPoint = (classOf obj == Point)
        
        -- 使用CPTools的矩阵获取方式
        local tm = matrix3 1
        if classOf obj == Biped_Object do (
            try (
                local master = getBipedMaster obj
                if master != undefined do (
                    isRootBiped = (master.GetRootNode() == obj)
                    local id = 0, link = 0
                    master.GetIdLink obj &id &link
                    tm = master.GetBipedTM currentTime id link
                )
            )
            catch()
        )
        
        append g_postureCache #(
            obj.name,
            (if classOf obj == Biped_Object then tm else obj.transform), -- 使用精准矩阵
            bipData,
            if obj.parent != undefined then obj.parent.name else "",
            classOf obj == BoneGeometry,
            isPoint,
            (if classOf obj == Biped_Object then getBipedMaster obj else undefined) -- 存储Biped主接口
        )
    )
    format "[姿势备份] 已记录 % 个骨骼状态\n" g_postureCache.count
)  -- 补全copyPosture函数结束括号

-- 智能姿势粘贴函数（整合CPTools骨骼处理）
fn pastePosture enableAutoKey = (
    if g_postureCache == undefined do return false
    
    local originalAutoKey = autoKeyMode
    autoKeyMode = enableAutoKey
    local startTime = animationRange.start
    
    -- 阶段0：初始化Biped系统
    disableSceneRedraw()
    progressStart "初始化Biped系统..."
    try (
        for entry in g_postureCache where entry[7] != undefined do (
            entry[7].StartSettingBipedKeys() -- 启动快速设置模式
        )
    )
    catch (format "[初始化错误] %\n" (getCurrentException()))
    enableSceneRedraw()
    progressEnd()

    -- 阶段1：应用变换矩阵
    disableSceneRedraw()
    progressStart "应用精准矩阵..."
    try (
        for entry in g_postureCache do (
            local targetObj = getNodeByName entry[1]
            if not isValidNode targetObj do continue
            
            try (
                case of (
                    (entry[5]): ( -- 常规骨骼
                        targetObj.transform = entry[2]
                        if enableAutoKey do addNewKey targetObj.transform.controller startTime
                    )
                    
                    (entry[6]): ( -- Point辅助
                        targetObj.transform = entry[2]
                        if enableAutoKey do addNewKey targetObj.transform.controller startTime
                    )
                    
                    (entry[7] != undefined): ( -- Biped骨骼
                        local master = entry[7]
                        local id = 0, link = 0
                        master.GetIdLink targetObj &id &link
                        
                        -- 使用CPTools的SetBipedTM方法
                        master.SetBipedTM startTime entry[2] id link
                        if enableAutoKey do (
                            master.AddKey startTime
                            biped.update targetObj #all
                        )
                    )
                )
                format "[成功] % % 更新\n" (classOf targetObj) targetObj.name
            )
            catch (format "[应用错误] % : %\n" targetObj.name (getCurrentException()))
        )
    )
    catch (format "[矩阵应用错误] %\n" (getCurrentException()))
    enableSceneRedraw()
    progressEnd()

    -- 阶段2：关闭Biped快速模式
    disableSceneRedraw()
    progressStart "完成Biped操作..."
    try (
        for entry in g_postureCache where entry[7] != undefined do (
            entry[7].StopSettingBipedKeys() -- 关闭快速设置模式
            biped.update entry[7].GetRootNode() #all
        )
    )
    catch (format "[关闭错误] %\n" (getCurrentException()))
    enableSceneRedraw()
    progressEnd()

    autoKeyMode = originalAutoKey
    true
)

/* 使用示例：
with redraw off (
    copyPosture() -- 备份姿势
    
    -- 导入FBX后执行
    pastePosture false  -- 基础姿势
    pastePosture true   -- 动画关键帧
    
    -- 最终更新
    for master in biped.getBipedRoots() do (
        biped.createAllLayers master
        maxOps.CollapseNode master off
    )
)
format "[完成] 姿势应用成功！\n"
*/

-- 修正后的文件加载函数 / true
fn loadFileSafe fPath = (
    if not doesFileExist fPath do return false
    
    try (
        if maxFilePath != "" and needsSave do (
            if not (queryBox "场景未保存，是否继续？" title:"警告") do return false
        )
        
        loadMaxFile fPath useFileUnits:true quiet:true
   
    ) catch (
        format "加载失败：%\n" (getCurrentException())
        false
    )
)

-- Lv列表刷新函数（必须声明在rollout内部）/（稳定的刷新函数）核心列表刷新函数 ！

    fn refreshFileListView forceRefresh:false = (
        -- 确保未截断列表
        local itemsToShow = model_files_array  -- 直接使用完整数组
        -- 调整列宽调整顺序到BeginUpdate之前
        --adjustColumnWidths forceCustom:g_forceCustomLayout 
        -- 在BeginUpdate前更新列宽
        lvHeader.Columns.Item[2].Width = if chkChangeFont.checked then 145 else 125
    
        lvHeader.Refresh()
        
        Lv_model.BeginUpdate()
        --Lv_model.Scrollable = false  -- 每次刷新时强制禁用
        --Lv_model.Scrollable = true
        Lv_model.Items.Clear()
        model_files_array = #()
        -- 添加数据时设置对齐方式
        for i=1 to model_files_array.count do (
            local li = dotNetObject "System.Windows.Forms.ListViewItem" ""
            
            -- CK列内容居中
            li.Text = "✓" -- 示例图标
            li.TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Center
            
            -- 文件列左对齐（默认）
            li.SubItems.Add(filenameFromPath model_files_array[i])
            
            -- 类型列居中
            local typeItem = li.SubItems.Add(getFileType model_files_array[i])
            typeItem.TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Center
        )
        local currentPath = pathConfig.normalizePath edtExportPath.text -- 第一层标准化
        local currentPath = edtExportPath.text
        local pathValid = false
        try (
            pathValid = doesDirectoryExist currentPath
            if not pathValid and matchPattern currentPath pattern:"\\\\*" do (
                dotNetClass "System.Threading.Thread").Sleep(1000)  -- 直接调用静态方法
                --dotNet.invokeMethod (dotNetClass "System.Threading.Thread") "Sleep" #(1000)
                pathValid = doesDirectoryExist currentPath
            
        ) catch (pathValid = false)
        
        if not pathValid  do (
            Lv_model.EndUpdate()
            lblCount.text = "路径不可用！"
            messageBox ("路径不可访问：\n" + currentPath) title:"错误" beep:false
            return false
        )
        -- 强制去除当前路径末尾反斜杠
        if currentPath != "" and currentPath[currentPath.count] == "\\" do (
            currentPath = substring currentPath 1 (currentPath.count - 1)
        )
        if not doesDirectoryExist currentPath do return #()
        
        -- 获取目录和文件（自然排序）
        local data = g_fileManager.getFilesAndDirs currentPath (
            case rdoFileFilter.state of (
                1: "*.max"                   -- Max场景
                2: "*.fbx"                   -- FBX资源
                3: "*.ms*"                   -- 精确匹配所有脚本类型(Max脚本/加密脚本/宏脚本)
                4: "*.bip"                   -- Biped数据
                5: "*.mzp"                   -- 宏脚本
                6: "*.xaf"                    -- 附件数据
                default: "*"                   -- 默认全显示
            )
        )
        
        -- 分离目录和文件计数
        local dirCount = data[1].count
        local fileCount = data[2].count
        
        local dirs = data[1]
        local files = data[2]
        local fileCount = files.count -- 新增文件计数
        local baseDepth = (filterString currentPath "\\").count
        -- 自然排序
        qsort dirs g_fileManager.pseudoNaturalSort
        qsort files g_fileManager.pseudoNaturalSort
    
        -- 添加目录项 / true
        for d in data[1] do (
            local normDir = pathConfig.normalizePath d
            -- 强制去除末尾反斜杠
            if normDir != "" and normDir[normDir.count] == "\\" do (
                normDir = substring normDir 1 (normDir.count - 1)
            )
        
        -- 提取纯文件夹名称 / true （默认通用）
        local folderName = filenameFromPath normDir
        li = dotNetObject "System.Windows.Forms.ListViewItem" "📂"
        li.UseItemStyleForSubItems = false
        
        -- 主列图标颜色（固定值）
        li.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 245 245 125 -- 固定浅黄色
        
        -- 文件名列（跟随文件夹颜色配置）
        local subName = li.SubItems.Add(folderName)
        subName.ForeColor = g_ColorConfig.folderNameColor  -- 使用配置颜色
        
        -- 类型列（同步文件名颜色）
        local subType = li.SubItems.Add("文件夹")
        subType.ForeColor = g_ColorConfig.folderNameColor  -- 与文件名同色
        
        li.Tag = d
        Lv_model.Items.Add(li)
        append model_files_array ("[DIR]"+d) -- 目录标记
    )
    
    -- 添加目录项 / true (文件项保持稳定逻辑)
    for f in data[2] do (
        local exists = doesFileExist f
        
        li = dotNetObject "System.Windows.Forms.ListViewItem" (if exists then "📄" else "✘")
        li.UseItemStyleForSubItems = false
        
        -- 主列图标颜色（固定白色）
        li.ForeColor = (dotNetClass "System.Drawing.Color").White
        
        -- 文件名列（跟随文件颜色配置）
        local subName = li.SubItems.Add(filenameFromPath f)
        subName.ForeColor = if exists then g_ColorConfig.fileNameColor else (dotNetClass "System.Drawing.Color").Red
        
        -- 类型列（同步文件名颜色）
        local typeInfo = try(getFileType f)catch("无效文件")
        local subType = li.SubItems.Add(if exists then typeInfo else "失效文件")
        subType.ForeColor = if exists then g_ColorConfig.fileNameColor else (dotNetClass "System.Drawing.Color").Red
        
        li.Tag = f
        Lv_model.Items.Add(li)
        append model_files_array f   --  仅添加文件路径
        
        -- 在创建列表项后添加特殊标记
        local isMergeFile = (findString (toLower (getFilenameFile f)) "merge") != undefined or 
                           (findString (toLower (getFilenameFile f)) "socket") != undefined or
                           (findString (getFilenameFile f) "挂点") != undefined
        
        if isMergeFile do (
            li.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 255 200 0  -- 橙色标记合并文件
            li.Text = "🔗"  -- 链接图标
        )
        
        -- 在创建列表项后添加特殊标记（分段文件）
        local fileName = toLower (getFilenameFile f)
        local isSegmentFile = (findString fileName "start") != undefined or 
                             (findString fileName "loop") != undefined or 
                             (findString fileName "end") != undefined

        if isSegmentFile do (
            li.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 216 191 216  -- 标记分段文件颜色
            li.Text = "🔄"  -- 循环图标
        )
        --append g_model_files_array f
    )
        
    -- 调整列宽//失效-false/默认列表width/不在这调整！！！//在全局函数里调整即可 / false 
        --if Lv_model.Columns.Count >= 3 do (                
            --Lv_model.Columns.Item[0].Width = 50
            --Lv_model.Columns.Item[1].Width = 310
            --Lv_model.Columns.Item[2].Width = 100
        --)
        
        -- 文件计数部分
        local fileCount = 0
        for i=0 to (Lv_model.Items.Count-1) do (
        if Lv_model.Items.Item[i].SubItems.Item[2].Text != "文件夹" do fileCount += 1)
        lblCount.text = "文件：" + (fileCount as string)
        
        --lblCount.text = "文件：" + (model_files_array.count) as string -- 更新计数列表显示的所有/items / false / 备用
        
         -- 新增：计算并更新文件计数
         local dirCount = (getDirectories (edtExportPath.text + "\\*")).count
         lblCount.text = "文件：" + (model_files_array.count - dirCount) as string
         
         -- 更新模式状态中的路径信息
         local currentFolder = if ddlLikedPaths.selection > 0 then 
        g_likedFolders[ddlLikedPaths.selection].name else 
        filenameFromPath currentPath
        
        -- 强制状态栏更新
        updateModeStatus()
        if ModeStatus.Items.Count > 0 do (
            try (
                local item = ModeStatus.Items.Item[0]
                item.SubItems[2].Text = lblCount.text
                ModeStatus.Refresh()
            ) catch ()
        )
        Lv_model.Scrollable = (Lv_model.Items.Count * 20 > Lv_model.Height) -- 根据项数动态启用
        -- 强制设置滚动范围
        Lv_model.VirtualListSize = model_files_array.count
        Lv_model.EndUpdate()
    
        -- 在刷新完成后添加：
        if g_forceCustomLayout do (
            adjustColumnWidths forceCustom:true
            Lv_model.Font = g_alternateFont
        )
        
        -- 确保默认状态
        if not g_forceCustomLayout do (
            adjustColumnWidths forceCustom:false
            Lv_model.Font = g_defaultFont
        )
    -- 新增：统一滚动条控制
    Lv_model.Scrollable = false
    --adjustColumnWidths forceCustom:g_forceCustomLayout -- 关键：先调整列宽 / false 
    Lv_model.Scrollable = true
    
    -- 特殊处理最近文件模式
    --if g_showRecentFiles do (
        --Lv_model.Columns.Item[1].Width -= 20 -- 文件名列压缩防止溢出
        --Lv_model.Scrollable = false
        --Lv_model.Scrollable = true -- 保持垂直滚动
    --)
        -- 强制重绘
        Lv_model.Refresh()
        updateModeStatus()
        --adjustColumnWidths ()
        windows.processPostedMessages() -- 关键！确保UI刷新
    )

----------------------------------------------------------------
--自动保存监控-函数
fn initAutoSaveWatcher = (
    try (
        g_autoSaveWatcher.Path = g_autoSavePath
        g_autoSaveWatcher.Filter = "*.max"
        g_autoSaveWatcher.NotifyFilter = (dotNetClass "System.IO.NotifyFilters").FileName
        g_autoSaveWatcher.EnableRaisingEvents = true
        
        -- 修正参数传递方式为数组
        dotnet.addEventHandler g_autoSaveWatcher "Created" (fn s e = (
            dotNet.invokeMethod (dotNetClass "System.Threading.Thread") "Sleep" #(1000)
            if doesFileExist e.FullPath and (getFilenameType e.FullPath) == ".max" do (
                additem_lv Lv_model e.FullPath
            )
        ))
    ) catch (
        format "[监控初始化错误] %\n" (getCurrentException())
    )
)

-- 在监控事件中增加重试机制/优化选项--待验证-false
--dotNet.addEventHandler g_autoSaveWatcher "Created" (fn s e = (
    --local retryCount = 0
    --while retryCount < 3 do (
        --try (
            --if doesFileExist e.FullPath do (
                --additem_lv Lv_model e.FullPath
                --exit
            --)
        --) catch (
           --retryCount += 1
            --dotNet.invokeMethod (dotnetclass "System.Threading.Thread") "Sleep" 500
        --)
    --)
--))

-- 强化动画检测-函数
fn export_mod_fn mod_state = (
    --
    case mod_state of (
        1: ( -- Auto模式（智能判断）
            FbxExporterSetParam "ResetExport"
            FbxExporterSetParam "SmoothingGroups" true
            FbxExporterSetParam "SmoothMeshExport" true
            
            FbxExporterSetParam "Cameras" false
            FbxExporterSetParam "Lights" false
            FbxExporterSetParam "EmbedTextures" false
            FbxExporterSetParam "ShowWarnings" false
        )
        2: ( -- Skin模型模式
            FbxExporterSetParam "ResetExport"
            FbxExporterSetParam "SmoothingGroups" true
            FbxExporterSetParam "SmoothMeshExport" true
            FbxExporterSetParam "Animation" false
            FbxExporterSetParam "EmbedTextures" false
            FbxExporterSetParam "Cameras" false
            FbxExporterSetParam "Lights" false
            FbxExporterSetParam "Skin" true -- 显式启用蒙皮
            FbxExporterSetParam "ShowWarnings" false
        )
        3: ( -- Bake动画模式
            FbxExporterSetParam "ResetExport"
            FbxExporterSetParam "SmoothingGroups" false
            FbxExporterSetParam "SmoothMeshExport" false
            
            FbxExporterSetParam "Animation" true
            FbxExporterSetParam "BakeAnimation" true
            FbxExporterSetParam "BakeResampleAnimation" true
            FbxExporterSetParam "FilterKeyReducer" true
            
            FbxExporterSetParam "EmbedTextures" false
            FbxExporterSetParam "Cameras" false
            FbxExporterSetParam "Lights" false
            FbxExporterSetParam "ShowWarnings" false
        )
    )
        
)

-- 选择集过滤函数 / 未验证 / false / 备用
fn filterSetsByMode sets = (
    case rdo_exportMode.state of (
        2: ( -- Skin模式过滤
            local skinSets = for s in sets where matchPattern s pattern:"*skin*" collect s
            if skinSets.count == 0 do (
                messageBox "未找到包含'skin'的选择集！" title:"模式不匹配"
                throw "导出中止"
            )
            skinSets -- 关键：返回单一数组
        )
        
        default: sets -- Auto模式不过滤
 
    )
) 

-- 日期时间刷新函数 =================================================
fn fnRefreshDate = (
    local arrTime = getLocalTime()  -- 获取本地时间数组
    
    -- 格式化日期时间 -------------------------------------------------
    local formattedDate = formattedPrint arrTime[1] format:"04d" + "/" +  -- 年
                          formattedPrint arrTime[2] format:"02d" + "/" +  -- 月
                          formattedPrint arrTime[4] format:"02d"         -- 日
    --全显示（时分）
    local formattedTime = formattedPrint arrTime[5] format:"02d" + ":" +  -- 时
                          formattedPrint arrTime[6] format:"02d"          -- 分
                         
    --全显示（时分秒）
	--local formattedTime = formattedPrint arrTime[5] format:"02d" + ":" +  -- 时
                          --formattedPrint arrTime[6] format:"02d" + ":" +  -- 分
                          --formattedPrint arrTime[7] format:"02d"         -- 秒
	-- 计算星期 ------------------------------------------------------
    local dayWeekID = mod arrTime[3] 7  -- 星期索引 (0=日,1=一...6=六)
    
    -- 构建显示字符串 -------------------------------------------------
    lblDateTime.text = formattedDate + "  星期" + arrDayWeek[dayWeekID + 1] + "  " + formattedTime  --（实时秒显示）
)

-- 记忆窗口位置配置函数（pos-remenber)
fn savePositionToINI pos = (
        local iniPath = (getDir #scripts) + "\\AutoExportTool_Pro.ini"
        try (
            setIniSetting iniPath "Settings" "LastPos" (pos as string)
        ) catch (
            format "[错误] 无法保存窗口位置到INI文件：%\n" (getCurrentException())
            messageBox "无法保存设置，请检查脚本目录权限！" title:"警告"
        )
    )


-- 实时检测选择集状态函数
fn refreshSceneSetsCache = (
    g_sceneSetsCache = #()
    try (
        g_sceneSetsCache = for i=1 to (getNumNamedSelSets()) collect (getNamedSelSetName i)
    ) catch (
        format "[错误] 选择集刷新失败：%\n" (getCurrentException())
    )
)

-- 检查基础场景状态--函数
fn isValidScene = (
    try (
        local valid = true
        valid = valid and (maxFileName != undefined)  -- 场景文件名有效性
        valid = valid and (objects.count > 0)         -- 至少存在一个对象
        valid = valid and (not isDeleted rootNode)    -- 根节点有效性
        valid
    ) catch (
        false
    )
)    
    
-- 修改CheckForSave函数，确保始终返回布尔值 / 服务于 双击打开 
fn CheckForSave = (
    try (
        -- 确保needsSave转换为布尔值
        local needsSaveState = (needsSave as BooleanClass)
        if needsSaveState then (
            local res = queryBox "当前场景未保存，是否保存更改？" title:"保存确认"
            return (res == true) -- 明确返回布尔值
        ) else (
            return true -- 无需保存时直接返回true
        )
    ) catch (
        format "[OpenSuccess] MouseDoubleClick--双击打开文件成功！！！\n" (getCurrentException())
        return true -- 异常时默认允许继续操作
    )
)
    
-- 定义通用文件打开函数 - 服务于双击打开文件/（注意若此类代码执行中引用到其他函数，则 需 排在引用到的函数的后面即-代码行下方！！！fn CheckForSave = (... 此函数的后面任意位置！
fn openFileWithDefaultApp filePath = (
    if (CheckForSave()) do (
        g_lastAction = "双击-打开文件"
        updateModeStatus()
        try (
            shellLaunch filePath ""
            
            -- 如果是MAX文件，高亮显示
            if (toLower (getFilenameType filePath)) == ".max" do (
                -- 稍等片刻让文件加载完成
                dotNet.invokeMethod (dotNetClass "System.Threading.Thread") "Sleep" 500
                highlightCurrentFile()
            )
            
            format "已打开文件：%\n" filePath
        ) catch (
            format "[打开错误] 文件：%\n错误：%\n" filePath (getCurrentException())
        )
    )
)

--lv列表-主要新增序号可勾选/拓展插件加载缓存；
fn initPluginSystem = (
        
    -- 初始化列表
    Lv_model.View = (dotNetClass "System.Windows.Forms.View").Details
    Lv_model.CheckBoxes = true  
    Lv_model.MultiSelect = true  
 )
     
-- 动态布局调整函数 -- new try
fn updateButtonLayout = (
    -- 计算文本实际需要的像素宽度
    local textPadding = 20 -- 左右留白
    btn_aotu_model.width = (getTextExtent btn_aotu_model.text)[1] + textPadding
    btn_exp_M_fbx.width = (getTextExtent btn_exp_M_fbx.text)[1] + textPadding
    
    -- 强制刷新布局
    AutoExportTool_Pro.width = 500  --  roulout--尺寸 wide 失效，以此强制尺寸为主宽，按需可删，对应 updateButtonLayout()
    redrawViews()           -- true 刷新列表 
    ---refreshFileListView()
)
    
   
----------------------------------------------------------------
    
-- 刷新场景选择集--函数
fn GetSetFormScene = (
    sele_set_list = #()
    local set_array = getNumNamedSelSets()
    for i=1 to set_array do (
        append sele_set_list (getNamedSelSetName i)
    )
    selec_set.items = sele_set_list
)
    
    ----------------------------------------------------------------
    
-- 列表-框架-函数1
fn setup_list lv_body =
(
    lv_body.view = (dotnetclass "system.windows.forms.view").details
    lv_body.fullrowselect = True
    lv_body.gridlines = True
    lv_body.hideselection = false
    lv_body.borderstyle = lv_body.borderstyle.fixedsingle
    lv_body.headerstyle = lv_body.headerstyle.nonclickable
    lv_body.backcolor = lv_body.backcolor.fromargb 225 225 225
    lv_body.allowdrop = True
)
    
-- 列表-框架-函数2
fn newlist_columns lv_body str_array size_arry =
(
    for i=1 to str_array.count do
    (
        lv_body.columns.add str_array[i] size_arry[i]
    )
)
    
-- 列表初始化强化（列宽自适应）
fn start_Lv_model = (
    Lv_model.MultiSelect = true -- 启用多选
    Lv_model.HideSelection = false -- 保持选中可见
    -- 基础设置
    Lv_model.View = (dotNetClass "System.Windows.Forms.View").Details
    Lv_model.HeaderStyle = (dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None
    Lv_model.FullRowSelect = true
    Lv_model.Scrollable = false  -- 初始禁用滚动条
    Lv_model.MultiSelect = true -- 启用多选/新增/添加多选支持
    Lv_model.HideSelection = false -- 保持选中可见/新增/添加多选支持
    Lv_model.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
    -- 添加滚动事件处理
    Lv_model.Scrollable = (Lv_model.Items.Count * 20 > Lv_model.Height) -- 根据项数动态启用
    -- 创建列头并设置对齐
    Lv_model.Columns.Clear()
    
    -- CK/ICON列
    local colCK = Lv_model.Columns.Add "CK/ICON" COLUMN_CK_WIDTH
    colCK.TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Center
    
    -- 文件列（自适应宽度）
    local colFile = Lv_model.Columns.Add "文件/Name" (LISTVIEW_WIDTH - COLUMN_CK_WIDTH - COLUMN_TYPE_WIDTH - 5) -- 留出滚动条空间
    
    -- 类型列
    local colType = Lv_model.Columns.Add "类型/Type" COLUMN_TYPE_WIDTH
    colType.TextAlign = (dotNetClass "System.Windows.Forms.HorizontalAlignment").Center
    
    -- 设置标题字体
    
    --Lv_model.Font = dotNetObject "System.Drawing.Font" "微软雅黑" 8 ((dotNetClass "System.Drawing.FontStyle").Bold)

    --Lv_model.Font = dotNetObject "System.Drawing.Font" "宋体" 9 ((dotNetClass "System.Drawing.FontStyle").Regular)

    --Lv_model.Font = dotNetObject "System.Drawing.Font" "黑体" 10 ((dotNetClass "System.Drawing.FontStyle").Italic)
    
    Lv_model.Sorting = (dotNetClass "System.Windows.Forms.SortOrder").None
    
    -- 设置全局背景色 --------------------------
    --Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 180 180 180       -- 背景颜色-true
    Lv_model.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 255 255 255          -- 默认文字颜色 - 备用-false
    --Lv_model.ForeColor = (dotNetClass "System.Drawing.Color").Blue                         -- true 生效
    Lv_model.allowDrop = true
    updateModeStatus()
)

--高亮 / 颜色参考 
--电光蓝--RGB:color( 0 149 255 )
--霓虹紫--RGB:color( 255 0 255 )
--荧光绿--RGB:color( 50 255 50 )
--宝石红--RGB:color( 220 20 60 )
--镭射银--RGB:color( 192 192 192 )
--激光绿--RGB:color( 0 255 0 ) // 纯绿，视觉极亮
--炫光橙--RGB:color( 255 80 0 ) // 红橙火焰色
--极光青--RGB:color( 0 255 255 ) // 蓝绿双通道拉满
--霓虹粉--RGB:color( 255 0 127 ) // 荧光粉刺眼效果
--火焰红--RGB:color( 255 0 0 ) // 纯红基准色
--镭射金--RGB:color( 255 215 0 ) // 金属光泽高亮黄
--荧光柠黄--RGB:color( 200 255 0 ) // 绿黄混合荧光
--电光紫--RGB:color( 180 0 255 ) // 蓝紫通道极致对比
--赛博蓝--RGB:color( 0 150 255 ) // 比电光蓝更冷冽
--信号黄--RGB:color( 255 255 30 ) // 警示灯级别高亮

--泡糖粉--RGB:color( 255 105 180 ) ；樱花粉-- RGB:color ( 255 182 193 ) ； -- 复古蓝 RGB:color( 135 206 250 )；婴儿蓝 RGB:color( 135 206 235 )；
	--银灰 RGB:color( 192 192 192) ； --薰衣草紫 RGB:color( 216 191 216 )； -- 赛博蓝 RGB:color( 0 184 255 )；
	---- 紫晶色RGB:color( 160 0 255 )  (RGB；-- 霓虹粉 (RGB:(color( 255 95 155 )；-- 亮黄 RGB:color( 255 255 0) 

--薄荷绿--RGB:color( 62 180 137 )
--深海蓝--RGB:color( 0 105 148 )
--奶油橙--RGB:color( 255 179 102 )
--薰衣草--RGB:color( 181 126 220 )
--琥珀金--RGB:color( 255 176 59 )

--冰川灰--RGB:color( 112 128 144 )
--樱桃红--RGB:color( 222 49 99 )
--香槟色--RGB:color( 242 210 161 )
--孔雀蓝--RGB:color( 0 117 113 )
--巧克力棕--RGB:color( 123 63 0 )

--暖色
--落日橘--RGB:color( 255 95 31 )
--玫瑰金--RGB:color( 183 110 121 )
--焦糖棕--RGB:color( 175 110 75 )
--珊瑚粉--RGB:color( 255 114 118 )
--荧光黄--RGB:color( 204 255 0 )

--冷色
--松石绿--RGB:color( 64 224 208 )
--雾霾蓝--RGB:color( 109 155 195 )
--橄榄绿--RGB:color( 128 128 0 )
--冰川蓝--RGB:color( 176 224 230 )
--暗夜紫--RGB:color( 102 0 153 )

--中性
--石板灰--RGB:color( 94 94 94 )
--亚麻米--RGB:color( 250 240 230 )
--炭黑色--RGB:color( 28 28 28 )
--水泥灰--RGB:color( 168 172 173 )
--珍珠白--RGB:color( 248 248 255 )

-- 删除选中的文件/文件夹函数/true/稳定 / 优势：统一的删除逻辑：

--文件和文件夹使用相似的删除流程 / 服务器路径统一使用DOS命令

--本地路径使用原生方法
fn deleteSelectedFiles = (
    try (
        local selItems = AutoExportTool_Pro.Lv_model.SelectedItems
        if selItems.Count == 0 do return undefined
        
        -- 构建文件列表字符串
        local fileList = ""
        for i=0 to selItems.Count-1 do (
            local path = selItems.Item[i].Tag as String
            fileList += path + "\n"
        )
        
        -- 确认对话框
        local msg = "确定永久删除以下项目？此操作不可恢复！\n\n" + fileList
        if not (queryBox msg title:"危险操作" beep:true) do return false
        
        -- 删除所有选中的项目
        local deletedItems = #()
        local failedItems = #()
        
        for i=selItems.Count-1 to 0 by -1 do (
            local path = selItems.Item[i].Tag as String
            local isNetworkPath = matchPattern path pattern:"\\\\*"
            local success = false
            local isDir = doesDirectoryExist path
            local successCount = 0
            local failCount = 0
            try (
                if isDir then (
                    -- 删除文件夹
                    if isNetworkPath then (
                        -- 服务器路径使用DOS命令
                        local cmd = "cmd /c rmdir /s /q \"" + path + "\""
                        hiddenDOSCommand cmd
                    ) else (
                        -- 本地路径使用.NET方法
                        local dir = dotNetClass "System.IO.Directory"
                        dir.Delete path true
                    )
                ) else (
                    -- 删除文件
                    if isNetworkPath then (
                        -- 服务器路径使用DOS命令
                        local cmd = "cmd /c del /f /q \"" + path + "\""
                        hiddenDOSCommand cmd
                    ) else (
                        deleteFile path
                    )
                )
                
                -- 验证删除
                if (isDir and not doesDirectoryExist path) or (not isDir and not doesFileExist path) then (
                    success = true
                    g_lastAction = "​​右键-删除" + (if isDir then "文件夹" else "文件")
                    updateModeStatus()
                )
            ) catch (
                success = false
            )
            
            -- 记录结果
            if success then (
                append deletedItems path
            ) else (
                append failedItems path
            )
        )
        
        -- 刷新文件列表
        AutoExportTool_Pro.refreshFileListView()
        -- 显示操作结果
        local resultMsg = ""
        --local resultMsg = g_lastAction
        if deletedItems.count > 0 then (
        g_lastAction = "已删除 " + (deletedItems.count as string) + " 个项目\n"
        updateModeStatus()
    )
        if failedItems.count > 0 then (
            resultMsg += "删除失败 " + (failedItems.count as string) + " 个项目:\n"
            for i=1 to (amin 5 failedItems.count) do (  -- 最多显示5个失败项
                resultMsg += failedItems[i] + "\n"
            )
            if failedItems.count > 5 do resultMsg += "......\n"
        )
        
        if resultMsg != "" do messageBox resultMsg title:"删除结果"
        updateModeStatus() 
    ) catch (
        format "[删除错误] %\n" (getCurrentException())
        messageBox ("删除过程中发生错误: " + (getCurrentException())) title:"错误"
    )
)

--双重删除尝试 / 首先尝试使用DOS命令强制删除 / 如果DOS命令失败，再尝试使用MAXScript的deleteFile方法 / 每次尝试后验证文件是否确实被删除
--本地删除已经实现且稳定/服务器则有几率不稳定 - 若 删除无效 则 需 等待服务器网络恢复 相对稳定后 再次 操作尝试！！！问题不大..
-- 带重试机制的文件删除函数/未验证/备用 （当服务器地址不稳定则删除不成功，列表刷新文件/文件夹还存在，新增的一个重删机制，当检测到 not success  则 进行重试 ）本地删除已经实现且稳定
fn deleteFileWithRetry path maxRetries:3 = (
    local retryCount = 0
    local success = false
    local isNetworkPath = matchPattern path pattern:"\\\\*"
    
    while retryCount < maxRetries and not success do (
        try (
            if isNetworkPath then (
                -- 服务器路径使用DOS命令
                local cmd = "cmd /c del /f /q \"" + path + "\""
                hiddenDOSCommand cmd
                -- 检查文件是否被删除
                if not doesFileExist path then (
                    success = true
                )
            ) else (
                -- 本地路径使用MAXScript方法
                deleteFile path
                if not doesFileExist path then success = true
            )
        ) catch (
            success = false
        )
        
        if not success do (
            sleep 0.5  -- 等待0.5秒再重试
            retryCount += 1
        )
    )
    
    success
)

-- 修复后的文件/文件夹属性查看函数
fn showItemProperties path = (
    try (
        if not (doesFileExist path or doesDirectoryExist path) do (
            messageBox "路径不存在: " + path title:"错误"
            return false
        )
        
        if Lv_model.SelectedItems.Count == 0 do return undefined
        local selItem = Lv_model.SelectedItems.Item[0]
        local fPath = selItem.Tag as String
        -- 获取基本信息
        local size = 0
        local modDate = "未知"
        if doesFileExist path then (
            size = getFileSize path
            modDate = getFileModDate path
        )
        else if doesDirectoryExist path then (
            modDate = getFileModDate path
            -- 计算文件夹大小
            local totalSize = 0
            local files = getFiles (path + "\\*.*")
            for f in files do totalSize += getFileSize f
            size = totalSize
        )
        
        -- 转换文件大小格式
        local sizeStr
        case of (
            (size > 1024*1024*1024): sizeStr = (size/(1024*1024*1024)) as string + " GB"
            (size > 1024*1024): sizeStr = (size/(1024*1024)) as string + " MB"
            (size > 1024): sizeStr = (size/1024) as string + " KB"
            default: sizeStr = size as string + " 字节"
        )
        
        -- 创建属性字符串
        local msg = "路径:🌻 " + path + "\n" + \
                   "类型:📩 " + (if doesDirectoryExist path then "文件夹" else "文件") + "\n" + \
                   "大小: " + sizeStr + "\n" + \
                   "修改时间: " + modDate
        
        -- 显示消息框
        messageBox msg title:"属性"
    ) catch (
        format "[属性错误] %\n" (getCurrentException())
        messageBox ("⚠️不支持文件夹属性获取: " + (getCurrentException())) title:"错误"
    )
)

-- 辅助函数：格式化文件大小
fn formatSize size = (
    case of (
        (size > 1024*1024*1024): (size/(1024*1024*1024.0)) as string + " GB"
        (size > 1024*1024): (size/(1024*1024.0)) as string + " MB"
        (size > 1024): (size/1024.0) as string + " KB"
        default: size as string + " 字节"
    )
)

-- 创建编辑框函数
fn createEditTextBox item = (
    try (
        -- 获取项目位置和大小（只针对文件/文件夹名称列）
        local rect = item.SubItems.Item[1].Bounds
        
        -- 创建编辑框
        g_editTextBox = dotNetObject "System.Windows.Forms.TextBox"
        g_editTextBox.Bounds = rect
        g_editTextBox.Text = item.SubItems.Item[1].Text
        g_editTextBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
        g_editTextBox.Font = Lv_model.Font
              -- 确定是文件还是文件夹
              local oldPath = item.Tag as String
              g_editingIsFile = not (doesDirectoryExist oldPath)
              
              -- 优化文件名显示
              if g_editingIsFile then (
                  -- 文件：只显示文件名部分（不带扩展名）
                  g_editTextBox.Text = getFilenameFile item.SubItems.Item[1].Text
              ) else (
                  -- 文件夹：显示完整名称
                  g_editTextBox.Text = item.SubItems.Item[1].Text
              )
        -- 添加编辑框到ListView
        Lv_model.Controls.Add g_editTextBox
        g_editTextBox.Focus()
        g_editTextBox.SelectAll()
        
        -- 保存当前编辑项
        g_editingItem = item
    )
    catch (
        format "[创建编辑框错误] %\n" (getCurrentException())
    )
)

-- 完成编辑函数
fn finishEditing = (
    try (
        if g_editTextBox != undefined and g_editingItem != undefined do (
            local newName = g_editTextBox.Text
            local oldPath = g_editingItem.Tag as String
            local isFolder = doesDirectoryExist oldPath
            
            -- 构建新路径
            local newPath = ""
            if isFolder then (
                local parentDir = getFilenamePath oldPath
                newPath = pathConfig.appendPath parentDir newName
            ) else (
                local dir = getFilenamePath oldPath
                local ext = getFilenameType oldPath
                newPath = dir + newName + ext
            )
            
            -- 执行重命名
            if isFolder then (
                -- 使用DOS命令重命名文件夹
                local cmd = "cmd /c ren \"" + oldPath + "\" \"" + newName + "\""
                hiddenDOSCommand cmd
            ) else (
                -- 文件重命名
                renameFile oldPath newPath
            )
            
            -- 更新列表项
            g_editingItem.SubItems.Item[1].Text = if isFolder then newName else (newName + ext)
            g_editingItem.Tag = newPath
            g_lastAction = "重命名成功"
            updateModeStatus()
            
            -- 清理编辑状态
            Lv_model.Controls.Remove g_editTextBox
            g_editTextBox.Dispose()
            g_editTextBox = undefined
            g_editingItem = undefined
        )
    )
    catch (
        format "[重命名错误] %\n" (getCurrentException())
        cancelEditing()
    )
)

-- 取消编辑函数
fn cancelEditing = (
    try (
        if g_editTextBox != undefined do (
            Lv_model.Controls.Remove g_editTextBox
            g_editTextBox.Dispose()
            g_editTextBox = undefined
            g_editingItem = undefined
            g_lastAction = "重命名取消"
            updateModeStatus()
        )
    )
    catch (
        format "[取消编辑错误] %\n" (getCurrentException())
    )
)

-- 重命名函数（启动编辑）
fn renameSelectedItem = (
    try (
        local selItems = AutoExportTool_Pro.Lv_model.SelectedItems
        if selItems.Count != 1 do (
            messageBox "请选择单个项目进行重命名" title:"提示"
            return false
        )
        
        local item = selItems.Item[0]
        createEditTextBox item
    ) 
    catch (
        format "[重命名错误] %\n" (getCurrentException())
    )
)

-- 新增/列表-剪切功能（支持多选）
fn cutSelectedItems = (
    try (
        g_clipboard = #()
        g_clipboardType = "cut"
        local selItems = AutoExportTool_Pro.Lv_model.SelectedItems
        
        -- 支持多选
        for i=0 to selItems.Count-1 do (
            local path = selItems.Item[i].Tag as String
            append g_clipboard path
        )
        
        if g_clipboard.count > 0 do (
            g_lastAction = "已剪切 " + (g_clipboard.count as string) + " 个项目"
            updateModeStatus()
        )
    ) catch (
        format "[剪切错误] %\n" (getCurrentException())
    )
)

-- 新增/列表-复制功能（支持多选）
fn copySelectedItems = (
    try (
        g_clipboard = #()
        g_clipboardType = "copy"
        local selItems = AutoExportTool_Pro.Lv_model.SelectedItems
        
        -- 支持多选
        for i=0 to selItems.Count-1 do (
            local path = selItems.Item[i].Tag as String
            append g_clipboard path
        )
        
        if g_clipboard.count > 0 do (
            g_lastAction = "已复制 " + (g_clipboard.count as string) + " 个项目"
            updateModeStatus()
        )
    ) catch (
        format "[复制错误] %\n" (getCurrentException())
    )
)

-- 新增/列表-粘贴功能（修复文件夹剪切）
fn pasteItems = (
    try (
        -- 检查剪贴板是否为空
        if g_clipboard.count == 0 do (
            messageBox "剪贴板为空" title:"提示"
            return false
        )
        
        -- 确定目标路径
        local targetPath = ""
        local selItems = AutoExportTool_Pro.Lv_model.SelectedItems
        
        -- 如果选中了单个文件夹
        if selItems.Count == 1 and doesDirectoryExist (selItems.Item[0].Tag as String) then (
            targetPath = selItems.Item[0].Tag as String
        ) 
        -- 如果当前列表路径有效
        else if g_currentPath != undefined and doesDirectoryExist g_currentPath then (
            targetPath = g_currentPath
        )
        -- 如果都没有，使用导出路径作为后备
        else if AutoExportTool_Pro.edtExportPath.text != "" then (
            targetPath = AutoExportTool_Pro.edtExportPath.text
        )
        else (
            messageBox "无法确定目标位置，请先选择一个文件夹或设置导出路径" title:"错误"
            return false
        )
        
        -- 确保目标路径存在
        if not doesDirectoryExist targetPath do (
            makeDir targetPath all:true
        )
        
        local successCount = 0
        local failCount = 0
        local movedItems = #()  -- 记录成功移动的项目
        
        for path in g_clipboard do (
            try (
                -- 确保源路径有效
                if not (doesFileExist path or doesDirectoryExist path) do (
                    format "[粘贴警告] 源路径不存在: %\n" path
                    failCount += 1
                    continue
                )
                
                local fileName = filenameFromPath path
                local newPath = targetPath + "\\" + fileName
                
                -- 处理文件夹
                  if doesDirectoryExist path then (
                    if g_clipboardType == "copy" then (
                        -- 复制文件夹
                        local cmd = "cmd /c xcopy /E /I /Y \"" + path + "\" \"" + newPath + "\""
                        hiddenDOSCommand cmd
                        if doesDirectoryExist newPath do successCount += 1
                    ) else (
                        -- 移动文件夹
                        local cmd = "cmd /c move /Y \"" + path + "\" \"" + newPath + "\""
                        hiddenDOSCommand cmd
                        if doesDirectoryExist newPath do successCount += 1
                    )
                    
                    if g_clipboardType == "cut" then (
                        -- 复制文件夹
                        local cmd = "cmd /c xcopy /E /I /Y \"" + path + "\" \"" + newPath + "\""
                        hiddenDOSCommand cmd
                        if doesDirectoryExist newPath do successCount += 1
                    ) else (
                        -- 移动文件夹
                        local cmd = "cmd /c move /Y \"" + path + "\" \"" + newPath + "\""
                        hiddenDOSCommand cmd
                        if doesDirectoryExist newPath do successCount += 1
                    )
                        
                        -- 检查是否移动成功
                        if doesDirectoryExist newPath and not doesDirectoryExist path then (
                            successCount += 1
                            append movedItems path  -- 记录已移动的项目
                        ) else (
                            failCount += 1
                    )
                )
                
                -- 处理文件
                else if doesFileExist path then (
                    if g_clipboardType == "copy" then (
                        -- 复制文件
                        local result = copyFile path newPath
                        if result and doesFileExist newPath then (
                            successCount += 1
                        ) else (
                            failCount += 1
                        )
                    ) else (
                        -- 移动文件
                        local result = renameFile path newPath
                        if result and doesFileExist newPath and not doesFileExist path then (
                            successCount += 1
                            append movedItems path  -- 记录已移动的项目
                        ) else (
                            failCount += 1
                        )
                    )
                )
            ) catch (
                failCount += 1
                format "[粘贴错误] 项目: % 错误: %\n" path (getCurrentException())
            )
        )
        
        -- 如果是剪切操作，只移除成功移动的项目
        if g_clipboardType == "cut" then (
            for movedItem in movedItems do (
                local index = findItem g_clipboard movedItem
                if index > 0 do deleteItem g_clipboard index
            )
            
            -- 如果所有项目都已移动，清空剪贴板类型
            if g_clipboard.count == 0 then (
                g_clipboardType = ""
            )
        )
        
        -- 刷新文件列表
        AutoExportTool_Pro.refreshFileListView()
        
        g_lastAction = "已粘贴 " + (successCount as string) + " 个项目 (" + (failCount as string) + " 失败)"
        updateModeStatus()
        
        return true
    )
    catch (
        format "[粘贴错误] %\n" (getCurrentException())
        messageBox ("粘贴失败: " + (getCurrentException())) title:"错误"
        return false
    )
)



fn ensurePluginDir = (
    local pluginDir = getDir #scripts
    if not doesDirectoryExist pluginDir do (
        makeDir pluginDir all:true
    )
    pluginDir
)

--备份主插件 ms .. 简化 / 修复 8.18

fn createBackup = (
    try (
        if doesFileExist g_pluginPath do (
            -- 确保目录存在
            makeDir (getFilenamePath g_backupPluginPath) all:true
            
            -- 删除旧备份
            if doesFileExist g_backupPluginPath do (
                try (deleteFile g_backupPluginPath) 
                catch (format "[备份清理错误] %\n" (getCurrentException()))
            )
            
            -- 创建备份
            try (
                copyFile g_pluginPath g_backupPluginPath
                format "[备份成功] 插件已备份到: %\n" g_backupPluginPath
            ) 
            catch (
                format "[备份失败] %\n" (getCurrentException())
            )
        )
    ) 
    catch (
        format "[备份错误] %\n" (getCurrentException())
    )
)

-- 工具栏添加 max ui // macroScript(外部菜单宏工具栏) / true
fn addToolbarToMax = (
    -- 创建备份
    createBackup()
    
    -- 确保宏脚本在外部定义
    macroScript VideoTutorialAction 
    category:"AutoExportTool" 
    buttonText:"🎬 视频教程 | Video Tutorial"
    (
        openHelpLink "https://space.bilibili.com/327573825"
    )

    macroScript DocumentationAction 
    category:"AutoExportTool" 
    buttonText:"📚 帮助文档 | Documentation"
    (
        openHelpLink "https://ladyicefox.github.io/autoexporttool-docs/"
    )

    macroScript IssuesAction 
    category:"AutoExportTool" 
    buttonText:"🐛 问题建议 | Report Issues"
    (
        openHelpLink "https://github.com/ladyicefox/autoexporttool-docs/issues"
    )

    -- 新增：检查更新宏脚本
    macroScript checkForUpdatesAction 
    category:"AutoExportTool" 
    buttonText:"🔄 检查更新 | Check Updates"
    (
        try (
            checkForUpdates ()
            
        ) catch (
            format "[检查更新错误] %\n" (getCurrentException())
        )
    )

    -- 新增：重置窗口位置宏脚本
    macroScript ResetWindowPosAction 
    category:"AutoExportTool" 
    buttonText:"🔄 重置窗口位置 | Reset Window Position"
    (
        try (
            -- 如果插件窗口已经打开，则重置其位置
            if isDialogVisible AutoExportTool_Pro do (
                -- 获取屏幕尺寸
                local screenWidth = sysInfo.desktopSize[1]
                local screenHeight = sysInfo.desktopSize[2]
                
                -- 计算中央位置
                local dialogWidth = AutoExportTool_Pro.width
                local dialogHeight = AutoExportTool_Pro.height
                local centerX = (screenWidth - dialogWidth) / 2
                local centerY = (screenHeight - dialogHeight) / 2
                
                -- 设置对话框位置
                setDialogPos AutoExportTool_Pro [centerX, centerY]
                
                -- 更新全局变量和INI文件
                g_lastDialogPos = [centerX, centerY]
                setINISetting g_WindowPosPath "Window" "Position" (g_lastDialogPos as string)
                
                --messageBox "窗口位置已重置到屏幕中央！" title:"重置窗口位置"
            )
        ) catch (
            format "[重置窗口位置错误] %\n" (getCurrentException())
        )
    )

    -- 开启自动检测更新的宏脚本
    macroScript AutoUpdateEnableAction
    category:"AutoExportTool"
    buttonText:"✨ 开启自动检测 | Auto-Update On"
    (
        on execute do (
            g_autoCheckUpdate = true
            setINISetting g_UIConfigPath "Settings" "AutoCheckUpdate" "true"
            messageBox "自动检测更新已开启" title:"设置已更新"
        )
    )
    
    -- 关闭自动检测更新的宏脚本
    macroScript AutoUpdateDisableAction
    category:"AutoExportTool"
    buttonText:"❌ 关闭自动检测 | Auto-Update Off"
    (
        on execute do (
            g_autoCheckUpdate = false
            setINISetting g_UIConfigPath "Settings" "AutoCheckUpdate" "false"
            messageBox "自动检测更新已关闭" title:"设置已更新"
        )
    )
    
    macroScript AutoStartEnableAction 
        category:"AutoExportTool" 
        buttonText:"✨ 开启 ⚮​ Open"
    (
        try (
            if not g_autoStartEnabled do (
                toggleAutoStart()
                messageBox "AutoExportTool 自启 - 已打开" title:"✨ 成功"
            )
        ) catch (
            format "[自启开启错误] %\n" (getCurrentException())
        )
    )
    
    macroScript AutoStartDisableAction 
        category:"AutoExportTool" 
        buttonText:"❌ 关闭 ⚭​ Close"
    (
        try (
            if g_autoStartEnabled do (
                toggleAutoStart()
                messageBox "AutoExportTool 自启 - 已解除" title:"✨ 成功"
            )
        ) catch (
            format "[自启关闭错误] %\n" (getCurrentException())
        )
    )

    macroScript OpenToolAction 
    category:"AutoExportTool" 
    buttonText:"🧰 AutoExportTool"
    (
        try (
            fn findPluginFile = (
                -- 1. 首先尝试原始路径
                if doesFileExist g_pluginPath do return g_pluginPath
                
                -- 2. 尝试备份路径
                if doesFileExist g_backupPluginPath do return g_backupPluginPath
                
                -- 3. 在脚本目录中搜索
                local scriptDir = getDir #scripts
                local files = getFiles (scriptDir + "\\AutoExportTool_Pro*.ms")
                if files.count > 0 do return files[1]
                
                -- 4. 在备份目录中搜索
                local backupDir = scriptDir + "\\AutoExportTool_Backup\\"
                if doesDirectoryExist backupDir do (
                    local backupFiles = getFiles (backupDir + "\\AutoExportTool_Pro*.ms")
                    if backupFiles.count > 0 do return backupFiles[1]
                )
                
                undefined
            )
            
            local pluginPath = findPluginFile()
            if pluginPath == undefined do (
                messageBox "找不到AutoExportTool插件文件!" title:"错误"
                return false
            )
            
            -- 加载插件
            fileIn pluginPath
            
            -- 创建对话框（如果尚未显示）
            if not (isDialogVisible AutoExportTool_Pro) do (
                createDialog AutoExportTool_Pro
            )
        ) 
        catch (
            format "[工具栏错误] %\n" (getCurrentException())
            messageBox ("打开插件失败: " + (getCurrentException())) title:"错误"
        )
    )
    
    macroScript BilibiliAction 
        category:"AutoExportTool" 
        buttonText:"📺 Bilibili | 🔗 B/Link"
    (
        openHelpLink "https://space.bilibili.com/327573825"
    )
    
    macroScript QQSpaceAction 
        category:"AutoExportTool" 
        buttonText:"🐧 Qzone | 🔗 Q-Link"
    (
        openHelpLink "https://user.qzone.qq.com/240811498"
    )
    
    macroScript RemoveToolbarAction 
        category:"AutoExportTool" 
        buttonText:"💣 卸载工具栏 ​​⚬​⧐ Uninstall"
    (
        try (
            removeToolbarFromMax()
        ) catch (
            format "[工具栏移除错误] %\n" (getCurrentException())
        )
    )
    
    macroScript CloseToolAction 
        category:"AutoExportTool"
        buttonText:"❌ 关闭插件 ⧐ CloseTool "
    (
        try (
            if isDialogVisible AutoExportTool_Pro do (
                destroyDialog AutoExportTool_Pro
            )
        ) catch ()
    )
    
    -- 更新工具栏状态
    g_toolbarAdded = true
    setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "true"
    
    try (
        local mainMenu = menuMan.getMainMenuBar()
        local subMenu = menuMan.findMenu "AutoExportTool"
        
        -- 移除旧菜单（如果存在）
        if subMenu != undefined do (
            menuMan.unRegisterMenu subMenu
            menuMan.updateMenuBar()
        )
        
        -- 创建新菜单
        subMenu = menuMan.createMenu "AutoExportTool"
        
        -- 添加主功能项
        local openToolItem = menuMan.createActionItem "OpenToolAction" "AutoExportTool"
        openToolItem.setTitle "🧰​AutoExportTool"
        subMenu.addItem openToolItem -1
        
        -- 添加到主菜单栏
        local mainItem = menuMan.createSubMenuItem "🧰​AutoExportTool" subMenu
        mainMenu.addItem mainItem (mainMenu.numItems() + 1)
        
        -- 添加分隔符
        local separator = menuMan.createSeparatorItem()
        subMenu.addItem separator -1
        
        -- 创建自启子菜单
        local autoStartSubMenu = menuMan.createMenu "自启设置"
        
        -- 创建自启动作项
        local enableAutoStartItem = menuMan.createActionItem "AutoStartEnableAction" "AutoExportTool"
        enableAutoStartItem.setTitle "✨ 开启 ⚮​ Open"
        
        local disableAutoStartItem = menuMan.createActionItem "AutoStartDisableAction" "AutoExportTool"
        disableAutoStartItem.setTitle "❌ 关闭 ⚭​ Close"
        
        -- 将自启动作项添加到自启子菜单
        autoStartSubMenu.addItem enableAutoStartItem -1
        autoStartSubMenu.addItem disableAutoStartItem -1
        
        -- 将自启子菜单添加到主菜单
        local autoStartMenuItem = menuMan.createSubMenuItem "🗿 自启设置 | AutoStart" autoStartSubMenu
        subMenu.addItem autoStartMenuItem -1
        
        -- 添加分隔符
        local separator1 = menuMan.createSeparatorItem()
        subMenu.addItem separator1 -1
        
        -- 创建版本更新子菜单
        local updateSubMenu = menuMan.createMenu "版本更新"
        
        -- 创建立即检查更新动作项
        local checkNowItem = menuMan.createActionItem "checkForUpdatesAction" "AutoExportTool"
        checkNowItem.setTitle "🔄 检查更新 | Check Updates"
        updateSubMenu.addItem checkNowItem -1
        
        -- 添加分隔符
        local updateSeparator = menuMan.createSeparatorItem()
        updateSubMenu.addItem updateSeparator -1
        
        -- 创建开启自动检测动作项
        local enableAutoUpdateItem = menuMan.createActionItem "AutoUpdateEnableAction" "AutoExportTool"
        enableAutoUpdateItem.setTitle "✨ 开启自动检测 | Auto-Update On"
        
        -- 创建关闭自动检测动作项
        local disableAutoUpdateItem = menuMan.createActionItem "AutoUpdateDisableAction" "AutoExportTool"
        disableAutoUpdateItem.setTitle "❌ 关闭自动检测 | Auto-Update Off"
        
        -- 将自动检测动作项添加到版本更新子菜单
        updateSubMenu.addItem enableAutoUpdateItem -1
        updateSubMenu.addItem disableAutoUpdateItem -1
        
        -- 将版本更新子菜单添加到主菜单
        local updateMenuItem = menuMan.createSubMenuItem "🔄 版本更新 | Check Updates" updateSubMenu
        subMenu.addItem updateMenuItem -1
        
        -- 添加分隔符
        local separator2 = menuMan.createSeparatorItem()
        subMenu.addItem separator2 -1
        
        -- 创建帮助子菜单
        local helpSubMenu = menuMan.createMenu "❓ 帮助 | Help"
        
        -- 添加视频教程项
        local videoTutorialItem = menuMan.createActionItem "VideoTutorialAction" "AutoExportTool"
        videoTutorialItem.setTitle "🎬 视频教程 | Video Tutorial"
        helpSubMenu.addItem videoTutorialItem -1
        
        -- 添加帮助文档项
        local docsItem = menuMan.createActionItem "DocumentationAction" "AutoExportTool"
        docsItem.setTitle "📚 帮助文档 | Documentation"
        helpSubMenu.addItem docsItem -1

        -- 添加问题建议项
        local issuesItem = menuMan.createActionItem "IssuesAction" "AutoExportTool"
        issuesItem.setTitle "🐛 问题建议 | Report Issues"
        helpSubMenu.addItem issuesItem -1
        
        -- 添加分隔线
        local separatorNew = menuMan.createSeparatorItem()
        helpSubMenu.addItem separatorNew -1
        
        -- 添加B站链接项
        local bilibiliItem = menuMan.createActionItem "BilibiliAction" "AutoExportTool"
        bilibiliItem.setTitle "📺 Bilibili | 🔗 B/Link "
        helpSubMenu.addItem bilibiliItem -1
        
        -- 添加QQ空间链接项
        local qqSpaceItem = menuMan.createActionItem "QQSpaceAction" "AutoExportTool"
        qqSpaceItem.setTitle "🐧 Qzone | 🔗 Q-Link"
        helpSubMenu.addItem qqSpaceItem -1
        
        -- 添加分隔符
        local separator3 = menuMan.createSeparatorItem()
        helpSubMenu.addItem separator3 -1
        
        -- 添加工具栏管理项
        local removeToolbarItem = menuMan.createActionItem "RemoveToolbarAction" "AutoExportTool"
        removeToolbarItem.setTitle "💣 卸载工具栏 ​​⚬​⧐ Uninstall"
        helpSubMenu.addItem removeToolbarItem -1
        
        -- 添加分隔符
        local separator4 = menuMan.createSeparatorItem()
        helpSubMenu.addItem separator4 -1
        
        -- 添加重置窗口位置项
        local resetWindowPosItem = menuMan.createActionItem "ResetWindowPosAction" "AutoExportTool"
        resetWindowPosItem.setTitle "🔄 重置窗口位置 | Reset Window Position"
        helpSubMenu.addItem resetWindowPosItem -1
    
        -- 添加分隔线
        local separatorReset = menuMan.createSeparatorItem()
        helpSubMenu.addItem separatorReset -1
        
        -- 添加关闭插件/工具项
        local closeToolItem = menuMan.createActionItem "CloseToolAction" "AutoExportTool"
        closeToolItem.setTitle "❌ 关闭插件 ⧐ CloseTool"
        helpSubMenu.addItem closeToolItem -1
        
        -- 将帮助子菜单添加到主菜单
        local helpMenuItem = menuMan.createSubMenuItem "❓ 帮助 | Help" helpSubMenu
        subMenu.addItem helpMenuItem -1
        
        -- 更新菜单栏
        menuMan.updateMenuBar()
        
        g_toolbarAdded = true
        setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "true"
        
        g_lastAction = "工具栏已添加到3ds Max菜单"
        updateModeStatus()
        messageBox "✨ 工具栏已成功添加到3ds Max菜单栏" title:"成功"
        
    ) catch (
        format "[工具栏添加错误] %\n" (getCurrentException())
        messageBox ("添加工具栏失败: " + (getCurrentException())) title:"错误"
    )
)


--插件备份 / 恢复 功能 - 恢复性检查
fn checkAndRecoverPlugin = (
    -- 如果主插件丢失但备份存在
    if not doesFileExist g_pluginPath and doesFileExist g_backupPluginPath do (
        try (
            -- 从备份恢复
            makeDir (getFilenamePath g_backupPluginPath) all:true
            copyFile g_backupPluginPath g_pluginPath
            format "[恢复] 插件已从备份恢复: %\n" g_pluginPath
        ) catch (
            format "[恢复错误] %\n" (getCurrentException())
        )
    )
    
    -- 如果备份过时（主插件更新日期更晚）
    if doesFileExist g_pluginPath and doesFileExist g_backupPluginPath and \
       (getFileModDate g_pluginPath) > (getFileModDate g_backupPluginPath) do (
        try (
            -- 更新备份
            makeDir (getFilenamePath g_backupPluginPath) all:true
            copyFile g_pluginPath g_backupPluginPath
            format "[备份更新] 插件备份已更新\n"
        ) catch (
            format "[备份更新错误] %\n" (getCurrentException())
        )
    )
)

-- 首次启动时自动添加工具栏/在INI文件中记录已添加状态/避免重复添加）/ 注意 引用 addToolbarToMax() 行列先后位置！！！
fn autoAddToolbarOnFirstRun = (
    -- 检查是否已经添加过工具栏
    local alreadyAdded = getINISetting g_UIConfigPath "Settings" "ToolbarAdded"
    if alreadyAdded != "true" then (
        addToolbarToMax()
        setINISetting g_UIConfigPath "Settings" "ToolbarAdded" "true"
    )
)

-- 右键菜单事件处理 / true
fn setupContextMenu = (
    -- 右键菜单显示事件
    dotNet.addEventHandler g_contextMenu "Opening" (fn sender args = (
        try (
            -- 清除现有菜单项
            g_contextMenu.Items.Clear()
            
            -- 获取选中的项目
            local selItems = AutoExportTool_Pro.Lv_model.SelectedItems
            
            -- 检查是否点击在空余处 (没有选中任何项目)
            local isClickOnEmpty = (selItems.Count == 0)
            
            -- 如果是点击在空余处，显示粘贴菜单
            if isClickOnEmpty then (
                -- 粘贴菜单（始终显示）
                local pasteItem = g_contextMenu.Items.Add("📋 粘贴")
                dotNet.addEventHandler pasteItem "Click" (fn s e = pasteItems())
                
                return true
            )
            
            
            -- 检查是否多选（2个或更多项目）
            local isMultiSelect = (selItems.Count > 1)
            
            -- 如果是多选，显示批量操作菜单
            if isMultiSelect then (
                -- 添加剪切菜单
                local cutItem = g_contextMenu.Items.Add("✄ 剪切")
                dotNet.addEventHandler cutItem "Click" (fn s e = cutSelectedItems())
                
                -- 添加复制菜单
                local copyItem = g_contextMenu.Items.Add("⧉ 复制")
                dotNet.addEventHandler copyItem "Click" (fn s e = copySelectedItems())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 添加删除菜单
                local deleteItem = g_contextMenu.Items.Add("❌ 删除")
                dotNet.addEventHandler deleteItem "Click" (fn s e = deleteSelectedFiles())
                
                return true
            )
            
            -- 单选情况下的处理
            local firstItem = selItems.Item[0]
            local path = firstItem.Tag as String
            local isFolder = doesDirectoryExist path
            
            -- 根据类型添加不同的菜单项
            if isFolder then (
                -- 文件夹的菜单项
                local openFolderItem = g_contextMenu.Items.Add("📂→打开文件夹")
                dotNet.addEventHandler openFolderItem "Click" (fn s e = (
                    for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                        local itemPath = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                        if doesDirectoryExist itemPath then (
                            shellLaunch "explorer.exe" ("\"" + itemPath + "\"")
                            g_lastAction = "​​右键-打开文件夹"
                            updateModeStatus()
                        )
                    )
                ))
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 新增：粘贴功能
                local pasteItem = g_contextMenu.Items.Add("​⎗​ 粘贴")
                dotNet.addEventHandler pasteItem "Click" (fn s e = pasteItems())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
        
                -- 新增：剪切功能
                local cutItem = g_contextMenu.Items.Add("✄​ 剪切")
                dotNet.addEventHandler cutItem "Click" (fn s e = cutSelectedItems())
                
                -- 新增：复制功能
                local copyItem = g_contextMenu.Items.Add("⧉ 复制")
                dotNet.addEventHandler copyItem "Click" (fn s e = copySelectedItems())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 添加通用删除菜单项
                local deleteItem = g_contextMenu.Items.Add("❌ 删除")
                dotNet.addEventHandler deleteItem "Click" (fn s e = deleteSelectedFiles())
            
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
              
                -- 添加重命名菜单
                local renameItem = g_contextMenu.Items.Add("✏️ 重命名")
                dotNet.addEventHandler renameItem "Click" (fn s e = renameSelectedItem())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                local propertiesItem = g_contextMenu.Items.Add("📌 属性")
                dotNet.addEventHandler propertiesItem "Click" (fn s e = (
                    for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                        local itemPath = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                        showItemProperties itemPath
                        g_lastAction = "​​右键-属性"
                        updateModeStatus()
                    )
                ))
            )
            else (
                -- 文件的菜单项
                local fileType = toLower (getFilenameType path)
                -- 添加通用打开选项 - 但BIP 和 xaf 文件除外 / 排除特定类型
                if fileType != ".bip" and fileType != ".xaf" do (
                    local openItem = g_contextMenu.Items.Add("📋→默认方式打开")
                    dotNet.addEventHandler openItem "Click" (fn s e = (
                        for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                            local itemPath = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                            if doesFileExist itemPath then (
                                shellLaunch itemPath ""
                                g_lastAction = "​​右键-打开文件"
                                updateModeStatus()
                            )
                        )
                    ))
                )
                
                -- 添加分隔线（使用通用排除逻辑） // 修改在这里
                local excludedTypes = #(".max", ".fbx", ".ms",".mse",".mcr",".mzp")
                if (findItem excludedTypes fileType) != 0 do (
                    g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                )
                
                
                -- 类型特定菜单项
                case fileType of (
                    
                    ".max": (
                        g_lastAction = "​​右键-当前打开"
                        updateModeStatus()
                        -- 只显示特定于bip的菜单项
                        
                        local maxItem = g_contextMenu.Items.Add("🔜→当前场景打开")
                        dotNet.addEventHandler maxItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                resetMaxFile #noPrompt
                                loadMaxFile Path useFileUnits:true quiet:true
                        -- 打开max 同时刷新 选择集 / true 
                                GetSetFormScene() 
                                messageBox ("MAX打开成功: " + path) title:"操作成功"
                            )
                        ))
                    )
                    
                    ".bip": (
                        g_lastAction = "​​右键-导入BIP"
                        updateModeStatus()
                        -- 只显示特定于bip的菜单项
                        local bipItem = g_contextMenu.Items.Add("🔤→导入BIP")
                        dotNet.addEventHandler bipItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                SilentBipedImport path
                                messageBox ("BIP导入成功: " + path) title:"操作成功"
                            )
                        ))
                    )
                    
                    ".ms": (
                        g_lastAction = "​​右键-运行脚本"
                        updateModeStatus()
                        -- 只显示特定于ms的菜单项
                        local runItem = g_contextMenu.Items.Add("🔤→运行脚本")
                        dotNet.addEventHandler runItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                fileIn path
                            )
                        ))
                    )
                    
                    ".mse": (
                        g_lastAction = "​​右键-运行加密脚本"
                        updateModeStatus()
                        -- 只显示特定于mse的菜单项
                        local runItem = g_contextMenu.Items.Add("🔤→运行加密脚本")
                        dotNet.addEventHandler runItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                fileIn path
                            )
                        ))
                    )
                    
                    ".mzp": (
                        g_lastAction = "​​右键-运行宏脚本"
                        updateModeStatus()
                        -- 只显示特定于mzp的菜单项
                        local runItem = g_contextMenu.Items.Add("🔤→运行宏脚本")
                        dotNet.addEventHandler runItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                fileIn path
                            )
                        ))
                    )
                    
                    ".mcr": (
                        g_lastAction = "​​右键-运行宏脚本"
                        updateModeStatus()
                        -- 只显示特定于mcr的菜单项
                        local runItem = g_contextMenu.Items.Add("🔤→运行宏脚本")
                        dotNet.addEventHandler runItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                fileIn path
                            )
                        ))
                    )
                    
                    ".xaf": (
                        g_lastAction = "​​右键-导入XAF"
                        updateModeStatus()
                        -- 只显示特定于xaf的菜单项
                        local xafItem = g_contextMenu.Items.Add("🔤→导入XAF")
                        dotNet.addEventHandler xafItem "Click" (fn s e = (
                            for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                importXafAnimation path
                                messageBox ("xaf导入成功: " + path) title:"操作成功"
                            )
                        ))
                    )
                    
                    ".fbx": (
                        g_lastAction = "​​右键-用FBX查看器打开"
                        updateModeStatus()
                        -- 只显示特定于fbx的菜单项
                        local fbxItem = g_contextMenu.Items.Add("用FBX查看器打开")
                        dotNet.addEventHandler fbxItem "Click" (fn s e = (
                            local viewerPath = getDir #scripts + "\\FBXViewer.exe"
                            if doesFileExist viewerPath then (
                                for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                                    local path = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                                    ShellLaunch viewerPath ("\"" + path + "\"")
                                )
                            ) else (
                                messageBox "FBX查看器未找到，请将FBXViewer.exe放入脚本目录！" title:"错误"
                            )
                        ))
                        
                        -- 添加分隔线
                        g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                        
                        -- 添加"导入场景"菜单项
                        local importSceneItem = g_contextMenu.Items.Add("🔤→导入场景")
                        dotNet.addEventHandler importSceneItem "Click" (fn s e = (
                            local selectedItems = AutoExportTool_Pro.Lv_model.SelectedItems
                            if selectedItems.Count == 0 do return false
                            
                            -- 只导入第一个选中的FBX文件
                            local fbxPath = selectedItems.Item[0].Tag as String
                            
                            -- 确认操作
                            local msg = "确定要清空当前场景并导入FBX文件吗？\n" + fbxPath
                            if not (queryBox msg title:"导入FBX场景" beep:false) do return false
                            
                            try (
                                -- 清空场景
                                resetMaxFile #noPrompt  
                                
                                -- 设置FBX导入参数为默认值
                                FBXImporterSetParam "Mode" #create        -- 创建新场景
                                FBXImporterSetParam "Animations" true     -- 导入动画
                                FBXImporterSetParam "Cameras" true        -- 导入摄像机
                                FBXImporterSetParam "Lights" true         -- 导入灯光
                                FBXImporterSetParam "AxisConversion" true -- 应用轴转换
                                FBXImporterSetParam "Rescale" true        -- 自动缩放
                                
                                -- 导入FBX文件
                                importFile fbxPath #noPrompt using:FBXIMP
                                
                                g_lastAction = "FBX导入场景"
                                updateModeStatus()
                                messageBox "FBX文件已成功导入场景" title:"操作成功"
                                
                            ) catch (
                                format "[FBX导入错误] %\n" (getCurrentException())
                                messageBox ("FBX导入失败: " + (getCurrentException())) title:"错误"
                            )
                        ))
                    )
                )  -- 结束case语句
                
                   -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 新增：粘贴功能
                local pasteItem = g_contextMenu.Items.Add("​⎗​ 粘贴")
                dotNet.addEventHandler pasteItem "Click" (fn s e = pasteItems())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
        
                -- 新增：剪切功能
                local cutItem = g_contextMenu.Items.Add("✄ ​剪切")
                dotNet.addEventHandler cutItem "Click" (fn s e = cutSelectedItems())
                
                -- 新增：复制功能
                local copyItem = g_contextMenu.Items.Add("⧉ 复制")
                dotNet.addEventHandler copyItem "Click" (fn s e = copySelectedItems())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 添加通用删除菜单项
                local deleteItem = g_contextMenu.Items.Add("❌ 删除")
                dotNet.addEventHandler deleteItem "Click" (fn s e = deleteSelectedFiles())
            
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 添加重命名菜单
                local renameItem = g_contextMenu.Items.Add("✏️ 重命名")
                dotNet.addEventHandler renameItem "Click" (fn s e = renameSelectedItem())
                
                -- 添加分隔线
                g_contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
                
                -- 添加通用属性菜单项
                local propertiesItem = g_contextMenu.Items.Add("📌 属性")
                dotNet.addEventHandler propertiesItem "Click" (fn s e = (
                    for i=0 to AutoExportTool_Pro.Lv_model.SelectedItems.Count-1 do (
                        local itemPath = AutoExportTool_Pro.Lv_model.SelectedItems.Item[i].Tag as String
                        showItemProperties itemPath
                        g_lastAction = "​​右键-属性"
                        updateModeStatus()
                    )
                ))
            )  -- 结束else块（文件处理）
            
            true -- 显示菜单
        ) catch (
            format "[菜单错误] %\n" (getCurrentException())
            false -- 不显示菜单
        )
    ))  -- 结束Opening事件处理函数
    --g_contextMenu.Show (mouse.screenPos[1]) (mouse.screenPos[2])
    -- 绑定右键菜单到列表
    AutoExportTool_Pro.Lv_model.ContextMenuStrip = g_contextMenu
)  -- 结束setupContextMenu函数

-- 在列表空余处右键呼出菜单
fn createEmptyAreaContextMenu = (
    -- 创建临时菜单
    local tempMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
    
    -- 粘贴菜单
    local pasteItem = tempMenu.Items.Add("粘贴")
    dotNet.addEventHandler pasteItem "Click" (fn s e = pasteItems())
    
    -- 显示菜单
    tempMenu.Show (mouse.screenPos[1]) (mouse.screenPos[2])
)

-- 列表空余处右键处理（使用命名函数）
fn onListViewRightClick s e = (
    try (
        if e.Button == e.Button.Right then (
            local hitTest = Lv_model.HitTest e.X e.Y
            
            -- 如果点击在空余处（没有项目）
            if hitTest.Item == undefined then (
                -- 创建临时菜单
                local tempMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
                
                -- 粘贴菜单
                local pasteItem = tempMenu.Items.Add("粘贴")
                dotNet.addEventHandler pasteItem "Click" (fn s e = pasteItems())
                
                -- 显示菜单
                tempMenu.Show (mouse.screenPos[1]) (mouse.screenPos[2])
            )
        )
    )
    catch (
        format "[右键菜单错误] %\n" (getCurrentException())
    )
-- 绑定右键事件
dotNet.addEventHandler Lv_model "MouseClick" onListViewRightClick
)

-- 增强滚动状态检测函数
fn updateScrollState = 
(
    try 
    (
        -- 动态计算列宽（关键修改）
        --local totalWidth = Lv_model.ClientRectangle.Width
        Lv_model.Columns.Item[1].Width = totalWidth - COLUMN_CK_WIDTH - COLUMN_TYPE_WIDTH - 5 -- 25为滚动条预留宽度
        
        -- 垂直滚动条自动显示
        local itemHeight = Lv_model.GetItemRect(0).Height
        local visibleItems = (Lv_model.ClientRectangle.Height / itemHeight) as integer
        Lv_model.Scrollable = (Lv_model.Items.Count > visibleItems)
        --Lv_model.Refresh()
		
	)
    catch 
    (
        try(Lv_model.Scrollable = true)catch()
    )
    chkChangeFont.checked = true  -- 覆盖INI配置，强制勾选
    g_forceCustomLayout = true    -- 同步全局状态
    adjustColumnWidths forceCustom:true -- 立即应用列宽e
    Lv_model.Font = g_alternateFont     -- 强制应用字体

	)

-- 修改后的 additem_lv 函数
fn additem_lv lv_body file_node isDrag:false = (
    if doesFileExist file_node or doesDirectoryExist file_node do (
        try (
            lv_body.BeginUpdate()
            local isDir = (getFilenameType file_node) == "" -- 修复类型判断
            local li = dotNetObject "System.Windows.Forms.ListViewItem" (if isDir then "📂" else "📄")
            
            -- 显示原始文件名（保留点号）
            li.subitems.add (filenameFromPath file_node)
            
            -- 强制设置类型（关键修复）
            li.subitems.add (if isDir then "文件夹" else getFileType file_node)
            
            li.Tag = file_node
            lv_body.Items.Add(li)
            append model_files_array file_node
            lv_body.EndUpdate()
            
            -- 立即更新计数和状态
            lblCount.text = "文件：" + (model_files_array.count - (getDirectories (edtExportPath.text + "\\*")).count) as string
            updateModeStatus()
        ) catch (
            format "添加文件到列表失败：%\n" (getCurrentException())
        )
    )
)


----------------------------------------------------------------
    
    -- ===================== 新增功能模块 ===========================

    ----------------------------------------------------------------
    
-- 确保进度更新函数正确调用
fn updateProgress index total success fail = (
    try (
        local progressPercent = (100.0 * index / total) as integer
        pbProgress.value = progressPercent
        lblProgressInfo.text = "进度：" + progressPercent as string + "% | 成功：" + success as string + " | 失败：" + fail as string
        pbProgress.refresh()
        --windows.processPostedMessages() -- 强制界面更新
        if mod index 5 == 0 do (  -- 每5个文件更新一次界面
        --lblProgressInfo.text = "进度：" + ((100.0*index/total) as integer) as string + "%"
        pbProgress.value = index
        windows.processPostedMessages()  -- 控制刷新频率
        )
    ) catch (
        format "[进度更新错误] %\n" (getCurrentException())
    )
)
    
    
-- 在函数定义区域添加缺失的 updateExportPath 函数 ================
    -- 修改路径更新函数，响应自动生成复选框变化
fn updateExportPath forceAuto:false = (
    if chkAutoFolder.checked or forceAuto then (
        basePath = if maxFilePath != "" then maxFilePath else getDir #scene
        edtExportPath.text = pathConfig.appendPath basePath "FBX"
    ) else (
        if edtExportPath.text == "" do edtExportPath.text = getDir #scene
    )
    if not doesFileExist edtExportPath.text do makeDir edtExportPath.text all:true
)
    
   -- 挂点归零函数 - 在导出前处理所有包含"Socket"的对象
fn resetSocketTransforms = (
    local socketNodes = for obj in objects where (
        (classOf obj == Dummy or classOf obj == Point) and 
        matchPattern obj.name pattern:"*Socket*"
    ) collect obj
    
    local originalStates = #()
    
    for node in socketNodes do (
        -- 保存原始状态
        local state = #(
            node.parent,
            node.transform,
            node.rotation.controller
        )
        append originalStates #(node, state)
        
        -- 断开与父对象的链接
        node.parent = undefined
        
        -- 重置位置和旋转
        node.pos = [0,0,0]
        
        -- 确保使用Euler XYZ旋转控制器
        if classOf node.rotation.controller != Euler_XYZ do (
            node.rotation.controller = Euler_XYZ()
        )
        
        -- 设置旋转 (X:90, Y:0, Z:0)
        node.rotation.controller.x_rotation = 90
        node.rotation.controller.y_rotation = 0
        node.rotation.controller.z_rotation = 0
        
        format "[挂点归零] 已处理: %\n" node.name
    )
    
    return originalStates
)

   -- 恢复挂点原始状态 / 导出 但  不影响  MAX 文件 （多余的操作，挂点归零勾选后的导出进程其实并未作保存max文件的动作，应该属于沉淀代码..实际上有些多余）
fn restoreSocketTransforms originalStates = (
    for stateData in originalStates do (
        local node = stateData[1]
        local state = stateData[2]
        
        if isValidObj node do (
            -- 恢复父对象链接
            node.parent = state[1]
            
            -- 恢复原始变换
            node.transform = state[2]
            
            -- 恢复原始旋转控制器
            node.rotation.controller = state[3]
        )
    )
) 

-- 导出名称的精准调试 /  导出函数 功能 true
fn sanitizeFileName name = (
    -- 替换空格为单下划线
    local cleanName = substituteString name " " "_"
    -- 替换特殊字符为单下划线
    --cleanName = substituteString cleanName "@" "_"
    cleanName = substituteString cleanName "-" "_"
    cleanName = substituteString cleanName ":" "_"
    
    -- 处理连续下划线问题
    while (findString cleanName "__") != undefined do (
        cleanName = substituteString cleanName "__" "_"
    )
    
    -- 移除开头和结尾的下划线
    if cleanName[1] == "_" do cleanName = substring cleanName 2 -1
    if cleanName[cleanName.count] == "_" do cleanName = substring cleanName 1 (cleanName.count-1)
    
    cleanName
)

-- 修改后的 export_file 函数（移除局部 export_segment 定义）
-- 修改后的导出函数（添加选择集有效性检查）
fn export_file fPath objSet targetPath = (
    export_mod_fn rdo_exportMode.state
    
    if not (isValidScene()) do (
        format "[错误] 当前场景无效或未加载\n"
        return false
    )
    
    -- 使用传入的targetPath
    exportDir = targetPath
    makeDir exportDir all:true
    
    -- 按选择集创建子目录
    if auto_makedir_set.checked do (
        exportDir = pathConfig.appendPath exportDir objSet
        makeDir exportDir all:true
    )

    -- 生成安全的文件名
    local baseName = if (maxFileName != "") then (
        getFilenameFile maxFileName
    ) else (
        getFilenameFile fPath
    )
    
    local safeName = sanitizeFileName baseName
    
    -- 最终输出路径
    local outName = exportDir + "\\" + safeName + ".fbx"
    
    try (
        exportFile outName #noPrompt selectedOnly:true using:FBXEXP
        format "[成功导出！] %\n" outName
        true
    ) catch (
        format "[导出失败！！！] %\n" outName
        false
    )
)

-- 根据选择集名称选中对象，并处理挂点归零
fn selectExportobject selste_items = (
    clearSelection()
    local temp_good = false
    local nss = selectionSets[selste_items]

    if nss != undefined do (
        -- 显示隐藏对象
        for i=1 to nss.count do (
            nss[i].isHidden = false
        )
        
        select nss  -- 选中选择集内对象
        max hide inv  -- 隐藏未选中对象
        temp_good = true
    )
    true
    temp_good
)

-- 强化文件加载函数（增加空指针保护）;明确捕获版本兼容性和文件损坏;load_file 函数（移除强制分段数据检查）
fn load_file fpath = (
    local temp_good = false
        if (getFilenameType fpath) == ".max" and doesFileExist fpath do (
            try (
                -- 使用正确的版本获取函数
                local fileVersion = getFileVersion fpath
                if fileVersion != undefined and fileVersion[1] > (maxVersion())[1] do (
                    format "[警告] 文件 % 版本(%)高于当前3ds Max版本(%)\n" fpath fileVersion maxVersion()
                )
                
                resetMaxFile #noPrompt
                loadMaxFile fpath useFileUnits:true quiet:true
                temp_good = true
                
                -- 加载后强制刷新场景数据
                refreshSceneSetsCache()
            ) catch (
                format "[严重错误] 文件加载失败：% (原因：%)\n" fpath (getCurrentException())
                temp_good = false
            )
        )
        temp_good
    )

-- 删除所有对象的动画关键帧
fn delete_all_key = (
    for obj in objects do (
        deleteKeys obj.transform.controller #allKeys
    )
)

-- 清空文件列表并更新UI
fn reset_model_files f_array btn_txt = (
    if f_array.count > 0 do (
        deleteItem f_array 1
        local filestext = ""
        for i in f_array do (filestext += i + "\r\n")
        btn_txt.text = filestext
    )
)

-- 生成FBX文件名（移除特殊字符）
fn GetFbxNameFormMax TempName = (
    local NameCutPos = 0
    for i = TempName.count to 1 by -1 do (
        if TempName[i] == "-" do (
            NameCutPos = i
            exit
        )
    )
    if NameCutPos > 0 then (
        substring TempName 1 (NameCutPos - 1)
    ) else (
        TempName
    )
)
   
-- 右键菜单处理函数--触发max默认弹窗-false--Esc=true
fn AutoExportTool_Pro_leftClickHandler = (
    g_showRecentFiles = false  -- 新增模式重置
    if queryBox "是否立即终止导出进程？" title:"终止确认" beep:false do (
        g_exportAbortFlag = true -- 设置中断标志
    )
) 

-- 按钮动态符号测试-动态更新表情-定义函数
fn updateEmoji state = (
    g_showRecentFiles = false  -- 新增模式重置
    case state of (
        #normal: lbl_01.text = emojiLib[1] + " YQiu_AutoExportTool"
        #hover: lbl_01.text = emojiLib[2] + " YQiu_AutoExportTool"
        #clicked: lbl_01.text = emojiLib[3] + " YQiu_AutoExportTool"
    )
)

-- 文件归档/ - 独立比较函数：按文件修改时间降序排序--沉淀函数（备用）
fn compareFiles a b = (
    local dateA = getFileModDate a  -- 获取文件A修改时间
    local dateB = getFileModDate b  -- 获取文件B修改时间
    dateA > dateB  -- 返回true表示A排在B前（从新到旧）
)

--常用路径相关辅助 文件路径自动粘贴 / btnBrowsePath 鼠标右键 实现 复制 TEXT = 文件目录地址 到 常用路径管理 ROULLOUT 的 目录路径  
-- ===== 常用目录/安全剪贴板操作函数 =====
-- 在复制前处理特殊字符
fn sanitizePathForCmd txt = (
    local sanitized = txt
    
    -- 处理空格
    if findString txt " " != undefined do (
        sanitized = "\"" + txt + "\""
    )
    
    -- 处理特殊符号
    sanitized = substituteString sanitized "&" "^&"
    sanitized = substituteString sanitized "<" "^<"
    sanitized = substituteString sanitized ">" "^>"
    sanitized = substituteString sanitized "|" "^|"
    
    sanitized
)

--常用目录/优化的剪贴板函数（包含版本检测）
fn setClipboardText txt = (
    -- 统一处理特殊字符
    local safeTxt = substituteString txt "\"" "\\\""
    
    -- MAX 2014及更早版本使用CMD方法
    if (maxVersion())[1] < 17000 do (
        try (
            local shell = createOLEObject "WScript.Shell"
            shell.Exec("cmd /c echo " + safeTxt + " | clip")
            return true
        )
        catch (return false)
    )
    
    try (
        -- 高版本优先使用.NET方法
        (dotNetClass "System.Windows.Forms.Clipboard").SetText(safeTxt)
        return true
    )
    catch (
        try (
            -- COM后备方法
            local shell = createOLEObject "WScript.Shell"
            shell.Exec("cmd /c echo " + safeTxt + " | clip")
            return true
        )
        catch (
            format "[错误] 剪贴板写入失败: %\n" (getCurrentException())
            return false
        )
    )
)

-- 批量合并挂点文件//查找对应的CS骨骼 / 改进的骨骼查找函数
fn findCorrespondingBone socketName = (
    local boneName = ""
    local targetBone = undefined
    
    -- 从Socket名称提取骨骼名称（更精确的匹配逻辑）
    case of (
        (matchPattern socketName pattern:"*_Socket"): 
            boneName = substituteString socketName "_Socket" ""
        (matchPattern socketName pattern:"*Socket"): 
            boneName = substituteString socketName "Socket" ""
        (matchPattern socketName pattern:"*挂点*"): 
            boneName = substituteString socketName "挂点" ""
        default: boneName = socketName
    )
    
    -- 清理名称中的多余下划线和空格
    boneName = trimRight (trimLeft boneName)
    boneName = substituteString boneName "__" "_"
    
    -- 优先查找Biped骨骼（BIPED OBJECT类型）
    local bipedBones = for obj in objects where (classOf obj == Biped_Object) collect obj
    
    -- 1. 精确匹配查找（考虑CS骨骼命名规范）
    for bone in bipedBones do (
        local cleanBoneName = bone.name
        -- 移除Bip前缀进行匹配
        if matchPattern cleanBoneName pattern:"Bip001 *" do (
            cleanBoneName = substituteString cleanBoneName "Bip001 " ""
        )
        
        if bone.name == boneName or cleanBoneName == boneName do (
            targetBone = bone
            exit
        )
    )
    
    -- 2. 智能部分匹配（处理常见的CS骨骼命名变体）
    if targetBone == undefined do (
        -- 处理头部相关骨骼
        if matchPattern boneName pattern:"*Head*" then (
            targetBone = getNodeByName "Bip001 Head"
            if targetBone == undefined do targetBone = getNodeByName "Head"
        )
        -- 处理脊柱相关骨骼
        else if matchPattern boneName pattern:"*Spine*" then (
            targetBone = getNodeByName "Bip001 Spine"
            if targetBone == undefined do targetBone = getNodeByName "Bip001 Spine1"
            if targetBone == undefined do targetBone = getNodeByName "Bip001 Spine2"
            if targetBone == undefined do targetBone = getNodeByName "Spine"
        )
        -- 处理骨盆
        else if matchPattern boneName pattern:"*Pelvis*" then (
            targetBone = getNodeByName "Bip001 Pelvis"
            if targetBone == undefined do targetBone = getNodeByName "Pelvis"
        )
        -- 处理四肢
        else if matchPattern boneName pattern:"*Arm*" then (
            if findString boneName "L" != undefined or findString boneName "Left" != undefined then (
                targetBone = getNodeByName "Bip001 L Arm"
                if targetBone == undefined do targetBone = getNodeByName "Bip001 L Forearm"
            )
            else (
                targetBone = getNodeByName "Bip001 R Arm"
                if targetBone == undefined do targetBone = getNodeByName "Bip001 R Forearm"
            )
        )
        else if matchPattern boneName pattern:"*Leg*" then (
            if findString boneName "L" != undefined or findString boneName "Left" != undefined then (
                targetBone = getNodeByName "Bip001 L Leg"
                if targetBone == undefined do targetBone = getNodeByName "Bip001 L Calf"
            )
            else (
                targetBone = getNodeByName "Bip001 R Leg"
                if targetBone == undefined do targetBone = getNodeByName "Bip001 R Calf"
            )
        )
    )
    
    -- 3. 最后尝试名称包含匹配
    if targetBone == undefined do (
        for bone in bipedBones do (
            if findString bone.name boneName != undefined do (
                targetBone = bone
                exit
            )
        )
    )
    
    -- 输出调试信息
    if targetBone != undefined then (
        format "[骨骼匹配] % -> %\n" socketName targetBone.name
    ) else (
        format "[警告] 未找到 % 的对应骨骼\n" socketName
    )
    
    targetBone
)

-- 批量合并挂点文件//对齐挂点到骨骼/改进的对齐挂点到骨骼函数
fn alignSocketToBone socketNode targetBone = (
    if not (isValidNode socketNode and isValidNode targetBone) do return undefined
    
    try (
        -- 检查是否已经是目标骨骼的子级
        if socketNode.parent == targetBone do (
            format "[信息] % 已经是 % 的子级，跳过对齐\n" socketNode.name targetBone.name
            return #(socketNode, targetBone, socketNode.transform, socketNode.parent)
        )
        
        -- 保存原始变换信息
        local originalTransform = socketNode.transform
        local originalParent = socketNode.parent
        
        -- 使用快捷链接插件的对齐逻辑
        -- 1. 先断开当前父级关系
        socketNode.parent = undefined
        
        -- 2. 对齐到目标骨骼的世界变换
        socketNode.transform = targetBone.transform
        
        -- 3. 链接到目标骨骼
        socketNode.parent = targetBone
        
        -- 4. 重置局部变换（使其相对于父骨骼的变换为0）
        in coordsys local (
            socketNode.pos = [0,0,0]
            socketNode.rotation = (quat 0 0 0 1)
        )
        
        format "[对齐成功] % -> %\n" socketNode.name targetBone.name
        
        -- 返回对齐信息
        #(socketNode, targetBone, originalTransform, originalParent)
    )
    catch (
        format "[对齐错误] % -> %: %\n" socketNode.name targetBone.name (getCurrentException())
        
        -- 尝试备用方法：直接使用父级链接而不变换
        try (
            socketNode.parent = targetBone
            format "[备用对齐] 使用简单父级链接: % -> %\n" socketNode.name targetBone.name
            #(socketNode, targetBone, originalTransform, originalParent)
        )
        catch (
            format "[严重错误] 完全无法对齐: %\n" (getCurrentException())
            undefined
        )
    )
)

-- 批量合并挂点文件//恢复挂点原始状态
fn restoreSocketAlignment alignmentInfo = (
    if alignmentInfo == undefined do return false
    
    try (
        local socketNode = alignmentInfo[1]
        local originalTransform = alignmentInfo[3]
        local originalParent = alignmentInfo[4]
        
        if isValidNode socketNode do (
            -- 恢复父级关系
            socketNode.parent = originalParent
            
            -- 恢复变换
            socketNode.transform = originalTransform
        )
        
        true
    )
    catch (
        format "[恢复错误] %: %\n" alignmentInfo[1].name (getCurrentException())
        false
    )
)
-- 批量合并挂点文件//自动处理合并选择集弹窗
fn handleSelectionSetDialogs = (
    try (
        -- 查找并自动处理选择集合并弹窗
        local maxHWND = windows.getMAXHWND()
        local dialog = undefined
        local counter = 0
        
        -- 等待弹窗出现（最多等待2秒）
        while dialog == undefined and counter < 20 do (
            sleep 0.1
            dialog = UIAccessor.FindWindowEx maxHWND 0 "#32770" "重命名合并材质"
            if dialog == undefined do (
                dialog = UIAccessor.FindWindowEx maxHWND 0 "#32770" "合并"
            )
            counter += 1
        )
        
        -- 如果找到弹窗，自动点击"是"或"合并"
        if dialog != undefined do (
            local yesButton = UIAccessor.FindWindowEx dialog 0 "Button" "是(&Y)"
            if yesButton == undefined do yesButton = UIAccessor.FindWindowEx dialog 0 "Button" "合并(&M)"
            
            if yesButton != undefined do (
                UIAccessor.PressButton yesButton
                format "[自动处理] 已处理合并弹窗\n"
            )
        )
    )
    catch (
        format "[弹窗处理错误] %\n" (getCurrentException())
    )
)
-- 批量合并挂点文件//合并文件并处理挂点
fn mergeAndProcessSockets targetFile mergeFile = (
    if not (doesFileExist targetFile and doesFileExist mergeFile) do return false
    
    local success = false
    local alignmentInfos = #()
    
    -- 启用静默模式
    setSilentMode true
    
    try (
        -- 加载目标文件
        if not (loadMaxFile targetFile quiet:true) do (
            format "[错误] 无法加载文件: %\n" targetFile
            return false
        )
        
        -- 获取当前场景中的骨骼
        local sceneBones = for obj in objects where (classOf obj == BoneGeometry or classOf obj == Biped_Object) collect obj
        
        -- 合并文件（使用静默模式）
        local mergeResult = false
        try (
            mergeResult = mergeMaxFile mergeFile #autoRenameDups #useMergedMtlDups #neverReparent quiet:true
        )
        catch (
            -- 如果合并失败，尝试处理弹窗后重试
            handleSelectionSetDialogs()
            sleep 0.5
            try (
                mergeResult = mergeMaxFile mergeFile #autoRenameDups #useMergedMtlDups #neverReparent quiet:true
            )
            catch (
                format "[合并错误] 无法合并文件: %\n" (getCurrentException())
                return false
            )
        )
        
        if not mergeResult do (
            format "[错误] 合并文件失败: %\n" mergeFile
            return false
        )
        
        -- 查找并处理所有挂点
        local socketNodes = for obj in objects where (
            (classOf obj == Dummy or classOf obj == Point) and 
            (matchPattern obj.name pattern:"*Socket*" or matchPattern obj.name pattern:"*socket*" or
             matchPattern obj.name pattern:"*挂点*")
        ) collect obj
        
        format "[挂点检测] 找到 % 个挂点\n" socketNodes.count
        
        -- 处理每个挂点
        for socket in socketNodes do (
            local targetBone = findCorrespondingBone socket.name
            
            if targetBone != undefined then (
                format "[挂点对齐] % -> %\n" socket.name targetBone.name
                local alignmentInfo = alignSocketToBone socket targetBone
                if alignmentInfo != undefined do append alignmentInfos alignmentInfo
            )
            else (
                format "[警告] 未找到 % 的对应骨骼\n" socket.name
            )
        )
        
        -- 保存文件
        saveMaxFile targetFile quiet:true
        success = true
        format "[成功] 处理完成: %\n" targetFile
        
    )
    catch (
        format "[合并错误] %: %\n" targetFile (getCurrentException())
        success = false
    )
    
    -- 恢复正常模式
    setSilentMode false
    
    -- 恢复场景
    resetMaxFile #noPrompt
    
    success
)

-- 批量合并挂点文件//获取合并文件
fn getMergeFileFromList = (
    for i = 0 to (Lv_model.Items.Count - 1) do (
        local item = Lv_model.Items.Item[i]
        local path = item.Tag as String
        
        if doesFileExist path and (
            matchPattern (filenameFromPath path) pattern:"*merge*" or 
            matchPattern (filenameFromPath path) pattern:"*Merge*" or
            matchPattern (getFilenameFile path) pattern:"*挂点*" or
            matchPattern (getFilenameFile path) pattern:"*socket*"
        ) then (
            return path
        )
    )
    
    undefined
)

-- 批量合并挂点文件//主处理函数：批量合并挂点文件
fn batchMergeSocketFiles = (
    -- 检查是否有合并文件
    g_mergeFilePath = getMergeFileFromList()
    
    if g_mergeFilePath == undefined do (
        messageBox "未找到合并文件！\n请确保列表中有包含\"merge\"、\"Merge\"或\"挂点\"字样的文件" title:"错误"
        return false
    )
    
    -- 确认对话框
    local msg = "即将开始批量合并挂点文件！\n\n"
    msg += "合并文件: " + filenameFromPath g_mergeFilePath + "\n"
    msg += "警告: 此操作将直接修改原文件，请确保已备份！\n"
    msg += "是否继续？"
    
    if not (queryBox msg title:"危险操作" beep:true) do return false
    
    -- 获取处理文件列表
    local processFiles = #()
    
    for i = 0 to (Lv_model.Items.Count - 1) do (
        local item = Lv_model.Items.Item[i]
        local path = item.Tag as String
        
        -- 跳过合并文件本身和文件夹
        if path != g_mergeFilePath and not (matchPattern path pattern:"[DIR]*") and 
           doesFileExist path and (getFilenameType path) == ".max" do (
            append processFiles path
        )
    )
    
    if processFiles.count == 0 do (
        messageBox "没有找到需要处理的MAX文件！" title:"操作中止"
        return false
    )
    
    -- 初始化进度
    g_exportAbortFlag = false
    pbProgress.value = 0
    pbProgress.maximum = processFiles.count
    lblProgressInfo.text = "准备开始合并挂点文件..."
    
    local successCount = 0
    local failCount = 0
    
    -- 主处理循环
    for i = 1 to processFiles.count where not g_exportAbortFlag do (
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            lblProgressInfo.text = "用户中断操作！"
            exit
        )
        
        local targetFile = processFiles[i]
        lblProgressInfo.text = "处理中: " + filenameFromPath targetFile + " (" + i as string + "/" + processFiles.count as string + ")"
        
        -- 处理文件
        if mergeAndProcessSockets targetFile g_mergeFilePath then (
            successCount += 1
            format "[成功] %\n" targetFile
        )
        else (
            failCount += 1
            format "[失败] %\n" targetFile
        )
        
        -- 更新进度
        pbProgress.value = i
        windows.processPostedMessages()
        
        -- 内存优化
        if mod i 5 == 0 do (gc(); freeSceneBitmaps())
    )
    
    -- 完成处理
    local resultMsg = "批量合并完成！\n\n"
    resultMsg += "成功: " + successCount as string + " 个文件\n"
    resultMsg += "失败: " + failCount as string + " 个文件\n"
    resultMsg += "合并文件: " + filenameFromPath g_mergeFilePath
    
    lblProgressInfo.text = "批量合并*挂点*文件完成！成功: " + successCount as string + " / 失败: " + failCount as string
    messageBox resultMsg title:"完成"
    
    true
)

-- 批量同步选择集函数 / 同步更新列表文件的选择集 
fn batchSyncSelectionSets = (
    -- 清空监听器信息
    clearListener()
    g_exportAbortFlag = false
    pbProgress.value = 0
    lblProgressInfo.text = "准备开始同步选择集..."
    
    -- 保存当前场景信息（选择集模板文件）
    local templateFile = maxFilePath + maxFileName
    local templateFileName = maxFileName
    
    -- 检查当前场景是否有选择集
    if (getNumNamedSelSets()) == 0 do (
        messageBox "当前场景没有选择集！" title:"操作中止"
        return false
    )
    
    -- 获取处理文件列表（仅MAX文件）
    local processFiles = #()
    for i = 0 to (Lv_model.Items.Count - 1) do (
        local item = Lv_model.Items.Item[i]
        local path = item.Tag as String
        
        -- 跳过文件夹和非MAX文件
        if not (matchPattern path pattern:"[DIR]*") and 
           doesFileExist path and 
           (toLower (getFilenameType path)) == ".max" do (
            append processFiles path
        )
    )
    
    if processFiles.count == 0 do (
        messageBox "没有找到需要处理的MAX文件！" title:"操作中止"
        return false
    )
    
    -- 保存当前选择集到临时XML
    local tempXmlPath = (getDir #temp) + "\\TempSelectionSets.xml"
    local saveSuccess = false
    
    try (
        -- 使用现有的保存函数
        local dotNetXmlDoc = dotNetObject "System.xml.xmlDocument"
        local rootElement = dotNetXmlDoc.createElement "SelectionSet_Tools"
        dotNetXmlDoc.appendChild rootElement

        for s in selectionSets do (
            local setElement = dotNetXmlDoc.createElement "SelectionSet"
            setElement.SetAttribute "SetName" s.name
            rootElement.appendChild setElement

            for o in s do (
                local objElement = dotNetXmlDoc.createElement "ObjectName"
                objElement.InnerText = o.name
                setElement.appendChild objElement
            )
        )
        dotNetXmlDoc.save tempXmlPath
        saveSuccess = true
    )
    catch (
        format "[选择集保存错误] %\n" (getCurrentException())
        saveSuccess = false
    )
    
    if not saveSuccess do (
        messageBox "无法保存当前选择集！" title:"错误"
        return false
    )
    
    -- 确认对话框
    local msg = "即将开始批量同步选择集！\n\n"
    msg += "将影响 " + (processFiles.count as string) + " 个MAX文件\n"
    msg += "警告: 此操作将修改原文件，请确保已备份！\n"
    msg += "是否继续？"
    
    if not (queryBox msg title:"批量同步选择集" beep:true) do (
        deleteFile tempXmlPath  -- 清理临时文件
        return false
    )
    
    -- 设置进度
    pbProgress.maximum = processFiles.count
    local successCount = 0
    local failCount = 0
    local errorFiles = #()  -- 记录出错的文件
    
    -- 存储选择集信息用于最后显示
    local selectionSetNames = #()
    for s in selectionSets do append selectionSetNames s.name
    
    -- 主处理循环 - 使用代码1的稳定逻辑
    for i = 1 to processFiles.count where not g_exportAbortFlag do (
        -- ESC键检测
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            format "[用户中断] 导出进程已被手动终止\n"
            lblProgressInfo.text = "用户中断操作！"
            windows.processPostedMessages()
            messageBox "同步更新选择集进程已被用户中断！" title:"提示"
            exit
        )
        
        local targetFile = processFiles[i]
        lblProgressInfo.text = "选择集/同步中: " + filenameFromPath targetFile + " (" + i as string + "/" + processFiles.count as string + ")"
        
        try (
            -- 保存当前场景状态（如果是已打开的场景）
            local wasDirty = needsSave
            local currentFile = maxFilePath + maxFileName
            
            -- 加载目标文件
            if loadMaxFile targetFile quiet:true then (
                -- 清除现有选择集
                local numSets = getNumNamedSelSets()
                for j = numSets to 1 by -1 do (
                    try (
                        deleteNamedSelSet (getNamedSelSetName j)
                    )
                    catch (
                        format "[清理选择集] 移除: %\n" (getNamedSelSetName j)
                    )
                )
                
                -- 加载选择集
                local dotNetXmlDoc = dotNetObject "System.xml.xmlDocument"
                dotNetXmlDoc.Load tempXmlPath
                local rootElement = dotNetXmlDoc.DocumentElement
                
                if rootElement.name == "SelectionSet_Tools" then (
                    local nodesSelSet = rootElement.ChildNodes
                    
                    for k = 0 to nodesSelSet.count - 1 do (
                        local elemSelSet = nodesSelSet.Item[k]
                        local setName = (elemSelSet.Attributes.GetNamedItem "SetName").value
                        
                        local objNodes = elemSelSet.ChildNodes
                        local objNames = #()
                        
                        for m = 0 to objNodes.count - 1 do (
                            local objElement = objNodes.Item[m]
                            append objNames objElement.InnerText
                        )
               
                        -- 创建选择集（只包含场景中存在的对象）
                        local validObjects = #()
                        for objName in objNames do (
                            local obj = getNodeByName objName
                            if obj != undefined and not isDeleted obj do append validObjects obj
                        )
                        
                        if validObjects.count > 0 do (
                            try (
                                selectionSets[setName] = validObjects
                            )
                            catch (
                                format "[警告] 无法创建选择集: %\n" setName
                            )
                        )
                    )
                    
                    -- 保存文件
                    try (
                        saveMaxFile targetFile
                        successCount += 1
                        format "[成功] 已同步: %\n" targetFile
                    )
                    catch (
                        format "[保存错误] 无法保存: %\n" targetFile
                        append errorFiles #(targetFile, "保存失败")
                        failCount += 1
                    )
                )
                else (
                    format "[错误] 无效的XML格式: %\n" targetFile
                    append errorFiles #(targetFile, "XML格式无效")
                    failCount += 1
                )
                
                -- 重置场景，恢复原始文件
                resetMaxFile #noPrompt
                
                -- 如果之前有打开的文件，重新打开它
                if currentFile != "" and doesFileExist currentFile and wasDirty do (
                    loadMaxFile currentFile quiet:true
                )
            )
            else (
                format "[错误] 无法加载文件: %\n" targetFile
                append errorFiles #(targetFile, "文件无法加载")
                failCount += 1
            )
        )
        catch (
            local errMsg = getCurrentException()
            append errorFiles #(targetFile, errMsg)
            failCount += 1
            
            -- 尝试恢复场景
            try (
                resetMaxFile #noPrompt
                if (maxFilePath + maxFileName) != "" do (
                    loadMaxFile (maxFilePath + maxFileName) quiet:true
                )
            )
            catch ()
        )
        
        -- 更新进度
        pbProgress.value = i
        windows.processPostedMessages()
        
        -- 内存优化
        if mod i 5 == 0 do (
            gc()
            freeSceneBitmaps()
        )
    )
    
    -- 清理临时文件
    try (deleteFile tempXmlPath) catch ()
    
    -- 完成处理，显示详细结果 
    local resultMsg = "批量同步选择集完成！\n\n"
    resultMsg += "处理成功: " + successCount as string + " 个文件\n"
    
    -- 添加选择集信息到结果消息
    if selectionSetNames.count > 0 do (
        resultMsg += "\n同步的选择集:\n"
        for setName in selectionSetNames do (
            resultMsg += "  • " + setName + "\n"
        )
    )
    
    -- 重新打开选择集模板文件
    if templateFile != "" and doesFileExist templateFile do (
        try (
            resetMaxFile #noPrompt
            loadMaxFile templateFile quiet:true
            resultMsg += "\n\n已重新打开选择集模板文件: " + templateFileName
            format "[完成] 已重新打开选择集模板文件: %\n" templateFileName
        )
        catch (
            resultMsg += "\n\n警告: 无法重新打开选择集模板文件: " + templateFileName
            format "[警告] 无法重新打开选择集模板文件: %\n" templateFileName
        )
    )
    
    lblProgressInfo.text = "选择集同步完成！处理成功: " + successCount as string + " 个文件"
    messageBox resultMsg title:"更新完成"

    -- 刷新当前场景的选择集显示
    try (
        if (maxFilePath + maxFileName) != "" do (
            GetSetFormScene()
        )
    ) 
    catch ()
    
    true
)

--合并分段动画
fn mergeSegmentAnimations = (
    g_exportAbortFlag = false
    lblProgressInfo.text = "准备开始合并分段动画..."
    
    -- 获取勾选的文件
    local selectedFiles = #()
    for i = 0 to (Lv_model.Items.Count - 1) do (
        if Lv_model.Items.Item[i].Checked do (
            local path = Lv_model.Items.Item[i].Tag as String
            if not matchPattern path pattern:"*[DIR]*" and (getFilenameType path) == ".max" and doesFileExist path do (
                append selectedFiles path
            )
        )
    )
    
    if selectedFiles.count < 2 do (
        messageBox "请至少勾选2个分段MAX文件进行合并！" title:"操作中止"
        return false
    )
    
    -- 显示确认对话框
    local fileList = ""
    for f in selectedFiles do (
        fileList += filenameFromPath f + "\n"
    )
    
    local msg = "确定要将以下分段文件合并吗？\n\n" + fileList + "\n此操作可能需要一些时间，请耐心等待。"
    if not (queryBox msg title:"确认合并" beep:true) do (
        return false
    )
    
    -- 分析文件名，确定动画顺序
    local animationSegments = #()
    for f in selectedFiles do (
        local fileName = getFilenameFile f
        local segmentType = "middle" -- 默认中间段
        
        case of (
            (findString (toLower fileName) "start" != undefined): segmentType = "start"
            (findString (toLower fileName) "loop" != undefined): segmentType = "loop"
            (findString (toLower fileName) "end" != undefined): segmentType = "end"
        )
        
        append animationSegments #(f, fileName, segmentType)
    )
    
    -- 按类型排序: start -> loop -> end -> middle
    fn segmentSort a b = (
        local typeOrder = #("start", "loop", "end", "middle")
        local aIndex = findItem typeOrder a[3]
        local bIndex = findItem typeOrder b[3]
        
        if aIndex < bIndex then -1
        else if aIndex > bIndex then 1
        else 0
    )
    
    qsort animationSegments segmentSort
    
    -- 创建输出目录
    local baseName = getFilenameFile animationSegments[1][1]
    baseName = substituteString baseName "_start" ""
    baseName = substituteString baseName "_loop" ""
    baseName = substituteString baseName "_end" ""
    baseName = substituteString baseName "start" ""
    baseName = substituteString baseName "loop" ""
    baseName = substituteString baseName "end" ""
    
    local timeStamp = localTime as string
    timeStamp = substituteString timeStamp "/" "-"
    timeStamp = substituteString timeStamp ":" "-"
    local outputDir = pathConfig.appendPath (getDir #scene) ("Merged_" + baseName + "_" + timeStamp)
    local bipDir = pathConfig.appendPath outputDir "BIP"
    local xafDir = pathConfig.appendPath outputDir "XAF"
    makeDir outputDir all:true
    makeDir bipDir all:true
    makeDir xafDir all:true
    
    -- 进度设置 - 修复: 使用正确的.NET属性
    local totalSteps = animationSegments.count * 3 + 2 -- 3步操作: 导出BIP, 导出XAF, 合并 + 保存和清理
    pbProgress.Minimum = 0
    pbProgress.Maximum = totalSteps
    pbProgress.Value = 0
    
    local currentProgress = 0
    local successCount = 0
    
    -- 报告数据
    local reportData = "====== 分段动画合并报告 ======\n"
    reportData += "生成时间: " + localTime as string + "\n"
    reportData += "基础模板: " + baseName + "\n"
    reportData += "合并文件数: " + animationSegments.count as string + "\n\n"
    
    -- 第一步: 导出各分段的BIP和XAF
    local bipFiles = #()
    local xafFiles = #()
    local animationRanges = #()
    
    for i = 1 to animationSegments.count where not g_exportAbortFlag do (
        local segment = animationSegments[i]
        local filePath = segment[1]
        local fileName = segment[2]
        
        lblProgressInfo.text = "处理分段: " + fileName
        
        -- 加载文件
        if loadMaxFile filePath quiet:true do (
            -- 获取动画范围
            local animStart = animationRange.start
            local animEnd = animationRange.end
            
            -- 修复: 使用帧数计算动画长度
            local animLength = (animEnd.frame - animStart.frame) as integer
            append animationRanges #(animStart, animEnd, animLength)
            
            -- 导出BIP
            local bipRoots = for obj in objects where classOf obj == Biped_Object collect obj
            if bipRoots.count > 0 do (
                local bipPath = pathConfig.appendPath bipDir (fileName + ".bip")
                try (
                    biped.saveBipFile bipRoots[1].controller bipPath
                    append bipFiles #(bipPath, animStart, animEnd, animLength)
                    reportData += "BIP导出成功: " + bipPath + "\n"
                ) catch (
                    reportData += "BIP导出失败: " + bipPath + " - " + (getCurrentException()) + "\n"
                )
            )
            
            currentProgress += 1
            -- 修复: 确保进度值不超过最大值
            pbProgress.Value = amin currentProgress totalSteps
            
            -- 导出XAF (附件骨骼)
            try (
                local xafPath = pathConfig.appendPath xafDir (fileName + ".xaf")
                if exportAttachmentBones filePath xafDir do (
                    append xafFiles #(xafPath, animStart, animEnd, animLength)
                    reportData += "XAF导出成功: " + xafPath + "\n"
                )
            ) catch (
                reportData += "XAF导出失败: " + (getCurrentException()) + "\n"
            )
            
            currentProgress += 1
            -- 修复: 确保进度值不超过最大值
            pbProgress.Value = amin currentProgress totalSteps
            
            resetMaxFile #noPrompt
            successCount += 1
        )
        
        currentProgress += 1
        -- 修复: 确保进度值不超过最大值
        pbProgress.Value = amin currentProgress totalSteps
        windows.processPostedMessages()
    )
    
    -- 第二步: 打开第一个分段文件作为模板
    lblProgressInfo.text = "打开模板文件..."
    windows.processPostedMessages()
    
    local templatePath = animationSegments[1][1]
    if not (loadMaxFile templatePath quiet:true) do (
        messageBox "无法打开模板文件！" title:"错误"
        return false
    )
    
    -- 清空当前场景的动画
    lblProgressInfo.text = "清空模板文件动画..."
    windows.processPostedMessages()
    
    -- 清空Biped动画
    local bipRoots = for obj in objects where classOf obj == Biped_Object collect obj
    if bipRoots.count > 0 do (
        local bipRoot = bipRoots[1]
        try (
            -- 删除所有Biped关键帧
            biped.deleteKeys bipRoot.controller #allKeys
            reportData += "已清空Biped动画\n"
        ) catch (
            reportData += "清空Biped动画失败: " + (getCurrentException()) + "\n"
        )
    )
    
    -- 清空骨骼和虚拟体动画
    local boneNodes = for obj in objects where (
        classOf obj == BoneGeometry or 
        classOf obj == Dummy or 
        classOf obj == Point
    ) collect obj
    
    for bone in boneNodes do (
        try (
            deleteKeys bone.controller #allKeys
        ) catch ()
    )
    reportData += "已清空骨骼动画\n"
    
    currentProgress += 1
    -- 修复: 确保进度值不超过最大值
    pbProgress.Value = amin currentProgress totalSteps
    
    -- 第三步: 合并动画到当前场景
    lblProgressInfo.text = "合并动画到模板..."
    windows.processPostedMessages()
    
    -- 查找Biped根节点
    local bipRoot = undefined
    local bipRoots = for obj in objects where classOf obj == Biped_Object collect obj
    if bipRoots.count > 0 do bipRoot = bipRoots[1]
    
    -- 计算总时间范围
    local totalLength = 0
    for range in animationRanges do (
        totalLength += range[3]
    )
    
    -- 设置动画范围
    animationRange = interval 0f (totalLength as time)
    
    -- 合并BIP动画 - 修复: 使用正确的时间设置方法
    local currentFrame = 0
    
    for i = 1 to bipFiles.count do (
        local bipInfo = bipFiles[i]
        local bipPath = bipInfo[1]
        local segLength = bipInfo[4]
        
        if doesFileExist bipPath and bipRoot != undefined do (
            try (
                -- 修复: 使用正确的时间设置方法
                at time (currentFrame as time)
                (
                    -- 加载BIP文件到对应时间范围
                    biped.loadBipFile bipRoot.controller bipPath append:true
                    reportData += "BIP合并成功: " + bipPath + " -> " + (currentFrame as string) + "帧\n"
                    
                    -- 刷新Biped显示
                    biped.update bipRoot #all
                )
            ) catch (
                reportData += "BIP合并失败: " + bipPath + " - " + (getCurrentException()) + "\n"
            )
        )
        
        currentFrame += segLength
    )
    
    -- 合并XAF动画 (如果有)
    if xafFiles.count > 0 do (
        lblProgressInfo.text = "合并附件动画..."
        windows.processPostedMessages()
        
        -- 收集场景中的骨骼和虚拟体
        local boneNodes = for obj in objects where (
            classOf obj == BoneGeometry or 
            classOf obj == Dummy or 
            classOf obj == Point
        ) collect obj
        
        currentFrame = 0
        
        for i = 1 to xafFiles.count do (
            local xafInfo = xafFiles[i]
            local xafPath = xafInfo[1]
            local segLength = xafInfo[4]
            
            if doesFileExist xafPath and boneNodes.count > 0 do (
                try (
                    -- 修复: 使用正确的时间设置方法
                    at time (currentFrame as time)
                    (
                        -- 加载XAF文件
                        LoadSaveAnimation.loadAnimation xafPath boneNodes relative:false insert:false
                        reportData += "XAF合并成功: " + xafPath + "\n"
                    )
                ) catch (
                    reportData += "XAF合并失败: " + xafPath + " - " + (getCurrentException()) + "\n"
                )
            )
            
            currentFrame += segLength
        )
    )
    
    currentProgress += 1
    -- 修复: 确保进度值不超过最大值
    pbProgress.Value = amin currentProgress totalSteps
    
    -- 第四步: 保存合并后的场景
    lblProgressInfo.text = "保存合并文件..."
    windows.processPostedMessages()
    
    -- 修复: 确保文件名正确去除分段标识
    local finalBaseName = baseName
    if matchPattern finalBaseName pattern:"*_Merged" do (
        finalBaseName = substituteString finalBaseName "_Merged" ""
    )
    
    local mergedMaxPath = pathConfig.appendPath outputDir (finalBaseName + "_Merged.max")
    try (
        saveMaxFile mergedMaxPath
        reportData += "\n合并场景保存成功: " + mergedMaxPath + "\n"
        
        -- 验证保存的文件
        if doesFileExist mergedMaxPath then (
            local fileSize = getFileSize mergedMaxPath
            reportData += "文件大小: " + (fileSize as string) + " 字节\n"
        )
    ) catch (
        reportData += "场景保存失败: " + (getCurrentException()) + "\n"
    )
    
    currentProgress += 1
    -- 修复: 确保进度值不超过最大值
    pbProgress.Value = amin currentProgress totalSteps
    
    -- 保存报告
    local reportPath = pathConfig.appendPath outputDir "Merge_Report.txt"
    try (
        local reportFile = createFile reportPath
        format "%" reportData to:reportFile
        close reportFile
    ) catch ()
    
    -- 完成处理
    lblProgressInfo.text = "分段动画合并完成！成功处理 " + successCount as string + " 个文件"
    
    if chk_autoOpenDir.checked do (
        ShellLaunch "explorer.exe" outputDir
    )
    
    -- 显示报告
    messageBox ("合并完成！\n\n已处理: " + successCount as string + " 个文件\n输出目录: " + outputDir) title:"分段动画合并"
    
    true
)


-- 在 rollout 的 on 事件区域添加按钮事件
on btnBatchExportXAFChecked pressed do
(
    batchExportXAFChecked()
)

-- 在AutoExportTool_Pro rollout中添加XAF-编辑/按钮事件处理
on btnBatchExportXAF pressed do (
    g_lastAction = "批量导出XAF"
    updateModeStatus()
    batchExportXAF()
)

on btnBatchImportXAF pressed do (
    g_lastAction = "批量导入XAF"
    updateModeStatus()
    batchImportXAF()
)

on btnOpenXAFEditor pressed do (
    try (
        createDialog rolXAFEditor modal:false
        g_lastAction = "打开XAF编辑器"
        updateModeStatus()
    )
    catch (
        format "[XAF编辑器打开错误] %\n" (getCurrentException())
        messageBox ("无法打开XAF编辑器:\n" + (getCurrentException())) title:"错误"
    )
)

-- 在BIP组按钮事件中添加调用
on btnMergeSegments pressed do (
    g_lastAction = "合并分段动画"
    updateModeStatus()
    mergeSegmentAnimations()
)
-- ===================== 事件处理 =====================
on btnBatchSyncSelSets pressed do (
    g_lastAction = "∥同步-选择集​"
    updateModeStatus()
    batchSyncSelectionSets()
)

-- 合并按钮事件处理
on btnBatchMerge pressed do (
    g_lastAction = "⧺合并-挂点"
    updateModeStatus()
    batchMergeSocketFiles()
)

-- 改名工具的呼出
on btnRenameTool pressed do (try(destroyDialog RenameToolRollout)catch(); createDialog RenameToolRollout)

-- false / 备用 / （ 未验证 ）
on btnCharacterMapping pressed do
(
    g_lastAction = "管理-角色映射"
    updateModeStatus()
    createdialog  rolCharacterMapping pos:mouse.screenpos
)

-- false / 备用 / -- false / 备用 / （ 批量导出-虽然已验证，UI重复-filepath位置占位多余，目前只保留一个必要的保存路径）
on btnBrowseEngine pressed do
(
    local initDir = if g_engineProjectPath != "" then g_engineProjectPath else "C:\\"
    local dir = getSavePath caption:"选择引擎项目目录" initialDir:initDir
    if dir != undefined do (
        edtEnginePath.text = pathConfig.normalizePath dir
        g_engineProjectPath = edtEnginePath.text
    )
)

--  false / 备用方案 ，备用方案 ，需要全局调试 目前 只 支持 批量导出事件按钮 / 已 注销 （感觉UI 布局 多余 ，保存路径也能支持其他路径，只是缺少角色文件夹的映射，目前功能满足基础的批量导出）
on chkExportToEngine changed state do
(
    g_exportToEngine = state
    edtExportPath.enabled = not state
    btnBrowsePath.enabled = not state
    btnOpenExportPath.enabled = not state
    
    if state then (
        lblProgressInfo.text = "导出目标: 引擎项目"
    ) else (
        lblProgressInfo.text = "导出目标: 本地路径"
    )
)

-- 应该是 点击 其他 绑定 点击  事件 - 事件确认 / 结束 编辑状态 
on Lv_model MouseClick e do (
    try(
        --if g_editTextBox = 0  and e.Button == e.Button.Left then 
    --dotNet.addEventHandler e.Button.Left "Click" (fn s e = 
       --createEditTextBox item 
       --finishEditing()
    --)
        -- 如果正在编辑，点击其他地方完成编辑
        if g_editTextBox != undefined and e.Button == e.Button.Left do (
            
            finishEditing()
        )
    ) 
    catch (
        format "[点击事件错误] %\n" (getCurrentException())
    )
)

-- 右键菜单扩展（在空余区域）
on AutoExportTool_Pro rbuttonup pos do (
    -- 创建右键菜单
    local contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
    
    -- 检测更新菜单项（放在最前面）
    local updateText = if g_updateAvailable then "🔄 检测更新 NEW❗ |【CheckUpdate】" else "🔄 检测更新 |【CheckUpdate】"
    local updateItem = contextMenu.Items.Add(updateText)
    updateItem.Image = (dotNetClass "System.Drawing.SystemIcons").WinLogo.ToBitmap()
    dotNet.addEventHandler updateItem "Click" (fn s e = 
        checkForUpdates()
    )
    
    -- 自动更新设置菜单项
local autoUpdateItem = contextMenu.Items.Add("⚙️ 自动检查更新")
autoUpdateItem.Checked = g_autoCheckUpdate
dotNet.addEventHandler autoUpdateItem "Click" (fn s e = (
    g_autoCheckUpdate = not g_autoCheckUpdate
    setINISetting g_UIConfigPath "Settings" "AutoCheckUpdate" (g_autoCheckUpdate as string)
    try (destroyDialog AutoExportTool_Pro) catch()
        fileIn (getSourceFileName())
        createDialog AutoExportTool_Pro
    ))
    -- 不尝试更新当前菜单项状态，下次打开菜单时会正确显示
    -- 不要返回任何值
    -- 分隔线
    contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
    
    -- 帮助菜单
    local helpItem = contextMenu.Items.Add("帮助 |【Help】")
    helpItem.Image = (dotNetClass "System.Drawing.SystemIcons").Question.ToBitmap()
    
    -- 帮助子菜单
    local helpSubMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
    
    local videoTutorialItem = helpSubMenu.Items.Add("视频教程")
    dotNet.addEventHandler videoTutorialItem "Click" (fn s e = 
        openHelpLink "https://space.bilibili.com/327573825"
    )
    
    local helpDocItem = helpSubMenu.Items.Add("帮助文档")
    dotNet.addEventHandler helpDocItem "Click" (fn s e = 
        openHelpLink "https://ladyicefox.github.io/autoexporttool-docs/"
    )
    
    local issueItem = helpSubMenu.Items.Add("问题建议")
    dotNet.addEventHandler issueItem "Click" (fn s e = 
        openHelpLink "https://github.com/ladyicefox/autoexporttool-docs/issues"
    )
    
    helpSubMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
    
    local bilibiliItem = helpSubMenu.Items.Add("📺Bilibili")
    dotNet.addEventHandler bilibiliItem "Click" (fn s e = 
        openHelpLink "https://space.bilibili.com/327573825"
    )
    
    local qqItem = helpSubMenu.Items.Add("🐧Qzone")
    dotNet.addEventHandler qqItem "Click" (fn s e = 
        openHelpLink "https://user.qzone.qq.com/240811498"
    )
    
    helpItem.DropDown = helpSubMenu
    
    -- 分隔线
    contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
    
  -- 添加自启菜单项（带状态标记）
  local autoStartItem = contextMenu.Items.Add("ℵ 是否随3dMax自启 |【Auto-SWMAX】")
  autoStartItem.Checked = g_autoStartEnabled
  dotNet.addEventHandler autoStartItem "Click" (fn s e = (
      toggleAutoStart()
      
  ))

    -- 分隔线
    --contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
 
    -- 添加工具栏菜单（带状态标记）
    local toolbarText = if g_toolbarAdded then "𓀀 工具栏已添加 |【Auto-STBMax】" else "𓀀 工具栏已卸载 |【Auto-Unistalled】"
    local toolbarItem = contextMenu.Items.Add(toolbarText)
    toolbarItem.Checked = g_toolbarAdded

    -- 添加状态图标
    if g_toolbarAdded then (
        toolbarItem.Image = (dotNetClass "System.Drawing.SystemIcons").Shield.ToBitmap()
    ) else (
        toolbarItem.Image = (dotNetClass "System.Drawing.SystemIcons").Warning.ToBitmap()
    )

    -- 工具栏点击处理函数
    fn toolbarClickHandler sender e = (
        if g_toolbarAdded then (
            removeToolbarFromMax()
            sender.Text = "𓀀 工具栏已卸载 |【Auto-Unistalled】"
        ) else (
            addToolbarToMax()
            sender.Text = "𓀀 工具栏已添加 |【Auto-STBMax】"
            
            -- 如果工具栏添加成功，自动开启自启动
            if g_toolbarAdded and not g_autoStartEnabled then (
                toggleAutoStart()
                
                -- 更新自启动菜单项状态（使用遍历查找）
                for i = 0 to (sender.Owner.Items.Count - 1) do (
                    local item = sender.Owner.Items.Item[i]
                    if item.Text == "ℵ 是否随3dMax自启 |【Auto-SWMAX】" then (
                        item.Checked = true
                        exit
                    )
                )
            )
        )
        
        -- 更新勾选状态和图标
        sender.Checked = g_toolbarAdded
        if g_toolbarAdded then (
            sender.Image = (dotNetClass "System.Drawing.SystemIcons").Shield.ToBitmap()
        ) else (
            sender.Image = (dotNetClass "System.Drawing.SystemIcons").Warning.ToBitmap()
        )
    )
    
    -- 添加事件处理
    dotNet.addEventHandler toolbarItem "Click" toolbarClickHandler

    -- 分隔线
    contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
    
    -- 添加重启插件项
    local restartItem = contextMenu.Items.Add("🔄​​​​ 重启插件 |【Auto-RSTool】")
    restartItem.Image = (dotNetClass "System.Drawing.SystemIcons").Information.ToBitmap()
    dotNet.addEventHandler restartItem "Click" (fn s e = (
        try (destroyDialog AutoExportTool_Pro) catch()
        fileIn (getSourceFileName())
        createDialog AutoExportTool_Pro
    ))
    
    
    -- 分隔符
    contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
    
    
    -- 关闭菜单
    local closeItem = contextMenu.Items.Add("📛 关闭工具 |【CloseTool】")
    closeItem.Image = (dotNetClass "System.Drawing.SystemIcons").Error.ToBitmap()
    dotNet.addEventHandler closeItem "Click" (fn s e = 
        try (destroyDialog AutoExportTool_Pro) catch()
    )
    -- 分隔符
    contextMenu.Items.Add((dotNetObject "System.Windows.Forms.ToolStripSeparator"))
        
    -- 关于菜单项
    local aboutItem = contextMenu.Items.Add("ℹ️ 关于")
    aboutItem.Image = (dotNetClass "System.Drawing.SystemIcons").Information.ToBitmap()
    dotNet.addEventHandler aboutItem "Click" (fn s e = 
        messageBox ("AutoExportTool Pro\n版本: v" + g_currentVersion + "\n作者: 叶秋") title:"关于"
    )
    
    -- 显示菜单
    contextMenu.Show (mouse.screenPos[1]) (mouse.screenPos[2])
)

-- 版本管理按钮事件/max版本管理/事件 / false / 备用
--on btnVersionManager pressed do (
    --try(destroyDialog rolVersionManager)catch()
    --createDialog rolVersionManager pos:mouse.screenpos style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
--)

-- ============================窗口拖动功能==================================

         -- ====== 纯 MaxScript 拖动实现 / 安全的事件处理 ====== 

on lblDragArea mousedown pos do
        (
            try (
                dragging = true
                dragStartPos = mouse.screenPos
                windowStartPos = getDialogPos AutoExportTool_Pro
            ) catch (
                dragging = false
            )
        )
        
on lblDragArea mousemove pos do
        (
            if dragging do
            (
                try (
                    -- 安全获取鼠标位置
                    local currentPos = [0,0]
                    if classof mouse == Point2 then currentPos = mouse.screenPos
                    
                    -- 安全计算新位置
                    local delta = currentPos - dragStartPos
                    local newPos = windowStartPos + delta
                    
                    -- 安全设置窗口位置
                    if isValidPos newPos do
                    (
                        setDialogPos AutoExportTool_Pro newPos
                    )
                ) catch (
                    dragging = false
                )
            )
        )
        
on lblDragArea mouseup pos do
        (
            dragging = false
        )
        
-- 辅助函数：检查位置是否有效
fn isValidPos pos =
(
    try (
        return classof pos == Point2 and pos.x > -10000 and pos.y > -10000 and pos.x < 10000 and pos.y < 10000
    ) catch (
        return false
    )
)
 
-- ====== 纯 DotNet 拖动实现  ====== （ 功能验证实现 / true ,有缺陷,主屏拖动问题不大；分屏不实时，有乱动现象 / 可优化  )
on lblTitle MouseDown arg do
    (
        
        g_dragging = true
        g_dragStartPos = mouse.screenPos
        
)

on lblTitle MouseMove arg do
    (
        if g_dragging and arg.button == arg.button.left then
        (
            local currentPos = mouse.screenPos
            local delta = currentPos - g_dragStartPos
            setDialogPos AutoExportTool_Pro (getDialogPos AutoExportTool_Pro + delta)
            g_dragStartPos = currentPos
        )
    )
    
on lblTitle MouseUp arg do
    (
        g_dragging = false
    )
    

-- ==========================================================================
-- 关闭插件 / 主插件标题抬头 add + 关闭插件按钮 / true ( 无边框模式 加个 关闭 模拟一下关闭，可点击 关闭..)
on btnClose pressed do 
 (
     destroyDialog AutoExportTool_Pro
 )

 -- ==========================================================================

 -- 重启插件/按钮点击事件
on btnRestartPlugin pressed do (
    g_lastAction = "​​⏻​插件-重启"
    updateModeStatus()
    restartPlugin()
)
-- 按钮事件处理- 新增独立刷新列表
on btnRefreshList pressed do (
    g_lastAction = "↻列表-刷新"
    updateModeStatus()
    local currentPath = edtExportPath.text -- 保持当前路径不变
    if doesDirectoryExist currentPath do (
        edtExportPath.text = currentPath -- 显式重置确保路径一致
        refreshFileListView forceRefresh:true
        format "[刷新] 路径：%\n" currentPath
    )
)
-- 按钮事件处理（完整修复版）// 事件 / false (失效/未实现)
on btnCleanRecent pressed do (  -- 左键处理
    if queryBox "是否设置最近文件显示数量为10个？\n(立即生效)" title:"设置" beep:false do (
        if setMaxRecentFileCountImmediately 10 do (
            messageBox "最近文件显示数量已设置为10个" title:"操作成功"
        )
    )
)
--最近文件 清理 重置记录文档 / 事件 / 实测 max 2022 生效 - false(部分版本不支持 比如 MAX 2019！！！) 
on btnCleanRecent rightclick do (  -- 右键处理
    if keyboard.controlPressed then (  -- Ctrl+右键：刷新列表
        refreshFileListView forceRefresh:true
    ) else (  -- 普通右键：清空记录
        if queryBox "是否彻底清空所有最近文件记录？\n(包括内存和文件存储)" title:"危险操作" beep:true do (
            if clearRecentFilesCompletely() do (
                Lv_model.Items.Clear()
                lblCount.text = "文件：0"
                messageBox "最近文件记录已彻底清空！" title:"完成"
            )
        )
    )
)

--新增旋转模式开关和排除前缀输入框/相关事件
on chk_useRotation changed state do (
    g_useCustomRotation = state
    rdo_rotation.visible = state
)
--新增 XAF 导出 数据属性 tcb / euler--/勾选/事件
on rdo_rotation changed state do (
    g_rotationMode = if state == 1 then #tcb else #euler
)
-- 新增 XAF / 相关/事件
on edt_excludePrefix entered text do (
    g_excludePrefix = text
)

--新增文件归档按钮（功能：按文件名和时间筛选最新版本文件，自动归档）/事件
on btnArchive pressed do (
    g_lastAction = "文件-归档"
    updateModeStatus()
    
    try (
        -- 1. 创建归档目录
        local currentPath = pathConfig.normalizePath edtExportPath.text
        local timeArray = getLocalTime()  -- 获取当前时间
        local dateStamp = formattedPrint timeArray[1] format:"04d" +  
                          formattedPrint timeArray[2] format:"02d" +   
                          formattedPrint timeArray[4] format:"02d"      
        local archiveDirName = "文件归档_" + dateStamp                  
        local archiveDir = pathConfig.appendPath currentPath archiveDirName
        
        -- 检查并删除已存在的当天归档文件夹
        if doesDirectoryExist archiveDir do (
            try (
                -- 使用DOS命令强制删除文件夹及其内容
                local cmd = "cmd /c rmdir /s /q \"" + archiveDir + "\""
                hiddenDOSCommand cmd
                format "[归档] 删除已存在的归档目录: %\n" archiveDir
            )
            catch (
                format "[归档错误] 无法删除现有目录: %\n" (getCurrentException())
                messageBox "无法删除现有归档目录，请手动删除后重试" title:"错误"
                return false
            )
        )
        
        -- 创建新的归档目录
        makeDir archiveDir all:true
        format "[归档] 创建新归档目录: %\n" archiveDir
        
        lblProgressInfo.text = "正在分析文件版本..."
        windows.processPostedMessages()
        
        -- 2. 智能版本检测
        local fileGroups = #()
        
        -- 文件名解析函数
        fn parseVersion fName = (
            local parts = filterString fName "_"
            if parts.count > 1 and (matchPattern parts[parts.count] pattern:"v??") then (
                local verPart = parts[parts.count]
                local numStr = substring verPart 2 -1
                
                -- 构建基础名称
                local baseParts = for i=1 to parts.count-1 collect parts[i]
                local baseName = ""
                for p in baseParts do baseName += p + (if p != baseParts[baseParts.count] then "_" else "")
                baseName = trimRight baseName "_ "
                
                -- 验证数字有效性
                if numStr as integer != undefined then (
                    return #(baseName, numStr as integer)
                )
            )
            #(fName, 0) -- 无版本信息返回0
        )
        
        -- 分组处理逻辑
        for f in model_files_array where (getFilenameType f == ".max") do (
            local fName = getFilenameFile f
            local parsed = parseVersion fName
            local found = false
            
            -- 查找或创建分组
            for group in fileGroups where group.baseName == parsed[1] do (
                found = true
                if parsed[2] > group.maxNumber then (
                    group.maxNumber = parsed[2]
                    group.latestFile = f
                )
                if parsed[2] == 0 do group.originalFile = f
                exit
            )
            
            if not found do (
                local newGroup = FileGroup \
                    baseName:parsed[1] \
                    originalFile:(if parsed[2]==0 then f else undefined) \
                    latestFile:(if parsed[2]>0 then f else undefined) \
                    maxNumber:parsed[2]
                append fileGroups newGroup
            )
        )
        
        -- 2.5 新增日期后缀处理函数
        fn addDateSuffix baseName = (
            -- 移除旧日期后缀（如果存在）
            if matchPattern baseName pattern:"*-??-?-?" do (
                local parts = filterString baseName "-"
                if parts.count >= 3 and \
                   isKindOf (parts[parts.count-2] as integer) Number and \
                   isKindOf (parts[parts.count-1] as integer) Number and \
                   isKindOf (parts[parts.count] as integer) Number do (
                    baseName = ""
                    for i=1 to (parts.count-3) do (
                        baseName += parts[i]
                        if i < (parts.count-3) do baseName += "-"
                    )
                )
            )
            
            -- 添加新日期后缀
            local t = getLocalTime()  -- 在函数内部获取时间
            baseName += "-" + (formattedPrint (t[1]-2000) format:"02d") + "-" + \
                         (formattedPrint t[2] format:"02d") + "-" + \
                         (formattedPrint t[4] format:"02d")
            return baseName
        )
        
        -- 3. 安全复制文件（添加日期后缀处理）
        local copyCount = 0
        local failedCount = 0
        
        for group in fileGroups do (
            -- 复制原始文件
            if group.originalFile != undefined and doesFileExist group.originalFile do (
                local baseName = getFilenameFile group.originalFile
                local ext = getFilenameType group.originalFile
                
                -- 添加日期后缀（如果勾选）
                if chkAddDateSuffix.checked do baseName = addDateSuffix baseName
                
                local target = archiveDir + "\\" + baseName + ext
                if copyFile group.originalFile target then (
                    copyCount += 1
                ) else (
                    failedCount += 1
                    format "[归档错误] 无法复制文件: % -> %\n" group.originalFile target
                )
            )
            
            -- 复制最新版本
            if group.latestFile != undefined and doesFileExist group.latestFile do (
                local baseName = getFilenameFile group.latestFile
                local ext = getFilenameType group.latestFile
                
                -- 添加日期后缀（如果勾选）
                if chkAddDateSuffix.checked do baseName = addDateSuffix baseName
                
                local target = archiveDir + "\\" + baseName + ext
                if copyFile group.latestFile target then (
                    copyCount += 1
                ) else (
                    failedCount += 1
                    format "[归档错误] 无法复制文件: % -> %\n" group.latestFile target
                )
            )
        )
        
        -- 4. 处理非版本文件（添加日期后缀处理）
        for f in model_files_array where (getFilenameType f == ".max") do (
            local isVersioned = false
            for group in fileGroups do (
                if findItem #(group.originalFile, group.latestFile) f > 0 do (
                    isVersioned = true
                    exit
                )
            )
            if not isVersioned and doesFileExist f do (
                local baseName = getFilenameFile f
                local ext = getFilenameType f
                
                -- 添加日期后缀（如果勾选）
                if chkAddDateSuffix.checked do baseName = addDateSuffix baseName
                
                local target = archiveDir + "\\" + baseName + ext
                if copyFile f target then (
                    copyCount += 1
                ) else (
                    failedCount += 1
                    format "[归档错误] 无法复制文件: % -> %\n" f target
                )
            )
        )
        
        -- 刷新文件列表
        AutoExportTool_Pro.refreshFileListView()
        
        -- 完成反馈
        ShellLaunch "explorer.exe" archiveDir
        
        local resultMsg = "文件归档完成！成功复制: " + copyCount as string + " 个文件"
        if failedCount > 0 do resultMsg += "，失败: " + failedCount as string + " 个文件"
        
        lblProgressInfo.text = resultMsg
        
        if failedCount == 0 then (
            messageBox (resultMsg + "\n位置: " + archiveDir) title:"操作完成" beep:false
        ) else (
            messageBox (resultMsg + "\n请检查文件权限或磁盘空间") title:"操作完成(部分失败)" beep:true
        )
        
    ) catch (
        format "[归档错误] %\n" (getCurrentException())
        messageBox ("归档过程中发生错误: " + (getCurrentException())) title:"错误" beep:true
    )
)

--功能：手动清理场景冗余资源，释放内存
on btnGC pressed do (
    g_lastAction = "清理-场景！！！"
    updateModeStatus()
    -- 执行全面清理
    disableSceneRedraw()
    gc()          -- 垃圾回收
    freeSceneBitmaps()  -- 释放贴图内存
    enableSceneRedraw()
    completeRedraw()
    lblProgressInfo.text = "当前场景清理完成！！！" 
    messageBox "场景资源已清理！" title:"GC完成" beep:false
)

--lv-列表/恢复初始CP-颜色/显示控制
on btnResetColor pressed do (
    g_lastAction = "��始CP-颜色"
    updateModeStatus()
    cpFolder.color = color 245 245 125
    cpFile.color = color 255 255 255
    
    --Lv_model.Font = dotNetObject "System.Drawing.Font" "微软雅黑" 8 ((dotNetClass "System.Drawing.FontStyle").Bold)
)
----------------------------------------------------------------
--on cpGridLine changed newColor do (
    --g_gridLineColor = (dotNetClass "System.Drawing.Color").FromArgb newColor.r newColor.g newColor.b
--)
----------------------------------------------------------------
--lv-列表/网格线/显示控制
on chkGridLines changed state do (
    g_lastAction = "网格线/显示"
    updateModeStatus()
    Lv_model.GridLines = state
	--Lv_model.Font = dotNetObject "System.Drawing.Font" "宋体" 10 ((dotNetClass "System.Drawing.FontStyle").Regular)
    Lv_model.Refresh()
    --saveUIConfig() -- 实时保存状态
)

-- lv-列表//勾选框事件处理-修改字体切换事件
on chkChangeFont changed state do (
    g_lastAction = "切换-字体!!!"
    updateModeStatus()
    Lv_model.Font = if state then g_alternateFont else g_defaultFont   
	g_forceCustomLayout = state -- 更新全局状态
    -- 更新lvHeader列宽
    local targetTypeWidth = if state then 145 else 125
    lvHeader.Columns.Item[2].Width = targetTypeWidth  -- 第三列宽度
    
    lvHeader.Columns.Item[2].Width = if state then 145 else 125  -- 第三列
    
    lvHeader.Refresh()
	
	adjustColumnWidths forceCustom:state -- 立即应用新布局
)

-- 在 edtPathDir 的 entered 事件中添加
on edtPathDir entered txt do (
    
    updateModeStatus()  -- 统一调用状态更新

    if not doesDirectoryExist txt do (
        messageBox "路径无效或不可访问！" title:"输入错误"
        edtPathDir.text = getDir #scene
    )
)
--恢复默认路径
on btnResetPath pressed do (
	g_lastAction = "路径-恢复"
    updateModeStatus()  -- 统一调用状态更新
    local currentDir = maxFilePath
 
    -- 去除路径末尾的反斜杠（如果存在��
    if currentDir != "" and currentDir[currentDir.count] == "\\" do (
        currentDir = substring currentDir 1 (currentDir.count - 1)
    )
    edtExportPath.text = getDir #scene
    edtExportPath.text = currentDir
    refreshFileListView()
g_showRecentFiles = false
)

-- 修改文件计数标签的更新逻辑（双向同步）
on lblCount text changed newText do (
    try (
        if ModeStatus.Items.Count > 0 do (
            local item = ModeStatus.Items.Item[0]
            item.SubItems[2].Text = newText
            ModeStatus.Refresh()
        )
    ) catch (
        format "[状态同步错误] %\n" (getCurrentException())
    )
)

-- 在模式切换事件中更新
on rdo_exportMode changed state do (
    g_lastAction = "切换-导出模式"
    updateModeStatus()  -- 统一调用状态更新
)

-- 滑条值改变事件
on sldBgColor changed val do (
    g_lastAction = "灰度值-调整"
    updateModeStatus()
    -- 实时显示当前值
    format "[Slider Changed] Value: %\n" val
    lblBgValue.text = val as string
    Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb val val val
    saveUIConfig()  -- 立即保存
)

-- BIP模式切换事件2 ==================================================
on rdo_bipMode changed state do (
    
    updateModeStatus()  -- 统一调用状态更新
    
    -- BIP相关逻辑2
    g_bipProcessMode = state
    -- 仅同步文件类型过滤，不修改路径
    case state of (
        1: ( -- 导出模式显示MAX文件
            rdoFileFilter.state = 1  -- 对应MAX单选按钮
            currentFilter = "*.max"
            --return undefined -- 阻止后续刷新
        )
        2: ( -- 导入模式显示BIP文件
            rdoFileFilter.state = 4  -- 假设BIP是第四个单选按钮
            currentFilter = "*.bip"
            --return undefined -- 阻止后续刷新
        )
        
    )
    --Lv_model.Items.Clear()
    --model_files_array = #()
    
    if not g_showRecentFiles do (
    -- 强制刷新列表
    refreshFileListView forceRefresh:true
    format "[Bip-模式切换] 过滤类型：%\n" currentFilter
)
   if g_showRecentFiles do (
    return undefined )-- 阻止后续刷新///不作刷新//refreshFileListView forceRefresh:true//-最近打开文件模式下-刷新会列表刷新异常
)

-- 颜色应用事件
on btnApplyColor pressed do (
    g_lastAction = "应用颜色-cp"
    updateModeStatus()
    try (
        -- [1/4] 保存当前颜色配置
        g_ColorConfig.folderNameColor = (dotNetClass "System.Drawing.Color").FromArgb cpFolder.color.r cpFolder.color.g cpFolder.color.b
        g_ColorConfig.fileNameColor = (dotNetClass "System.Drawing.Color").FromArgb cpFile.color.r cpFile.color.g cpFile.color.b
        
        -- [2/4] 模式状态保持
        local isRecentMode = g_showRecentFiles

-- 如果当前为最近模式，切换到标准模式并初始化列表

        if isRecentMode do (
             --start_Lv_model()
             g_showRecentFiles = true 
             --Lv_model.GridLines = false
             -- [3/4] 物理按钮模拟
            if classOf btnRecentFiles == RolloutClass do (
                -- 视觉反馈
                btnRecentFiles.states.pressed = true
                redrawViews()
                sleep 0.1
                
                -- 实际执行
                btnRecentFiles.states.pressed = false
                btnRecentFiles.pressed()
            )
        )
        
        /* 智能刷新逻辑
        - 若从最近模式切换过来：用标准模式刷新
        - 若原本就是标准模式：正常刷新
        - 在最近模式不主动刷新（通过条件避免）
    */
    if not isRecentMode do (
        refreshFileListView forceRefresh:true  -- 标准模式强制刷新
    )
    
    -- 特殊处理：若原为最近模式，刷新后恢复状态
    if isRecentMode do (
        g_showRecentFiles = true  -- 恢复最近模式标记
            -- 更新颜色配置（无论当前模式）

        --refreshFileListView forceRefresh:false  -- 软刷新保持界面元素  -  false 
    )
        
        Lv_model.Refresh()
    	updateModeStatus() -- 新增
	    windows.processPostedMessages() -- 关键
	) catch (
        format "[严重错误] 颜色应用失败: %\n" (getCurrentException())
    )
)

-- 新增事件处理：返回上一层目录
on btnParentPath pressed do (
    g_lastAction = "↩文件返回"
    updateModeStatus()
    local currentPath = edtExportPath.text
    if currentPath == "" do (
        edtExportPath.text = getDir #scene
        refreshFileListView()
        return undefined
        updateModeStatus() -- 新增
        sleep 0.05 -- 50ms延迟确保操作完成
    )
    
    -- 新增路径存在性验证
    if not doesDirectoryExist currentPath do (
        --messageBox "路径不存在，已重置为默认目录！" title:"路径错误"
        edtExportPath.text = getDir #scene
        refreshFileListView()
        
		updateModeStatus() -- 新增
	    windows.processPostedMessages() -- 关键
		return undefined
    )
    
    -- 获取父目录并检查是否为根目录
    local parentPath = pathConfig.normalizePath (pathConfig.removePathLeaf currentPath)
    
    -- 若当前路径是根目录，则跳转到循环路径
    if parentPath == currentPath do (
        if doesDirectoryExist g_cyclePath do (
            edtExportPath.text = g_cyclePath
            refreshFileListView()
            return undefined
        )
        -- 若循环路径无效则重置为场景目录
        edtExportPath.text = getDir #scene
        refreshFileListView()
        return undefined
    )
    
    -- 更新循环路径为当前路径
    g_cyclePath = currentPath
    
    -- 正常返回上一层
    edtExportPath.text = parentPath
    chkAutoFolder.checked = false
    g_showRecentFiles = false
    refreshFileListView()
    format "[路径更新] 切换到父目录：%\n" parentPath
) 
    
-- 新增按钮1：一键添加所有选择集（带场景检查）

-- 修改 btnRecentFiles 的 pressed 事件处理

on btnRecentFiles pressed do (
    g_lastAction = "↩️最近打开"
    updateModeStatus()
    g_showRecentFiles = true
    rdoFileFilter.state = 1
    local validFiles = loadRecentFilesFromXML()
    
    model_files_array = #()
    Lv_model.Items.Clear()
    
    Lv_model.BeginUpdate()
    local existCount = 0
    for entry in validFiles do (
        local fPath = entry[1]
        local exists = entry[2]
        
        append model_files_array fPath
        
        li = dotNetObject "System.Windows.Forms.ListViewItem" ""
        li.UseItemStyleForSubItems = false
        
        -- 图标列
        li.Text = if exists then "📄" else "✘"
        li.ForeColor = (dotNetClass "System.Drawing.Color").White  -- 图标始终白色
        
        -- 文件名列
        local subName = li.SubItems.Add(filenameFromPath fPath)
        subName.ForeColor = if exists then g_ColorConfig.fileNameColor else (dotNetClass "System.Drawing.Color").Red
        
        -- 类型列
        local typeColor = if exists then g_ColorConfig.fileNameColor else (dotNetClass "System.Drawing.Color").Red
        local typeInfo = if exists then (getFileType fPath) else "<<失效文件>>"
        local subType = li.SubItems.Add(typeInfo)
        subType.ForeColor = typeColor
        
        li.Tag = fPath
        Lv_model.Items.Add(li)
        
        if exists do existCount += 1
    )
    Lv_model.EndUpdate()
    -- 新增：最近文件模式特殊处理
    Lv_model.Scrollable = false
    Lv_model.Scrollable = true -- 仅垂直
    -- 更新统计信息
    lblCount.text = "文件：" + (validFiles.count - (validFiles.count - existCount)) as string + "/" + validFiles.count as string
    edtExportPath.text = "最近文件（有效：" + existCount as string + " 失效：" + (validFiles.count - existCount) as string + "）"
    Lv_model.Refresh()
    updateModeStatus()
    -- 新增：特殊列宽计算
    -- 新增：自动保存模式特殊处理
    
    if chkChangeFont.checked do (
        if g_showRecentFiles do (
            local safeWidth = Lv_model.ClientRectangle.Width - 17 -- 扣除垂直滚动条
            Lv_model.Columns.Item[1].Width = safeWidth - 105 -- 文件名列动态计算
            
            -- 强制禁用水平滚动
            Lv_model.Scrollable = false
            Lv_model.Scrollable = true -- 仅垂直滚动
            return undefined -- 跳过常规计算
            )
    adjustColumnWidths forceCustom:chkChangeFont.checked -- 携带字体状态
    adjustColumnWidths()
    )
)

--on btnRecentFiles pressed do (
    --g_showRecentFiles = true
    --local validFiles = loadRecentFilesFromXML()
    
    --model_files_array = #()  -- 清空数据源
    --Lv_model.Items.Clear()   -- 直接清除列表项
    
    --local existCount = 0  -- 独立有效计数器
    --for entry in validFiles do (
        --local fPath = entry[1]
        --local exists = entry[2]
        
        --append model_files_array fPath  -- 保持原始数据完整
        
        -- 创建列表项（保持原有逻辑）
        --li = dotNetObject "System.Windows.Forms.ListViewItem" ""
        --li.Text = if exists then "📄" else "✘"
        --li.SubItems.Add(filenameFromPath fPath)
        --li.SubItems.Add((if exists then "最近文件 - " else "失效文件 - ") + getFileType fPath)
        --li.ForeColor = if exists then g_ColorConfig.fileNameColor else (dotNetClass "System.Drawing.Color").Red
        --Lv_model.Items.Add(li)
        
        --if exists do existCount += 1
    --)
    
    -- 修改点：直接设置计数，不依赖updateModeStatus
    --lblCount.text = "文件：" + existCount as string
    --edtExportPath.text = "最近打开（有效文件：" + existCount as string + "）"
    
    -- 手动触发状态栏更新
    --updateModeStatus()
--)
-- 修正控件事件绑定
on rdoFileFilter changed state do (
    g_lastAction = "File-筛选.."
    updateModeStatus()
    if g_showRecentFiles do (
        --messageBox "最近打开模式下不可切换文件类型!" title:"提示"
        rdoFileFilter.state = 1
        return undefined
    )
    refreshFileListView()
	updateModeStatus() -- 新增
	windows.processPostedMessages() -- 关键！
)

-- 保存路径TEXT 更改 / 触发列表刷新
on edtExportPath entered txt do refreshFileListView()

-- 自动记忆上次使用的路径
on edtExportPath changed text do (
    setINISetting g_ConfigPath "Paths" "LastExportPath" text
)

-- 修复插件目录序号显示问题 左键 主 MAX 插件位置 //在按钮事件处理部分添加右键功能 - 8.18
on btnPluginDir pressed do (
    g_lastAction = "📦插件目录"
    updateModeStatus()
    g_showRecentFiles = false  -- 新增模式重置
    local scriptDir = pathConfig.appendPath (getDir #maxroot) "scripts"
    edtExportPath.text = scriptDir
    rdoFileFilter.state = 3 -- 切换到MS类型
    Lv_model.Scrollable = false -- 
    Lv_model.Scrollable = true -- 允许垂直滚动
    -- 挂起布局防止闪烁 --
    Lv_model.SuspendLayout()
    -- 恢复布局并刷新 --
    Lv_model.ResumeLayout()
    refreshFileListView() -- 直接调用刷新
	-- 滚动条控制 --
    Lv_model.Scrollable = (Lv_model.Items.Count * 20 > Lv_model.Height)  -- 动态垂直滚动
    -- 最终布局验证 --
    Lv_model.PerformLayout()
    -- 状态同步 --
    updateModeStatus() -- 新增
	windows.processPostedMessages() -- 关键！

)

--右键 - 导航到备份目录 / 8.18
on btnPluginDir rightclick do ( 
    g_lastAction = "📦备份目录"
    updateModeStatus()
    g_showRecentFiles = false  -- 新增模式重置
    
    -- 获取正确的备份目录（去掉文件名部分）
    local backupDir = g_backupPluginPath1
    --local backupDir = getFilenamePath g_backupPluginPath1
    -- 确保备份目录存在
    makeDir backupDir all:true
    
    -- 设置路径并刷新
    edtExportPath.text = backupDir
    rdoFileFilter.state = 7 -- MS类型
    refreshFileListView() 
    
    -- 更新状态
    updateModeStatus()
    windows.processPostedMessages()
)

--新增按钮事件-点击刷新自动保存文件
on btnAutoSave pressed do (
    g_lastAction = "💾自动保存"
    updateModeStatus()
    g_showRecentFiles = false  -- 新增模式重置
    -- 设置路径显示为自动保存目录
    edtExportPath.text = g_autoSavePath
    
    -- 清空当前列表
    Lv_model.Items.Clear()
    model_files_array = #()
    rdoFileFilter.state = 1 -- 切换到MAX类型
    -- 挂起布局防止闪烁 --
    Lv_model.SuspendLayout()
    -- 获取自动保存目录下的所有.max文件
    --local autoSaveFiles = getFiles (pathConfig.appendPath g_autoSavePath "*.max")
    -- 恢复布局并刷新 --
    Lv_model.ResumeLayout()
    refreshFileListView() -- 直接调用刷新函数
	-- 滚动条控制 --
    Lv_model.Scrollable = (Lv_model.Items.Count * 20 > Lv_model.Height)  -- 动态垂直滚动
    -- 最终布局验证 --
    Lv_model.PerformLayout()
    -- 状态同步 --
    updateModeStatus() -- 新增
	windows.processPostedMessages() -- 关键！

)

-- 新增按钮事件--选择集管理
on btnSelSetManager pressed do (
    try(createdialog rolSelSetTools pos:[mouse.screenpos.x+50,mouse.screenpos.y])catch()
)

-- 事件处理
--按钮动态符号测试--动态更新表情- 绑定事件
on lbl_01 mouseOver do updateEmoji #hover
on lbl_01 mouseOut do updateEmoji #normal
on lbl_01 clicked do updateEmoji #clicked

--...
on ddlLikedFolder selected id do (
    g_lastAction = "常用-Selete.."
    updateModeStatus()
    g_showRecentFiles = false
    if iniLikedFolder[id] != undefined do (
        strDir = iniLikedFolder[id].dir
        fnRefreshList strDir type:arrFileType[rdoFileType.state]
    )
)

-- 右击删除项
on ddlLikedFolder rightclick do (
    if ddlLikedFolder.selection > 0 and ddlLikedFolder.items.count > 0 do (
        deleteItem iniLikedFolder ddlLikedFolder.selection
        fnRefLikedFolderItems()  -- 刷新下拉列表
        stSetConfigAll.fnSetConfigBsOpenTools()
    )
)
  
--常用目录-Main / 优化pos,重试，操作感官
on btnManagePaths pressed do (
    g_lastAction = "管理-常用目录"
    updateModeStatus()
    
    -- 刷新下拉列表
    ddlLikedPaths.items = for f in g_likedFolders collect f.name
    
    -- 计算对话框位置（确保在屏幕内）
    local dialogPos = mouse.screenPos - [150, 75]
    dialogPos.x = amax 0 (amin dialogPos.x (sysInfo.desktopSize.x - 300))
    dialogPos.y = amax 0 (amin dialogPos.y (sysInfo.desktopSize.y - 130))
    -- step1:关闭已存在的对话框（防止重复/通过步骤消除-路径管理界面遮挡）
    try (destroydialog rolPathManager) catch ()
    -- step2:创建对话框 (最终始终打开 常用目录)
    createDialog rolPathManager width:300 height:130 pos:dialogPos
    
    -- 设置对话框打开标记
    g_pathManagerDialogOpen = true
)

--常用目录-右键删除事件
-- 修改后的管理目录右键事件（Ctrl+右键清空所有路径/单项删除+右键）
on btnManagePaths rightclick do (
    g_lastAction = "Dlt-Path"
    updateModeStatus()
    try 
    (
        -- 新增：检测Ctrl键是否按下
        if keyboard.controlPressed then 
        (
            -- 确认清空操作
            if queryBox "确定清空所有常用路径吗？此操作不可恢复！" title:"⚠️ 警告" beep:true then 
            (
                g_likedFolders = #() -- 清空路径数组
                saveConfig()          -- 保存空配置
                ddlLikedPaths.items = #() -- 清空下拉列表
                messageBox "所有常用路径已清空！" title:"操作完成"
            )
        )
        else 
        (
            -- 原有逻辑：删除选中路径
            local selIndex = ddlLikedPaths.selection
            format "[删除操作] 尝试删除索引：%\n" selIndex
            if selIndex > 0 and selIndex <= g_likedFolders.count do 
            (
                local target = g_likedFolders[selIndex]
                if queryBox ("确定删除路径：\n[" + target.name + "]\n" + target.dir + "?") then 
                (
                    deleteItem g_likedFolders selIndex
                    if saveConfig() then 
                    (
                        format "[删除成功] 已删除路径：%\n" target.name
                        ddlLikedPaths.items = for f in g_likedFolders collect f.name
                        ddlLikedPaths.selection = min selIndex g_likedFolders.count
                    )
                )
            )
        )
    ) 
    catch 
    (
        format "[操作错误] %\n" (getCurrentException())
    )
)

--内存优化处理 / new
on rolPathManager close do (
    -- 清理全局临时变量
    if (globalVars.get #g_tempPathForManager) != undefined do (
        globalVars.remove #g_tempPathForManager
    )
    
    -- 强制垃圾回收
    gc light:true
)

-- (常用路径-listbox/匹配)-选中刷新列表
on ddlLikedPaths selected idx do (
    g_lastAction = "常用-Selete.."
    updateModeStatus()
    g_showRecentFiles = false
    if idx > 0 and idx <= g_likedFolders.count do (
        edtExportPath.text = g_likedFolders[idx].dir
        rdoFileFilter.state = 1 -- 切换到max类型
        model_files_array = #()
        Lv_model.items.clear()
        local maxFiles = getFiles (pathConfig.appendPath edtExportPath.text "*.max")
        for f in maxFiles do additem_lv Lv_model f
        
        refreshFileListView forceRefresh:true -- 强制完全刷新
        updateModeStatus() -- 新增
        windows.processPostedMessages() -- 关键！
    )
)

-- 新增按钮1：添加全部选择集 / 导出选择集配置
on btn_add_all pressed do (
    g_lastAction = "全选-选择集"
    updateModeStatus()
    -- 检查场景是否未保存
    if maxFileName == "" do (
        messageBox "场景未保存，请先保存场景！" title:"操作中止" beep:false
        return undefined
    )
    
    -- 检查场景是否为空
    if objects.count == 0 do (
        messageBox "场景为空，请添加对象！" title:"操作中止" beep:false
        return undefined
    )
    
    -- 检查是否存在选择集
    local setCount = getNumNamedSelSets()
    if setCount == 0 do (
        messageBox "当前场景没有选择集！" title:"操作中止" beep:false
        return undefined
    )
    
    -- 正常执行逻辑
    export_setsets = #()
    for i = 1 to setCount do (
        append export_setsets (getNamedSelSetName i)
    )
    
    -- 更新显示（优化字符串拼接）
    local temp_string = ""
    for i = 1 to export_setsets.count do (
        temp_string += export_setsets[i]
        if i < export_setsets.count do temp_string += " , "
    )
    set_names.text = temp_string
    
    if export_setsets.count > 1 do (
        auto_makedir_set.checked = true
    )
    --messageBox "成功添加所有选择集！" title:"操作完成" beep:false
)

-- 新增按钮2：一键清空选择集 
on btn_clear_all pressed do (
    g_lastAction = "清空-选择集"
    updateModeStatus()
    export_setsets = #()
    set_names.text = ""
    auto_makedir_set.checked = false -- 强制取消勾选分目录复选框
    --messageBox "已清除所有选择集！" title:"操作完成" beep:false
)

-- 增强双击事件处理，添加路径存在性检查-- true -- (功能实现)
on Lv_model MouseDoubleClick sender args do (
    g_lastAction = "双击-打开.."
    updateModeStatus()
    try (
        
        try (
            -- 获取选中文件路径
            selectedItem = Lv_model.SelectedItems.Item[0]
            selectedPath = selectedItem.Tag as String
            
            -- 根据Max版本设置单位参数
            maxVersionValue = (maxVersion())[1]
            if maxVersionValue >= 23000 then (  -- 2021+ 版本
                FBXImporterSetParam "ConvertUnit" #cm  -- 显式单位符号
            ) else (  -- 2019及更旧版本
                FBXImporterSetParam "ConvertUnit" true -- 旧版布尔值
            )
            
            -- 执行文件导入
            FBXImporterSetParam "ConvertUnit" (getConvertUnitParam())
            importFile selectedPath #noPrompt using:FBXIMP
        )
        catch (
            format "MouseDoubleClick--双击打开文件成功！！！" (getCurrentException())
        )
        
        --format "[严重错误] 文件打开失败：%\n" (getCurrentException())
        -- 1. 检查是否有选中项
        if (Lv_model.SelectedItems == undefined) or (Lv_model.SelectedItems.Count == 0) do (
            format "未选中任何文件项\n"
            return undefined
        )
        
        -- 2. 获取选中项并验证有效性
        local item = Lv_model.SelectedItems.Item[0]
        if item == undefined do (
            format "错误：选中的列表项无效\n"
            return undefined
        )
        
        -- 3. 提取文件路径并验证格式
        local filePath = item.Tag as String
        if filePath == undefined or filePath == "" do (
            format "错误：文件路径为空或未定义\n"
            return undefined
        )
        -- 4. 检查文件是否存在且为.max类型
        if not (doesFileExist filePath) do (
            format "错误：文件不存在 - %\n" filePath
            return undefined
        )
        --if (getFilenameType filePath) != ".max" do (
            --format "错误：文件类型不是.max - %\n" filePath
            --return undefined
        --)
        -- 5. 检查场景保存状态（确保返回布尔值）
        local shouldProceed = CheckForSave()
        if classOf shouldProceed != BooleanClass do (
            format "错误：保存检查返回非布尔值 - %\n" (classOf shouldProceed)
            return undefined
        )
        
       -- [1] 获取选中项 -----------------------------------------------------------------
       if Lv_model.SelectedItems.Count == 0 do return undefined
       local item = Lv_model.SelectedItems.Item[0]
       if item == undefined do return undefined
       
       -- 2. 严格类型转换路径
       local filePath = pathConfig.normalizePath (item.Tag as String)
       local fileType = toLower (getFilenameType filePath)
       local path = ""
       try (
           -- 强制转换为字符串并标准化路径
           path = pathConfig.normalizePath (item.Tag as String)
       ) catch (
           format "[错误] 路径转换失败：%\n" (getCurrentException())
           return undefined
       )
       
       -- 3. 跨版本文件夹检测逻辑
       local isFolder = false
       if (maxVersion())[1] >= 23000 then ( -- 2022+ 使用现代API
           isFolder = doesDirectoryExist path
       ) else ( -- 2019 兼容模式
           isFolder = (getFilenameType path) == "" or (doesDirectoryExist path)
       )
      
       
    -- 处理文件夹导航
    if isFolder do (
        -- 路径标准化处理
        -- 版本兼容路径设置
            edtExportPath.text = if (maxVersion())[1] >= 23000 then (
                pathConfig.appendPath path ""
            ) else (
                path
            )
        
    -- 智能设置文件筛选类型
    local newState = autoDetectFilterType path
    if newState != rdoFileFilter.state do (
        rdoFileFilter.state = newState
        format "[智能切换] 检测到特征文件夹：% → 类型%\n" folderName newState
    )
    
    -- 安全刷新列表
    try (
        refreshFileListView forceRefresh:true
    ) catch (
        format "[错误] 刷新失败：%\n" (getCurrentException())
        model_files_array = #()
        Lv_model.Items.Clear()
    )
    
    return undefined
)
    -- 强化类型判断逻辑（同时检查类型栏和文件系统）
    if (item.SubItems.Item[2].Text == "文件夹") or (doesDirectoryExist path) do (
        edtExportPath.text = path
        refreshFileListView()
        return undefined
    )
        
     -- 配置FBX导入参数
        FBXImporterSetParam "Animation" true        -- 导入动画
        FBXImporterSetParam "ResetScene" true        -- 重置场景
        FBXImporterSetParam "Skin" true               -- 导入蒙皮
        FBXImporterSetParam "Cameras" false            -- 禁止相机导入
        FBXImporterSetParam "Lights" false               -- 禁止灯光导入
        --FBXImporterSetParam "ConvertUnit" #centimeters  -- 单位转换  除max 2019 ////其他max 版本 双击会报错(单位转换混淆），必须注销掉...!!!  已 修复，max 2019,2022 OK .
        FBXImporterSetParam "AxisConversion" true    -- 自动轴转换
     -- 只处理左键双击 / 规避 误操作 右键 双击 / 提升 双击列表文件 打开文件的操作精准性 / false
     
     case (toLower (getFilenameType filePath)) of (
        --大部分文件格式 / 双击 可默认打开
        ".png": ( openFileWithDefaultApp filePath )  -- PNG图像
        ".jpg": ( openFileWithDefaultApp filePath )  -- JPEG图像
        ".jpeg": ( openFileWithDefaultApp filePath ) -- JPEG图像
        ".txt": ( openFileWithDefaultApp filePath )  -- 文本文件
        ".doc": ( openFileWithDefaultApp filePath )  -- Word文档
        ".docx": ( openFileWithDefaultApp filePath ) -- Word文档
        ".xls": ( openFileWithDefaultApp filePath )  -- Excel表格
        ".xlsx": ( openFileWithDefaultApp filePath ) -- Excel表格
        ".pdf": ( openFileWithDefaultApp filePath )  -- PDF文档
        ".zip": ( openFileWithDefaultApp filePath )  -- ZIP压缩包
        ".rar": ( openFileWithDefaultApp filePath )  -- RAR压缩包
        ".7z": ( openFileWithDefaultApp filePath )   -- 7-Zip压缩包
        ".ini": ( openFileWithDefaultApp filePath )  -- 配置文件
        ".json": ( openFileWithDefaultApp filePath ) -- JSON文件
        ".xml": ( openFileWithDefaultApp filePath )  -- XML文件
        
        ".bip": (
                if (CheckForSave()) do ( 
           
                g_lastAction = "双击-导入.."
                updateModeStatus()
                if Lv_model.SelectedItems.Count == 0 do return false
                local item = Lv_model.SelectedItems.Item[0]
                local bipPath = item.Tag as String
                
                if (toLower (getFilenameType bipPath)) != ".bip" do return false
                
                if SilentBipedImport bipPath do (
                    messageBox ("BIP已导入：\n" + bipPath) title:"成功" beep:false
                    )
                )
            )
        ".ms": (  -- 脚本文件（不重置场景）
                if (CheckForSave()) do (
                    g_lastAction = "双击-运行.."
                    updateModeStatus()
                    -- 安全执行脚本不重置场景
                    try (
                        fileIn filePath  -- 直接执行脚本
                        format "已执行脚本：%\n" filePath
                    ) catch (
                        format "[脚本错误] 文件：%\n错误：%\n" filePath (getCurrentException())
                    )
                )
            )
            
        ".mse": (  -- 加密脚本（不重置场景）
                if (CheckForSave()) do (
                    g_lastAction = "双击-运行.."
                    updateModeStatus()
                    -- 安全执行加密脚本
                    try (
                        fileIn filePath  -- 直接执行加密脚本
                        format "已执行加密脚本：%\n" filePath
                    ) catch (
                        format "[加密脚本错误] 文件：%\n错误：%\n" filePath (getCurrentException())
                    )
                )
            )
            
        ".mzp": (  -- 脚本文件（不重置场景）
                if (CheckForSave()) do (
                    g_lastAction = "双击-运行.."
                    updateModeStatus()
                    -- 安全执行脚本不重置场景
                    try (
                        fileIn filePath  -- 直接执行脚本
                        format "已执行脚本：%\n" filePath
                    ) catch (
                        format "[脚本错误] 文件：%\n错误：%\n" filePath (getCurrentException())
                    )
                )
            )
			
        ".mcr": (  -- 脚本文件（不重置场景）
                if (CheckForSave()) do (
                    g_lastAction = "双击-运行.."
                    updateModeStatus()
                    -- 安全执行脚本不重置场景
                    try (
                        fileIn filePath  -- 直接执行脚本
                        format "已执行脚本：%\n" filePath
                    ) catch (
                        format "[脚本错误] 文件：%\n错误：%\n" filePath (getCurrentException())
                    )
                )
            )
			
        ".max": (  -- MAX场景文件
                if (CheckForSave()) do (
                    resetMaxFile #noPrompt
                    loadMaxFile filePath useFileUnits:true quiet:true
                    -- 打开max 同时刷新 选择集
                    GetSetFormScene() 
                    
                    -- 直接调用高亮函数，不需要延迟
                    highlightCurrentFile()
                    
                    format "场景已重置并加载：%\n" filePath
                )
            )
            -- 其他文件类型处理（保持不变）
            default: (openFileWithDefaultApp filePath)
            
        ".xaf": (
                if (CheckForSave()) do (
                    g_lastAction = "双击-导入.."
                    updateModeStatus()
                    local xafPath = item.Tag as String
                    if importXafAnimation path do (
                        messageBox ("xaf已导入：\n" + xafPath) title:"成功" beep:false
                    )
                )
            )
            
            
        ".fbx": (
                
                if (CheckForSave()) do (
                    
                try(     
                    
                -- 导入前准备/核心双击导入查看
                with redraw off (
                    format "[完成] FBX导入及姿势修正成功！" (getCurrentException())  
                    --双击列表FBX文件功能备注：（
                    -- 前提是保证 导入前---当前打开的 max 文件 初始 pose 为 标准的默认初始POSE,目前功能暂时只是支持 导入查看为主，快捷检查：//FBX 导出 是否都导出成功了 ！？...
                    -- 逻辑是复制当前打开的文件的第0帧作为初始pose , 导入 FBX 前 进行强制复制 ，导入FBX 后 再 在 第 0 帧 进行粘贴 pose （包括cs,虚拟体如 B0NE ,DUMMY 等...)
                   
                    --清空监听器信息）
                    clearlistener()
                    -- 增强版禁用视图刷新
                     disableSceneRedraw()
                     suspendEditing() -- 挂起编辑操作（Max 2022+ 新增API）
                    -- 备份姿势时强制使用世界坐标系
                    in coordSys world copyPosture()
                    
                    -- 配置FBX导入参数
                    FBXImporterSetParam "ResetScene" true
                    FBXImporterSetParam "ConvertUnit" (getConvertUnitParam())  -- 正确调用全局函数
                                    
                    -- 执行导入（添加版本兼容参数）
                                    
                    if (maxVersion())[1] >= 21000 then (
                                        
                        importFile filePath #noPrompt using:FBXIMP  -- 新版必须指定using参数
                                    
                    ) else (
                                        
                        importFile filePath #noPrompt  -- 旧版无需using
                                    
                    )
                    
                    -- 延迟恢复UI（Max 2022+ 优化）
                    resumeEditing() -- 恢复编辑操作
                    enableSceneRedraw()
                    completeRedraw()           
                
                    -- 分阶段应用姿势
                    pastePosture false  -- 应用基础姿势
                    pastePosture true   -- 修正动画层状态
                )
                
                -- 最终Biped系统更新
                for master in biped.getBipedRoots() do (
                    -- 增加空指针保护
                    if isValidNode master do (
                    biped.update master #all
                    maxOps.CollapseNode master off
                )
            )
                format "[完成] FBX导入及姿势修正成功！\n"
                 
                                )catch (
                                         format "[完成] FBX导入及姿势修正成功！" (getCurrentException())
                                        )
                    )
                            )
                            default: (
                                openFileWithDefaultApp filePath
                            )
                        )
            )catch ( format "[全局错误] 双击操作失败：%\n" (getCurrentException()) 
                      )
        -- 在导入完成后强制回收内存
        gc light:true
        freeSceneBitmaps()
        
        )
    
--format "[严重错误] 流程中断：%\n" (getCurrentException())             

--[[ 列表交互增强2 ]]--直接点击执行删除--new--true
on btn_removeSelected pressed do (
    g_lastAction = "删除-选中项.."
    updateModeStatus()
    
    try (
        -- 安全锁定界面
        Lv_model.BeginUpdate()
        
        -- 获取要删除的项：优先使用勾选项，如果没有勾选项则使用选中的项
        local indicesToRemove = #()
        
        -- 检查是否有勾选项
        local hasCheckedItems = false
        for i = 0 to (Lv_model.Items.Count-1) do (
            if Lv_model.Items.Item[i].Checked do (
                hasCheckedItems = true
                exit
            )
        )
        
        -- 根据是否有勾选项决定删除策略
        if hasCheckedItems then (
            -- 删除所有勾选项
            for i = (Lv_model.Items.Count-1) to 0 by -1 where Lv_model.Items.Item[i].Checked do (
                append indicesToRemove i
            )
        ) else (
            -- 删除所有选中的项
            for i = (Lv_model.Items.Count-1) to 0 by -1 where Lv_model.Items.Item[i].Selected do (
                append indicesToRemove i
            )
        )
        
        if indicesToRemove.count == 0 do (
            messageBox "请先勾选或选择要删除的项目！" title:"提示"
            Lv_model.EndUpdate()
            return undefined
        )
        
        -- 对索引进行排序（从大到小）
        sort indicesToRemove
        indicesToRemove = for i in indicesToRemove collect i  -- 确保是数组
        
        -- 从后向前删除（避免索引变化问题）
        for i = indicesToRemove.count to 1 by -1 do (
            local idx = indicesToRemove[i]
            if idx >= 0 and idx < Lv_model.Items.Count do (
                try (
                    -- 移除列表项
                    Lv_model.Items.RemoveAt idx
                    
                    -- 同步数据数组
                    if idx+1 <= model_files_array.count do (
                        deleteItem model_files_array (idx+1)
                    )
                )
                catch (
                    format "[删除跳过] 索引 % 异常：%\n" idx (getCurrentException())
                )
            )
        )
        
        -- 更新统计显示
        local dirCount = (getDirectories (edtExportPath.text + "\\*")).count
        local fileCount = model_files_array.count - dirCount
        lblCount.text = "文件：" + (fileCount as string)
        
        -- 更新模式状态
        updateModeStatus()
        
        -- 显示操作结果
        g_lastAction = "已删除 " + (indicesToRemove.count as string) + " 个项目"
        updateModeStatus()
        
    )
    catch (
        format "[删除错误] 主流程异常：%\n" (getCurrentException())
        try (
            messageBox "删除操作异常，建议刷新列表！" title:"错误" beep:true
        ) catch ()
    )
    
    -- 确保界面解锁
    try (Lv_model.EndUpdate()) catch ()
    try (Lv_model.Refresh()) catch ()
    
    -- 内存清理
    gc light:true
)

-- 新增重置场景功能
on btn_resetScene pressed do (
    g_lastAction = "重置-场景"
    updateModeStatus()
    try (
        resetMaxFile #noPrompt
        format "场景已重置\n"
    ) catch (
        format "重置失败：%\n" (getCurrentException())
    )
)

-- 强化版自动识别功能
on btn_autoRead pressed do (
    g_lastAction = "⌛读取-当前"
    updateModeStatus()
    g_showRecentFiles = false -- 新增模式重置
    
    -- 获取当前Max文件的目录路径（包含末尾反斜杠）
    local currentDir = maxFilePath
    rdoFileFilter.state = 1 -- 切换到MAX类型
    
    -- 去除路径末尾的反斜杠（如果存在）
    if currentDir != "" and currentDir[currentDir.count] == "\\" do (
        currentDir = substring currentDir 1 (currentDir.count - 1)
    )
    
    -- 处理未保存场景的情况
    if currentDir == "" then (
        messageBox "当前场景未保存，请先保存文件！" title:"提示" beep:false
        return undefined
    )
    
    -- 更新导出路径和列表
    chkAutoFolder.checked = false
    edtExportPath.text = currentDir  -- 此时路径已无末尾反斜杠
    model_files_array = #()
    Lv_model.Items.Clear()
    
    -- 使用安全路径拼接加载.max文件
    local maxFiles = getFiles (pathConfig.appendPath currentDir "*.max")
    for f in maxFiles do additem_lv Lv_model f
    
    -- 刷新文件列表
    refreshFileListView()
    
    -- 使用全局函数高亮当前文件
    highlightCurrentFile()
    
    updateModeStatus() 
    windows.processPostedMessages() -- 关键！
    format "已加载目录：%\n" currentDir
)

-- 导出或者保存路径 地址 变更 刷新 列表 
on edtExportPath changed text do (
    if chkAutoFolder.checked do (
        model_files_array = #()
        Lv_model.items.clear()
        local maxFiles = getFiles (pathConfig.appendPath text "*.max")
        for f in maxFiles do additem_lv Lv_model f
    )
)

-- 只显示 文件 （ 比如 不需要文件夹的显示，则在导出前，添加一遍这个 添加MAX 操作 则列表只显示 MAX 文件 ，规避 批量导出 进程 开始后 ，提高 导出 目标 准备工作的 可操作性！规避 批量导出 会自动识别 有MAX 文件的 文件夹和文件）
on btnBrowseFolder pressed do (
    g_lastAction = "添加-MAX文件"
    updateModeStatus()
    g_showRecentFiles = false  -- 重置标记
        local selectedDir = getSavePath caption:"选择包含MAX文件的目录" initialDir:edtExportPath.text
        if selectedDir != undefined do (
            -- 清除旧数据
            model_files_array = #()
            Lv_model.items.clear()
            
            -- 加载新文件
            local maxFiles = getFiles (selectedDir + "\\*.max")
            for f in maxFiles do (
                additem_lv Lv_model f
            )
            edtExportPath.text = selectedDir
        )
    )
   
    -- 自动生成复选框事件
on chkAutoFolder changed state do (
    if state then updateExportPath forceAuto:true
    else edtExportPath.text = pathConfig.removePathLeaf edtExportPath.text
)
   -- 新增"定位FBX"按钮
on btn_resetFBXPath pressed do (
    g_lastAction = "定位-FBX"
    updateModeStatus()
    updateExportPath forceAuto:true
)                                
    
-- 浏览路径按钮功能--new
on btnBrowsePath pressed do (
    g_lastAction = "set-导出路径"
    updateModeStatus()
    newPath = getSavePath caption:"选择导出目录" initialDir:edtExportPath.text
    if newPath != undefined do (
        edtExportPath.text = newPath
        chkAutoFolder.checked = false  -- 新增：取消自动生成目录勾选
        g_lastExportPath = newPath  -- 更新最后路径记录
        -- 刷新文件列表
        AutoExportTool_Pro.refreshFileListView()
    )
)

--- ===== 在 btnBrowsePath 控件添加右键功能 =====
-- ===== 在按钮事件中调用 =====
-- 在 btnBrowsePath rightclick 事件中修改为：
on btnBrowsePath rightclick do (
    
    g_lastAction = "copy-path"
    updateModeStatus()
    
    if edtExportPath.text != "" do (
        -- 使用安全路径处理
        local pathToCopy = pathConfig.normalizePath edtExportPath.text
        
        -- 复制到剪贴板
        if (setClipboardText pathToCopy) then (
            -- 设置全局临时路径
            g_tempPathForManager = pathToCopy
            
            -- 关闭已存在的对话框（防止重复）
            try (destroydialog rolPathManager) catch ()
            
            -- 计算对话框位置（确保在屏幕内）
            local dialogPos = mouse.screenPos - [150, 75]
            dialogPos.x = amax 0 (amin dialogPos.x (sysInfo.desktopSize.x - 300))
            dialogPos.y = amax 0 (amin dialogPos.y (sysInfo.desktopSize.y - 130))
            
            -- 立即打开管理器（带位置参数）
            createDialog rolPathManager width:300 height:130 pos:dialogPos
            
            -- 设置对话框打开标记
            g_pathManagerDialogOpen = true
            
            -- 直接尝试填充路径（不再需要循环）
            try (
                rolPathManager.edtPathDir.text = g_tempPathForManager
                setFocus rolPathManager.edtPathName
            )
            catch (
                format "[路径管理] 自动填充失败: %\n" (getCurrentException())
            )
        )
        else (
            messageBox "剪贴板写入失败！" title:"错误" beep:true
        )
    )
)

-- 打开路径按钮功能--new/up
on btnOpenExportPath pressed do (
    g_lastAction = "打开当前路径1"
    updateModeStatus()
    if doesFileExist edtExportPath.text do (
        ShellLaunch "explorer.exe" ("file:///" + edtExportPath.text)  -- 兼容路径格式1
    )
if g_showRecentFiles do (
    messageBox "oi!这世上什么‘果’都有，就是没有‘如果’" title:"魔幻的现实​​/最近打开文件模式！！" beep:false
)
--g_showRecentFiles = false
)
    -- 打开路径按钮功能--new/down
on btnOpenExportPath1 pressed do (
    g_lastAction = "打开当前路径2"
    updateModeStatus()
    if doesFileExist edtExportPath.text do (
        ShellLaunch "explorer.exe" ("file:///" + edtExportPath.text)  -- 兼容路径格式2
    )
    if g_showRecentFiles do (
        messageBox "我遵从了内心的法则，而不是世俗的规则" title:"听从内心的声音​/最近打开文件模式！！！" beep:false
    )
    --g_showRecentFiles = false
)
----------------------------------------------------------------
    --刷新场景选择集
on btn_reset pressed do (
    g_lastAction = " 刷新-选择集"
    updateModeStatus()
    GetSetFormScene())
    --更新到导出选择集名称 添加
on btn_add_set pressed do (
    g_lastAction = " 添加-选择集"
    updateModeStatus()
    -- 检查选择集是否有效
    if selec_set.items.count == 0 do (
        messageBox "请先创建或刷新选择集！" title:"选择集为空" beep:false
        return undefined
    )
    
    local selName = selec_set.selected
    if selName == undefined or selName == "" do (
        messageBox "未选择有效选择集名称！" title:"无效选择" beep:false
        return undefined
    )
    
    -- 检查是否已存在同名选择集
    local temp_index = findItem export_setsets selName
    if temp_index == 0 do (
        append export_setsets selName
        
        -- 安全构建显示字符串（过滤无效项）
        local temp_string = ""
        for i in export_setsets where (i != undefined and i != "") do (
            temp_string += i + " , "
        )
        temp_string = trimRight temp_string " , "  -- 删除末尾逗号
        
        set_names.text = temp_string
    )
    if export_setsets.count > 1 do (
        auto_makedir_set.checked = true
    )
)
    
-- 修改后的导出配置--选择集--删除按钮逻辑1（无确认直接删除）
on btn_del_set pressed do (
    g_lastAction = " 移除-选择集"
    updateModeStatus()
    if export_setsets.count > 0 then
    (
        deleteItem export_setsets export_setsets.count
        
        -- 构建显示字符串
        local temp_string = ""
        for i = 1 to export_setsets.count do 
        (
            temp_string += export_setsets[i]
            if i < export_setsets.count do temp_string += " , "
        )
        set_names.text = temp_string
    )
    else
    (
        --messageBox "没有可删除的选择集！" title:"提示" beep:false
    )
)
    
--拖放事件结束
on Lv_model DragOver sender args do
(
    if args.Data.GetDataPresent (dotNetClass "System.Windows.Forms.DataFormats").FileDrop then
    (
        args.Effect = args.Effect.Copy
    )
    else
    (
        args.Effect = args.Effect.None
    )
)

--拖放事件开始
on Lv_model DragDrop sender args do
(
    local dropData = args.Data.GetData (dotNetClass "System.Windows.Forms.DataFormats").FileDrop
    if dropData == undefined do return false
    
    for path in dropData do
    (
        if doesFileExist path then 
        (
            -- 添加文件
            append model_files_array path
            -- 创建列表项并添加到Lv_model
            -- ... (类似上面refresh函数中的文件添加逻辑)
        )
        else if doesDirectoryExist path then 
        (
            -- 添加文件夹（使用特殊标记）
            append model_files_array ("[DIR]"+path)
            -- 创建列表项并添加到Lv_model
            -- ... (类似上面refresh函数中的文件夹添加逻辑)
        )
    )
    
    -- 刷新列表视图
    refreshFileListView()
)

-- 修改拖放事件，保留原有功能
on Lv_model DragDrop sender EventArgs do (
        g_showRecentFiles = false
        local data = EventArgs.data.GetFileDropList()
        local validExts = #(".max", ".fbx", ".ms", ".mse", ".bip", ".mzp", ".mcr")
        
        -- 新增：拖放前禁用自动布局
        Lv_model.BeginUpdate()
        
        for k = 0 to data.count-1 do 
        (
            local fPath = pathConfig.normalizePath data.item[k]
            if findItem validExts (toLower(getFilenameType fPath)) > 0 do
            (
                additem_lv Lv_model fPath isDrag:true
                -- 每次添加后立即更新布局（关键修复）
                Lv_model.EndUpdate()
                Lv_model.BeginUpdate()
                updateScrollState() 
            )
        )
        
        -- 恢复布局控制
        Lv_model.EndUpdate()
        updateScrollState()
    )
    ----------------------------------------------------------------
    -- 仅清空列表显示的文件和文件夹 / 并非 真实 删除
    on btn_model_close pressed do (
        g_lastAction = "​✖​清空-列表"
        updateModeStatus()
        model_files_array = #()
        Lv_model.Items.Clear()
        lblCount.text = "文件：0"
        -- 保留当前路径不重置
        format "[清空] 列表已清空，当前路径保持：%\n" edtExportPath.text
    )
    --edtExportPath.text = pathConfig.normalizePath (getDir #scene) -- 重置默认路径 - false

-- 批量BIP导入执行事件 ===========================================
----------------------------------------------------------------
--一键换皮/XAF导出导入属性事件 - 考虑到 UI 排版 已满 / false - 作沉淀代码处理/备用
--xaf 相关 附件 导出 参数 1 / 事件
on chk_useRotation changed state do (
    g_useCustomRotation = state
    rdo_rotation.visible = state
)

--xaf 相关 附件 导出 参数 2 / 事件
on rdo_rotation changed state do (
    g_rotationMode = if state == 1 then #tcb else #euler
)

-- 文件归档 / 后缀相关 / false 沉淀代码
on edt_excludePrefix entered text do (
    g_excludePrefix = text
)

-- 修改按钮事件绑定（移除骨骼选择验证）- 核心/批量处理文件一键换皮（导入BIP,XAF=附件，转存成新MAX) 自动创建的指定文件夹-//SkinReplace_Output
on btnBatchSkinReplace pressed do (
    try (
        g_lastAction = "🎭一键换皮"
        updateModeStatus()  -- 先更新状态再执行操作
        
        disableSceneRedraw()
        
        if queryBox "确定开始批量换皮吗？\n新文件将保存到 SkinReplace_Output 目录" title:"确认操作" do (
        processSkinReplacement()
        )
    )
    catch (
        format "[换皮错误] %\n" (getCurrentException())
        g_lastAction = "操作失败！"
        updateModeStatus()

    )
    enableSceneRedraw()
    completeRedraw()
    --cleanupBipedNodes()
)

-- 批量（识别列表全部BIP-数据文件，导入当前打开的 MAX 文件，转存成新MAX）自动创建的指定文件夹-// MAX_Imports
on btnBatchImportBip pressed do (
    g_lastAction = "📥批量BIP导入"
    updateModeStatus()
    -- 1. 获取待处理文件列表 
    local processFiles = #()
    local anyItemChecked = false
    
    -- 检测是否有勾选项
    for i=0 to (Lv_model.Items.Count-1) do (
        if Lv_model.Items.Item[i].Checked do (
            anyItemChecked = true
            exit
        )
    )
    
    -- 构建处理列表
    for i=0 to (Lv_model.Items.Count-1) do (
        local item = Lv_model.Items.Item[i]
        local fPath = item.Tag as String
        
        if (toLower (getFilenameType fPath)) == ".bip" do (
            case of (
                (anyItemChecked and item.Checked): append processFiles fPath
                (not anyItemChecked): append processFiles fPath
            )
        )
    )
    
    -- 有效性验证
    if processFiles.count == 0 do (
        messageBox "未找到有效BIP文件！" title:"操作中止"
        return undefined
    )
    
    -- 2. 创建输出目录 ---------------------------------------------------
    local outputDir = pathConfig.appendPath (getDir #scene) "MAX_Imports"
    makeDir outputDir all:true
    
    -- 3. 进度控制初始化 -------------------------------------------------
    local successCount = 0
    pbProgress.value = 0
    pbProgress.maximum = processFiles.count
    lblProgressInfo.text = "准备开始批量导入..."
    g_exportAbortFlag = false
    
    -- 4. 主处理循环 -----------------------------------------------------
    disableSceneRedraw()
    try (
        for i=1 to processFiles.count where not g_exportAbortFlag do (
            if keyboard.escPressed do (
                g_exportAbortFlag = true
                lblProgressInfo.text = "用户中断操作！"
                exit
            )
            
            local bipPath = processFiles[i]
            lblProgressInfo.text = "正在导入：" + filenameFromPath bipPath
            -- 保存原始场景状态
            local originalScene = holdMaxFile()
            -- 执行BIP导入
            if SilentBipedImport bipPath do (
                -- 生成唯一文件名
                --local newName = uniqueFileName outputDir (getFilenameFile maxFileName) ".max"
                local newName = GenerateTargetPath bipPath outputDir
                -- 冲突处理（同名文件自动编号）
                --local finalName = uniqueFileNameFromTemplate newName
                -- 安全保存文件
            if saveMaxFile newName then (
                successCount += 1
                format "[成功] 保存至：%\n" newName
            )
        )
            -- 恢复原始场景
            --fetchMaxFile originalScene quiet:true
            -- 更新进度
            pbProgress.value = i
            lblProgressInfo.text = "进度：" + ((100.0*i/processFiles.count) as integer) as string + "%"
            windows.processPostedMessages()
            
            -- 内存优化
            if mod i 5 == 0 do (gc(); freeSceneBitmaps())
        )
    )
    catch (
        format "[致命错误] %\n" (getCurrentException())
        messageBox "批量导入过程中发生严重错误！" title:"错误" beep:true
    )
    enableSceneRedraw()
    updateModeStatus()
    -- 5. 完成处理 -------------------------------------------------------
    lblProgressInfo.text = "批量-BIP-导入完成！！！成功导入 " + successCount as string + "/" + processFiles.count as string + " 个BIP文件"
    if successCount > 0 do (
        ShellLaunch "explorer.exe" outputDir
        messageBox ("文件已保存到：\n" + outputDir) title:"完成" beep:false
    )
    --cleanupBipedNodes()
)

-- 强化事件处理
on btnImportBip pressed do 
(
    g_lastAction = "🎮加载BIP"
    updateModeStatus()
    try(BsBipedImport())catch(
        messageBox ("导入失败：\n" + getCurrentException()) title:"BipedTools" beep:true
    )
    --cleanupBipedNodes()
)

on btnExportBip pressed do 
(
    g_lastAction = "💾保存BIP"
    updateModeStatus()
    try(BsBipedExport())catch(
        messageBox ("导出失败：\n" + getCurrentException()) title:"BipedTools" beep:true
    )
    --cleanupBipedNodes()
)

-- 按钮事件处理--false
--on btn_exportCurrentBIP pressed do (
    
    --if processCurrentBipExport != undefined then processCurrentBipExport()
    --else messageBox "导出函数未初始化！" title:"严重错误"
--)


-- 保持原有按钮事件绑定
on btn_bipBatchChecked pressed do (
    g_lastAction = "🏎️CK-导出BIP" 
    updateModeStatus()
    -- 检查前置条件
    if model_files_array.count == 0 do (
        messageBox "          文件列表为空！" title:"操作中止" beep:false
        for c in AutoExportTool_Pro.controls do c.enabled = true
        return undefined
    )
-
    updateModeStatus()
    processBipFiles rdo_bipMode.state true
    --cleanupBipedNodes()
)

on btn_bipBatchAll pressed do (
    g_lastAction = "💤ALL-导出BIP" 
    updateModeStatus()
    -- 检查前置条件
    if model_files_array.count == 0 do (
        messageBox "          文件列表为空！" title:"操作中止" beep:false
        for c in AutoExportTool_Pro.controls do c.enabled = true
        return undefined
    )
    
    updateModeStatus()
    processBipFiles rdo_bipMode.state false
    --cleanupBipedNodes()
)
----------------------------------------------------------------
----------------------------------------------------------------
--false
on btn_pauseResume pressed do (   
        g_processPaused = not g_processPaused
        btn_pauseResume.text = if g_processPaused then "▶继续" else "⏸暂停"
    )
    ----------------------------------------------------------------
    -- ===================== 批量导出 -（主执行事件）===========================
    
-- 批量导出-lv 列表 所有文件--非勾选--导出事件处理-- 强化导出主流程（添加多层保护）（跳过错误文件）（进度条显示）...

----------------------------------------------------------------
-- LV-列表全部导出 // FBX-批量导出列表全部 MAX 文件
on btn_aotu_model pressed do (
    g_lastAction = "⚡批量导出"
    updateModeStatus()
    
    -- 检查文件列表是否为空
    if model_files_array.count == 0 do (
        messageBox "文件列表为空！" title:"操作中止" beep:true
        return undefined
    )
    
    -- 检查选择集是否配置
    if export_setsets.count == 0 do (
        messageBox "导出选择集未配置！" title:"操作中止" beep:true
        return undefined
    )

    -- 重置中断标志
    g_exportAbortFlag = false
    clearlistener()
    
    -- 初始化进度控制
    local totalProgress = 0.0
    pbProgress.value = 0
    pbProgress.maximum = model_files_array.count * 100  -- 每个项目预留100%进度空间
    pbProgress.Refresh()
    btn_aotu_model.enabled = false
    
    local successCount = 0
    
    -- 主处理循环
    for i = 1 to model_files_array.count where not g_exportAbortFlag do (
        -- ESC键检测
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            format "[用户中断] 导出进程已被手动终止\n"
            lblProgressInfo.text = "操作已中断！" 
            windows.processPostedMessages()
            messageBox "导出进程已被用户中断！" title:"操作提示" beep:true
            exit
        )

        -- 处理当前项目
        local currentItem = model_files_array[i]
        
        -- 检查是否是文件夹项
        if matchPattern currentItem pattern:"[DIR]*" then (
            -- 处理文件夹
            local folderPath = substring currentItem 6 -1  -- 移除"[DIR]"前缀
            
            lblProgressInfo.text = "正在处理文件夹：" + filenameFromPath folderPath
            
            -- 获取文件夹中的所有max文件
            local folderFiles = getFiles (folderPath + "\\*.max")
            local folderFileCount = folderFiles.count
            
            -- 为当前角色文件夹创建FBX导出子目录
            local fbxExportDir = folderPath + "\\FBX_Export"
            if not doesDirectoryExist fbxExportDir do (
                makeDir fbxExportDir all:true
                format "[创建目录] %\n" fbxExportDir
            )
            
            if folderFileCount > 0 then (
                -- 处理文件夹中的每个文件 / 处理文件夹中的每个文件 - 添加中断检测
                for j = 1 to folderFileCount do (
                    -- 实时检测ESC键
                    if keyboard.escPressed do (
                        g_exportAbortFlag = true
                        format "[用户中断] 文件夹处理已被终止\n"
                        lblProgressInfo.text = "操作已中断！" 
                        windows.processPostedMessages()
                        exit
                    )
                    
                    local currentFile = folderFiles[j]
                    
                    lblProgressInfo.text = "处理文件夹中的文件：" + filenameFromPath currentFile
                    
                    -- 加载并导出文件
                    if (load_file currentFile) then (
                        export_mod_fn rdo_exportMode.state
                        refreshSceneSetsCache()
                        
                        -- 验证选择集有效性
                        local validSets = for s in export_setsets where (findItem g_sceneSetsCache s > 0) collect s
                        
                        if validSets.count > 0 do (
                            -- 应用挂点归零
                            if auto_socket.checked do resetSocketTransforms()
                            
                            for setName in validSets do (
                                if selectExportobject setName and (export_file currentFile setName fbxExportDir) do (
                                    successCount += 1
                                )
                            -- 添加额外中断检查点
                            if keyboard.escPressed do (
                                g_exportAbortFlag = true
                                format "[用户中断] 选择集处理已被终止\n"
                                lblProgressInfo.text = "操作已中断！" 
                                windows.processPostedMessages()
                                exit
                            )
                            
                        )
                        
                      )
                    )
                    else (
                        format "[错误] 无法加载文件：%\n" currentFile
                    )
                    
                    -- 更新进度
                    totalProgress += (100.0 / folderFileCount)
                    pbProgress.value = totalProgress as integer
                )
            )
            else (
                format "[跳过] 文件夹中没有.max文件：%\n" folderPath
                totalProgress += 100  -- 跳过空文件夹仍然计入进度
                pbProgress.value = totalProgress as integer
            )
        )
        else (
            -- 处理单个文件
            lblProgressInfo.text = "正在处理文件：" + filenameFromPath currentItem
             -- 确定导出路径
             local enginePath = getEngineExportPath currentItem
             local targetPath = if enginePath != undefined and doesDirectoryExist enginePath then enginePath else edtExportPath.text
            -- 加载文件
            if (load_file currentItem) then (
                export_mod_fn rdo_exportMode.state
                refreshSceneSetsCache()
                -- 应用挂点归零
                if auto_socket.checked do resetSocketTransforms()
                -- 验证选择集有效性
                local validSets = for s in export_setsets where (findItem g_sceneSetsCache s > 0) collect s
                
                if validSets.count > 0 do (
                    for setName in validSets do (
                        if selectExportobject setName and (export_file currentItem setName targetPath) do (
                            successCount += 1
                        )
                    )
                )
            )
            else (
                format "[错误] 无法加载文件：%\n" currentItem
            )
            
            -- 更新进度
            totalProgress += 100
            pbProgress.value = totalProgress as integer
        )
        
        -- 更新进度显示
        lblProgressInfo.text = "进度：" + ((totalProgress / model_files_array.count) as integer) as string + "%"
        windows.processPostedMessages()
        
    )

    -- 完成处理
    lblProgressInfo.text = "批量导出完成！成功导出 " + (successCount as string) + " 个文件"
    btn_aotu_model.enabled = true
    
    -- 新增：导出完成后刷新列表
    refreshFileListView forceRefresh:true
    format "[列表更新] 批量导出后刷新文件列表\n"
    
    if chk_autoOpenDir.checked do ShellLaunch "explorer.exe" edtExportPath.text 
)

----------------------------------------------------------------
-- LV-列表勾选导出--批量导出事件处理--新增
-- 导出勾选文件处理（支持文件夹递归）
on btn_export_checked pressed do (
    g_lastAction = "🚀导出勾选"
    updateModeStatus()
    
    -- 递归获取文件夹内所有.max文件
    fn getAllMaxFilesInFolder folderPath = (
        local maxFiles = #()
        local files = getFiles (folderPath + "\\*.max")
        join maxFiles files
        
        -- 递归子文件夹
        local subDirs = getDirectories (folderPath + "\\*")
        for dir in subDirs do (
            join maxFiles (getAllMaxFilesInFolder dir)
        )
        maxFiles
    )
    
    -- 收集所有需要导出的文件
    local filesToExport = #()
    
    -- 遍历勾选项
    for i = 0 to (Lv_model.Items.Count - 1) do (
        if Lv_model.Items.Item[i].Checked do (
            local itemPath = Lv_model.Items.Item[i].Tag as String
            
            -- 处理文件夹项
            if matchPattern itemPath pattern:"[DIR]*" then (
                local folderPath = substring itemPath 6 -1
                if doesDirectoryExist folderPath do (
                    join filesToExport (getAllMaxFilesInFolder folderPath)
                )
            )
            -- 处理单个文件项
            else (
                if (getFilenameType itemPath) == ".max" and doesFileExist itemPath do (
                    append filesToExport itemPath
                )
            )
        )
    )
    
    -- 检查前置条件
    if filesToExport.count == 0 do (
        messageBox "勾选导出不支持文件夹导出！" title:"提示" beep:true
        return undefined
    )
    
    if export_setsets.count == 0 do (
        messageBox "请先添加导出选择集！" title:"提示" beep:true
        return undefined
    )

    -- 获取导出基础路径
    local exportBasePath = edtExportPath.text
    
    -- 初始化进度控制
    local totalProgress = 0.0
    pbProgress.value = 0
    pbProgress.maximum = filesToExport.count * 100
    pbProgress.Style = (dotNetClass "System.Windows.Forms.ProgressBarStyle").Continuous
    btn_export_checked.enabled = false
    clearlistener()
    g_exportAbortFlag = false

    -- 在导出前设置FBX参数
    export_mod_fn rdo_exportMode.state
    
    local successCount = 0
    for filePath in filesToExport where not g_exportAbortFlag do (
        -- ESC键检测
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            lblProgressInfo.text = "操作已中断！"
            messageBox "导出进程已被用户中断！" title:"操作提示" beep:true
            exit
        )

        lblProgressInfo.text = "正在处理：" + filenameFromPath filePath
        windows.processPostedMessages()

        -- 加载文件
        if (loadMaxFile filePath quiet:true) do (
            -- 挂点归零
            if auto_socket.checked do resetSocketTransforms()
            
            -- 刷新场景选择集缓存
            refreshSceneSetsCache()
            
            -- 验证选择集有效性
            local validSets = #()
            local validCount = 0
            for o in export_setsets do (
                if findItem g_sceneSetsCache o > 0 do (
                    append validSets o
                    validCount += 1
                )
            )
            
            -- 执行导出
            local fileSuccess = 0
            for o in validSets do (
                if selectExportobject o and (export_file filePath o exportBasePath) do (
                    successCount += 1
                    fileSuccess += 1
                )
            )
            
            format "[成功] 文件 % 导出 %/% 个选择集\n" filePath fileSuccess validCount
            
            -- 更新进度
            totalProgress += 100
            pbProgress.value = totalProgress as integer
            lblProgressInfo.text = "进度：" + ((totalProgress / filesToExport.count) as integer) as string + "%"
            windows.processPostedMessages()
        )
    )
    
    -- 完成处理
    lblProgressInfo.text = "文件勾选导出完成！成功处理 " + (successCount as string) + " 个文件"
    btn_export_checked.enabled = true
    
    -- 新增：导出完成后刷新列表
    refreshFileListView forceRefresh:true
    format "[列表更新] 勾选导出后刷新文件列表\n"
    
    if chk_autoOpenDir.checked and doesDirectoryExist exportBasePath do (
        ShellLaunch "explorer.exe" exportBasePath
    )
    
    gc light:true
    freeSceneBitmaps()
)

--手动FBX导出模式--导出当前场景--单个文件--导出事件处理
   
on btn_exp_M_fbx pressed do (
    g_lastAction = "🎯导出当前"
    updateModeStatus()
    -- 修改后的验证逻辑
    if rdo_exportMode.state == 3 do (
        if animationRange.end <= animationRange.start do (
            msg = case of (
            (animationRange.end <= animationRange.start): "动画范围无效（起始帧必须小于结束帧）！"
            )
            messageBox msg title:"Bake模式错误"
            return undefined
        )
    )
    -- 重置进度条并强制颜色刷新
    pbProgress.value = 0
    windows.processPostedMessages()  -- 关键！确保UI更新
    
    clearlistener()
    
    -- 检查选择集配置
    if export_setsets.count == 0 do (
        messageBox "请先添加导出选择集！" title:"操作中止" 
        return undefined
    )
    
    -- 刷新场景选择集缓存
    refreshSceneSetsCache()
    
    -- 验证选择集有效性
    local validSets = for o in export_setsets where (findItem g_sceneSetsCache o > 0) collect o
    local missingSets = for o in export_setsets where (findItem g_sceneSetsCache o == 0) collect o
    
    -- 单个选择集不存在时立即中断
    if export_setsets.count == 1 and validSets.count == 0 do (
        msg = "选择集 [" + export_setsets[1] + "] 不存在！\n请创建选择集后重试！"
        messageBox msg title:"导出中断"
        return undefined
    )
    
    -- 多选择集部分缺失提示
    if missingSets.count > 0 do (
        missingInfo = "以下选择集不存在：\n" + (join missingSets "\n")
        if queryBox (missingInfo + "\n\n是否继续导出有效选择集？") title:"选择集缺失警告" == false do (
            return undefined
        )
    )
    
    -- 获取当前场景路径并检查有效性
    local exportPath = edtExportPath.text
    if exportPath == undefined or exportPath == "" do (
        messageBox "导出路径未设置！" title:"错误"
        return undefined
    )
    makeDir exportPath all:true  -- 确保目录存在
    
    -- 配置进度条（根据实际有效集数量）
    pbProgress.maximum = validSets.count
    pbProgress.Refresh()
    lblProgressInfo.text = "开始导出当前场景..."
    
    -- 执行导出
    export_mod_fn rdo_exportMode.state
    local successCount = 0
    for i = 1 to validSets.count do (
        -- 检测ESC中断
        if keyboard.escPressed do (
            g_exportAbortFlag = true
            format "[用户中断] 导出进程已被手动终止\n"
            lblProgressInfo.text = "操作已中断！" 
            windows.processPostedMessages()
            messageBox "导出进程已被用户中断！" title:"操作提示" beep:true
            exit  -- 直接退出循环
        )
        
        local setName = validSets[i]
        if selectExportobject setName then (
            local objCount = selection.count  -- 获取当前选择集物体数
            if (export_file maxFilePath setName exportPath) then (
                -- 应用挂点归零
                if auto_socket.checked do resetSocketTransforms()
                successCount += 1
                format "[Object/数量] % → 导出物体: % 个\n" setName objCount  -- 新增物体数显示
                format "[Export//路径] 已导出：% 到 %\n" setName exportPath
            ) else (
                format "[失败] 导出选择集：%\n" setName
            )
            
            pbProgress.value = i
            progressPercent = (100.0 * i / validSets.count) as integer
            lblProgressInfo.text = "进度：" + progressPercent as string + "%"
            windows.processPostedMessages()
        )
        
    )
    
    -- 完成处理（仅在未中断时执行）
    if not g_exportAbortFlag do (
        finalPercent = (100.0 * successCount / validSets.count) as integer
        lblProgressInfo.text = "当前导出场景-完成！！！"+ "-*FBX* →Objects: " + selection.count as string +" 个//Prog-进度：" + finalPercent as string + "%"
        if chk_autoOpenDir.checked do ShellLaunch "explorer.exe" exportPath
        
        -- 异常情况提示
        case of (
            (successCount == 0): (
                messageBox "所有选择集导出失败！" title:"导出结果"
            )
            (successCount < validSets.count): (
                msg = "部分导出成功：\n成功：" + successCount as string + "\n失败：" + (validSets.count - successCount) as string
                messageBox msg title:"导出结果"
            )
        )
    )
    refreshFileListView forceRefresh:true
    -- 重置中断标志并恢复控件
    g_exportAbortFlag = false
    for c in AutoExportTool_Pro.controls do c.enabled = true
)

    ----------------------------------------------------------------
    -- 响应文本变化的实时调整
    on btn_aotu_model text changed newText do updateButtonLayout()
    on btn_exp_M_fbx text changed newText do updateButtonLayout()
    -- 添加常用路径按钮事件
on btnAddLikedDir pressed do (
    createdialog rolAddExportPath pos:mouse.screenpos
)

on btnAddLikedDir rightclick do (
    if ltbLikedDir.selection > 0 do (
        deleteItem iniLikedDir (iniLikedFolder.count + 1 - ltbLikedDir.selection)
        ltbLikedDir.items = for i = iniLikedFolder.count to 1 by -1 collect iniLikedFolder[i].name
        fnSaveConfig()
    )
)

-- 双击常用目录跳转
on ltbLikedDir doubleClicked idx do (
    local dir = iniLikedFolder[iniLikedFolder.count + 1 - idx].dir
    if doesDirectoryExist dir do (
        edtExportPath.text = dir
        model_files_array = #()
        Lv_model.items.clear()
        local maxFiles = getFiles (dir + "\\*.max")
        for f in maxFiles do additem_lv Lv_model f
    )
)
    
on AutoExportTool_Pro close do (
    saveUIConfig()
    setINISetting g_ConfigPath "Layout" "CustomMode" (g_forceCustomLayout as string)
	setINISetting g_ConfigPath "Font" "UseAlternate" (chkChangeFont.checked as string)
    FbxExporterSetParam "ResetExport"  -- 关键修复：关闭时强制重置
    --try(destroyDialog rolVersionManager )catch()   -- false
    
    try(destroyDialog rolXAFEditor)catch()
    try(destroyDialog rolCharacterMapping)catch()   -- true
    try(destroyDialog rolPathManager)catch()   -- true
    
    --try(destroyDialog rolSelSetTools)catch()   -- false / 沉淀代码
    
    try (
        -- 安全停止定时器 ------------------------------------
        if g_refreshTimer != undefined do (
            if g_refreshTimer.Enabled do (
                g_refreshTimer.Stop()
                dotNet.removeAllEventHandlers g_refreshTimer
                format "[调试] 定时器已停止\n"
            )
            g_refreshTimer = undefined  -- 释放引用
        )
    ) catch (
        format "[警告] 定时器关闭异常: %\n" (getCurrentException())
    )
-- 1. 保存用户路径配置
    saveConfig()
  -- 2. 保存窗口位置到独立文件
    try (
        -- 确保窗口位置配置文件目录存在
        local windowPosDir = getFilenamePath g_WindowPosPath
        makeDir windowPosDir all:true
        
        -- 获取并保存当前窗口位置
        local currentPos = GetDialogPos AutoExportTool_Pro
        if classOf currentPos == Point2 do (
            setIniSetting g_WindowPosPath "WindowSettings" "LastPos" (currentPos as string)
            format "[pos配置] 窗口位置已保存到：%\n" g_WindowPosPath
        )
    ) catch (
        format "[警告] 无法保存窗口位置：%\n" (getCurrentException())
    )
    -- 停止文件监控
    try (
        if g_autoSaveWatcher != undefined do (
            g_autoSaveWatcher.EnableRaisingEvents = false
            dotNet.removeAllEventHandlers g_autoSaveWatcher
        )
    ) catch ()
    -- 3. 销毁对话框
    destroyDialog AutoExportTool_Pro
)

--主插件打开/初始化
on AutoExportTool_Pro open do (
    -- 加载自动检查更新设置
    local autoCheckSetting = getINISetting g_UIConfigPath "Settings" "AutoCheckUpdate"
    if autoCheckSetting != "" do (
        g_autoCheckUpdate = (autoCheckSetting == "true")
    )
    
    -- 自动检查更新（如果不是静默模式）
    if g_autoCheckUpdate do (
        checkForUpdates silent:true
    )
    
    -- 添加插件恢复检查
    try (
        if not doesFileExist g_pluginPath and doesFileExist g_backupPluginPath do (
            -- 从备份恢复插件
            makeDir (getFilenamePath g_pluginPath) all:true
            copyFile g_backupPluginPath g_pluginPath
            format "[恢复] 插件已从备份恢复: %\n" g_pluginPath
        )
    )
    catch (
        format "[插件恢复错误] %\n" (getCurrentException())
    )
    
    loadCharacterMappings()
    checkAndRecoverPlugin()
    -- 设置拖动区域的样式
    lblTitle.text = "🖱️ Mouse ⇆ ⇳​ Move - 👆 拖拽此处移动窗口"
    lblTitle.backColor = (dotNetClass "System.Drawing.Color").FromArgb 50 50 50
    lblTitle.foreColor = (dotNetClass "System.Drawing.Color").FromArgb 220 220 255
    lblTitle.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
    lblTitle.Font = dotNetObject "System.Drawing.Font" "Microsoft YaHei UI" 10 ((dotNetClass "System.Drawing.FontStyle").Bold)
    lblTitle.Cursor = (dotNetClass "System.Windows.Forms.Cursors").SizeAll
    
    -- 1. 确保配置文件存在----------------------------------------
        local configDir = getFilenamePath g_UIConfigPath
        makeDir configDir all:true  -- 创建配置目录
        
    -- 确保INI存在
    try (
        -- 1. 配置文件初始化---------------------------------------
        if not doesFileExist g_UIConfigPath do (
            -- 创建配置文件并写入默认值
            makeDir (getFilenamePath g_UIConfigPath) all:true
            setINISetting g_UIConfigPath "Settings" "BgGrayValue" "45"
            format "[初始化] 创建新配置文件：%\n" g_UIConfigPath
            
            -- 立即应用硬编码默认值
            sldBgColor.value = 45
            Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 45 45 45
        )
        
        -- 2. 加载核心配置-----------------------------------------
        loadConfig()   -- 加载文件路径；常用目录..等配置 /（中文兼容）
        loadUIConfig() -- 加载UI配置（必须在其他UI操作前调用）
         -- 修复背景色初始化
        local bgValue = executeSafe (getINISetting g_UIConfigPath "Settings" "BgGrayValue") g_defaultBgValue
        bgValue = amax 0 (amin 255 bgValue)
        sldBgColor.value = bgValue
        setBackgroundColor bgValue  -- 确保调用设置函数
        -- 3. UI初始化---------------------------------------------
        adjustColumnWidths forceCustom:chkChangeFont.checked
        Lv_model.Font = if chkChangeFont.checked then g_alternateFont else g_defaultFont
        
        -- 4. 最终验证---------------------------------------------
        format "[UI初始化完成] 当前滑块值：% | 背景色：%\n" \
            sldBgColor.value \
            Lv_model.BackColor.ToString()
    )
    catch (
        format "[初始化错误] %\n" (getCurrentException())
    )
    
    --local fontState = getINISetting g_ConfigPath "Font" "UseAlternate" / false
    --chkChangeFont.checked = if fontState == "true" then true else false /false
    
    chkChangeFont.checked = true  -- 覆盖INI配置，强制勾选
    g_forceCustomLayout = true    -- 同步全局状态
    adjustColumnWidths forceCustom:true -- 立即应用列宽
    Lv_model.Font = g_alternateFont     -- 强制应用字体
  
    -- 设置滑条初始值与列表背景同步 / false / 沉淀代码
    --sldBgColor.value = 55
    --Lv_model.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 55  55  55

    -- 动态绑定函数到Rollout / false / 沉淀代码
    --AutoExportTool_Pro.getProcessFiles = getProcessFiles
    --AutoExportTool_Pro.batchProcessSelSets = batchProcessSelSets

    --常用目录的核心下拉列表更新 / true 
    ddlLikedPaths.items = for f in g_likedFolders collect f.name
    --loadRecentFiles()
    
    --读取窗口位置--位置记忆（open）-- true--验证实现
     -- 定义默认位置--修复窗口位置--初始化无法恢复（一闪而过的问题）
    local defaultPos = [100, 100]
    --local g_ConfigPath = (getDir #scripts) + "\\FBX_ExporTools_UserPath.ini"
    local iniPath = (getDir #maxData) + "\\AutoExportTool_Pro.ini"
    
    -- 检查INI文件是否存在，若不存在则创建
    if not doesFileExist iniPath do (
        makeDir (getFilenamePath iniPath) all:true  -- 确保目录存在
        setIniSetting iniPath "Settings" "LastPos" (defaultPos as string)  -- 写入默认值
    )
    
    -- 读取位置信息并验证
    try (
        local posStr = getIniSetting g_WindowPosPath "WindowSettings" "LastPos"
        if posStr != "" do (
            local pos = execute ("(" + posStr + ")")
            if classOf pos == Point2 do (
                SetDialogPos AutoExportTool_Pro pos
                format "[信息] 已恢复窗口位置：%\n" pos
            )
        )
    ) catch (
        format "[警告] 加载窗口位置失败：%\n" (getCurrentException())
        
        SetDialogPos AutoExportTool_Pro defaultPos  -- 回退到默认位置
        setIniSetting iniPath "Settings" "LastPos" (defaultPos as string)  -- 修复INI文件
		)
	
        --日期时间显示--年/月/星期/时，分，秒 
	try (
            fnRefreshDate()  -- 初始显示
        -- 添加定时刷新（每秒更新）----------------------------------------
        global refreshTimer = dotNetObject "System.Windows.Forms.Timer"
        refreshTimer.Interval = 1000
        dotNet.addEventHandler refreshTimer "Tick" fnRefreshDate
        refreshTimer.Start()
        ) catch (
            lblDateTime.text = "时间模块初始化失败"
		  )   
        -- 初始化自动保存监控
    try (
        g_autoSaveWatcher = dotNetObject "System.IO.FileSystemWatcher"
        g_autoSaveWatcher.Path = g_autoSavePath
        g_autoSaveWatcher.Filter = "*.max"
        g_autoSaveWatcher.EnableRaisingEvents = true
        
        -- 文件创建事件处理
        dotNet.addEventHandler g_autoSaveWatcher "Created" (fn s e = (
            -- 延迟确保文件写入完成 / false 
            --dotNet.invokeMethod (dotnetclass "System.Threading.Thread") "Sleep" 1000
            --dotNetClass "System.Threading.Thread").Sleep(1000)
            dotNet.invokeMethod (dotNetClass "System.Threading.Thread") "Sleep" #(1000)
            -- 添加到列表
            if doesFileExist e.FullPath do (
                additem_lv Lv_model e.FullPath
            )
        ))
    ) catch (
        format "[错误] 自动保存监控初始化失败: %\n" (getCurrentException())
    )
        
        -- 强制初始化关键变量
        model_files_array = #()  -- 清空文件数组
        edtExportPath.text = getDir #scene  -- 重置为有效路径
        g_showRecentFiles = false  -- 确保初始为普通模式
        -- 强制设置初始滚动模式
        --Lv_model.HorizontalScrollable = false -- 显式禁用水平滚动
        Lv_model.Scrollable = false
        Lv_model.Scrollable = true -- 允许垂直滚动
        start_Lv_model()            -- ex file list 导出列表 / 默认 通用ListView / 列表刷新
        initLvModel()                -- 默认 通用ListView / ​列定义与配置 / ​​初始化 ListView（列表视图）数据模型​​ 的函数，主要处理 ​​数据加载、格式转换​​ 和 ​​UI 绑定​​
	    -- 带安全检查的列宽调整
        if Lv_model.Columns.count >= 3 do (
            adjustColumnWidths forceCustom:g_forceCustomLayout
        )
        
        -- 强制应用字体状态
        Lv_model.Font = if chkChangeFont.checked then g_alternateFont else g_defaultFont
        
        initlvHeader()
        lvHeader.Columns.Item[2].Width = if chkChangeFont.checked then 145 else 125
		--lvHeader.Columns.Item[2].Width = 125 -- 直接设置类型列宽
		initModeStatus()
        lblCount.text = "文件：0"  -- 强制初始为0
        
        updateModeStatus()  -- 更新 事件 ACT ''注释'' / 列表文件位置名称 / 文件计数 = 状态栏
        
        -- 强制创建初始状态项
        if ModeStatus.Items.Count == 0 do (
        local li = dotNetObject "System.Windows.Forms.ListViewItem" "初始化..."
        li.SubItems.Add("")
        li.SubItems.Add("文件：0")
        ModeStatus.Items.Add li
        ModeStatus.Refresh()
        )
        
        isValidScene()             --  插件初始化时检查场景基础条件/批量处理前的安全验证/自动保存前的状态检查/场景导入;导出前的合规性检测
        
        initPluginSystem()         --  checkbox 勾选盒子
        
        updateButtonLayout()       -- ListView 自适应/宽高
        
        updateExportPath()         --  导出/保存路径
        checkAndRecoverPlugin()    -- 恢复 备份路径
        createBackup()             --  拖入并同时备份主插件到一个备份目录地址/功能/防止 拖入 位置意外 删除 工具栏 打开 主插件 无法读取的情况 
        savePluginPath()           -- 记录 插件默认 打开 - （插件文件位置 ）          
        
        initAutoStartSetting()     -- 跟随MAX 自启 设置   -  （检测 记录读取 自启 勾选状态）
        initToolbarSetting()       -- 外部 工具栏 MAX 菜单  -  （检测是否 添加 工具栏 - 联动 主插件 工具栏添加状态）
        --首次添加 工具栏 /检测/记录/读取
        autoAddToolbarOnFirstRun() 
        --刷新 选择集
        GetSetFormScene()
        --刷新 日期
        fnRefreshDate ()
        
        pbProgress.style = (dotNetClass "System.Windows.Forms.ProgressBarStyle").Continuous  --  进度条dotNet-UI控件
        
        -- 列表主更新/刷新
        refreshFileListView()
        setupFileOpenCallback()
        -- 预加载最近文件列表
        loadRecentFilesFromXML()
        initAutoSaveWatcher() -- 确保在open事件中初始化监控
        format "[最近文件初始化] 预加载最近文件数：%\n" g_recentFiles.count
        -- 调用文件属性初始化
        setupContextMenu()
        -- 初始化键盘事件 / false （未实现参数）
        --initKeyboardEvents()
        -- 双重验证复选框状态
        if chkChangeFont.checked do (
        Lv_model.Font = g_alternateFont
        adjustColumnWidths forceCustom:true
        )

        format "[初始化] 界面加载完成.\n"
	)

)


-- 创建插件主窗口 /  无边框 显示 模式 / 增加 catch 防御性 / 创建 插件菜单UI 主框架 / MainScript createDialog  AutoExportTool_Pro 
-- 获取3ds Max版本信息 (针对3ds Max 2014的特定行为，同时保持其他版本的稳定性，规避异常弹窗msbox改为fomat)
maxVersionInfo = maxVersion()
maxMajorVersion = maxVersionInfo[1]  -- 主版本号

if maxMajorVersion == 16 then (  -- 16对应3ds Max 2014
    -- 2014版本直接创建对话框
    createDialog AutoExportTool_Pro style:#() modal:false
) else (
    -- 其他版本使用带错误处理的创建方式
    try (
        createDialog AutoExportTool_Pro style:#() modal:false
    ) catch (
        format "创建对话框时出错，请检查脚本!(max2014环境开启插件虚假出错，只要插件界面正常显示就无需理会...)"
    )
)