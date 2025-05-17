#SingleInstance force  ; 强制单实例运行
#Persistent            ; 保持脚本持续运行
Menu, Tray, Tip, ShowtitlebarV2  ; 设置托盘图标的悬浮提示文本

; ====================== 全局变量声明 ======================
global IsScriptEnabled := true       ; 脚本总开关状态
global IsDragModeActive := false     ; 拖动模式激活标志
global IsDragging := false           ; 正在拖动窗口标志
global TargetWinID := 0              ; 当前目标窗口ID
global DragStartX, DragStartY        ; 拖动起始坐标（鼠标）
global DragWinX, DragWinY            ; 拖动起始坐标（窗口）
global g_hOverlayGui := 0            ; 透明覆盖层窗口句柄
global FirstTime := true

; ====================== 托盘菜单设置 ======================
Menu, Tray, NoStandard  ; 清除默认菜单项

; 添加自定义菜单项
Menu, Tray, Add, 启用脚本, ToggleScript
Menu, Tray, Check, 启用脚本  ; 初始状态设为选中(打钩)
Menu, Tray, Add  ; 添加分隔线
Menu, Tray, Add, 关于, ShowAbout
Menu, Tray, Add, 退出, ExitScript
Menu, Tray, Default, 启用脚本  ; 设置默认选项（双击托盘图标触发）

; ====================== 窗口风格调整快捷键 ======================
!^f::  ; Alt+Ctrl+F - 启用窗口调整（添加标题栏和边框）
    if (!IsScriptEnabled || IsDragModeActive)  ; 检查脚本状态
        return
    
    WinGet, activeWin, ID, A  ; 获取活动窗口ID
    
    ; 添加窗口样式标志
    WinSet, Style, +0xC00000, ahk_id %activeWin%  ; 添加WS_CAPTION（标题栏）
    WinSet, Style, +0x40000, ahk_id %activeWin%   ; 添加WS_SIZEBOX（可调整大小边框）
    WinSet, Style, +0x20000, ahk_id %activeWin%   ; 添加WS_MINIMIZEBOX（最小化按钮）
    WinSet, Style, +0x10000, ahk_id %activeWin%   ; 添加WS_MAXIMIZEBOX（最大化按钮）
    
    ForceShowBorder("enable", activeWin)  ; 强制刷新边框显示
return

!^h::  ; Alt+Ctrl+H - 禁用窗口调整（移除标题栏和边框）
    if (!IsScriptEnabled || IsDragModeActive)  ; 检查脚本状态
        return
    
    WinGet, activeWin, ID, A  ; 获取活动窗口ID
    
    ; 移除窗口样式标志
    WinSet, Style, -0xC00000, ahk_id %activeWin%  ; 移除WS_CAPTION
    WinSet, Style, -0x40000, ahk_id %activeWin%   ; 移除WS_SIZEBOX
    WinSet, Style, -0x20000, ahk_id %activeWin%   ; 移除WS_MINIMIZEBOX
    WinSet, Style, -0x10000, ahk_id %activeWin%   ; 移除WS_MAXIMIZEBOX
    
    ForceShowBorder("disable", activeWin)  ; 强制刷新边框显示
return

; ====================== 窗口拖动功能 ======================
!^g::  ; Alt+Ctrl+G - 切换拖动模式
    if (!IsScriptEnabled)  ; 检查脚本是否启用
        return
    
    IsDragModeActive := !IsDragModeActive  ; 切换拖动模式状态
    
    if (IsDragModeActive) {
        ; 进入拖动模式流程 ------
        ; 第一次进入时显示提示
        if (FirstTime = true) {
            MsgBox, 64, 拖动模式, 拖动模式激活 (左键按住拖动，Alt+Ctrl+G 退出)
            FirstTime := false  ; 下次不会再提示
        }
        WinGet, TargetWinID, ID, A  ; 获取当前活动窗口ID
        if !TargetWinID {  ; 如果没有活动窗口则退出
            IsDragModeActive := false
            return
        }
        CreateOverlay()  ; 创建透明覆盖层拦截鼠标
        
        ; 设置移动光标样式
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32646, "ptr"))  ; IDC_SIZEALL (四向箭头)
        
        ; 注册鼠标热键
        Hotkey, ~LButton, DragStartHandler, On     ; 左键按下处理
        Hotkey, ~LButton Up, DragEndHandler, On    ; 左键释放处理
        
    } else {
        ; 退出拖动模式流程 ------
        DestroyOverlay()  ; 销毁透明覆盖层
        
        ; 注销鼠标热键
        Hotkey, ~LButton, Off
        Hotkey, ~LButton Up, Off
        
        ; 重置状态
        IsDragging := false
        TargetWinID := 0
        ToolTip,,,, 1  ; 关闭提示
        
        ; 恢复默认光标
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32512, "ptr"))  ; IDC_ARROW (标准箭头)
    }
return

; ====================== 透明覆盖层相关函数 ======================
CreateOverlay() {
    global g_hOverlayGui
    
    Gui, Overlay:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Overlay:Color, FFFFFF
    Gui, Overlay:Font, s1
    Gui, Overlay:+LastFound
    WinSet, Transparent, 1
    WinSet, ExStyle, +0x20  ; 添加WS_EX_TRANSPARENT
    WinSet, ExStyle, -0x20  ; 移除WS_EX_TRANSPARENT
    
    ; 显示全屏窗口
    Gui, Overlay:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight% NoActivate
    WinGet, g_hOverlayGui, ID, A
}

DestroyOverlay() {
    global g_hOverlayGui
    
    if (g_hOverlayGui) {
        Gui, Overlay:Destroy
        g_hOverlayGui := 0
    }
}

; ====================== 拖动事件处理函数 ======================
DragStartHandler:
    if (!IsDragModeActive || !TargetWinID)  ; 安全检查
        return
    
    ; 记录初始位置信息
    WinGetPos, winX, winY,,, ahk_id %TargetWinID%  ; 获取窗口当前位置
    MouseGetPos, mouseX, mouseY           ; 获取鼠标当前位置
    
    DragStartX := mouseX  ; 鼠标起始X
    DragStartY := mouseY  ; 鼠标起始Y
    DragWinX := winX      ; 窗口起始X
    DragWinY := winY      ; 窗口起始Y
    
    IsDragging := true  ; 标记为正在拖动
    
    ; 启动定时器立即更新窗口位置
    SetTimer, UpdateWindowPosition, -1
return

DragEndHandler:
    IsDragging := false          ; 标记拖动结束
    SetTimer, UpdateWindowPosition, Off  ; 停止定时器
return

UpdateWindowPosition:
    if (!IsDragging || !TargetWinID)  ; 安全检查
        return
    
    MouseGetPos, mouseX, mouseY  ; 获取当前鼠标位置
    
    ; 计算新位置
    newX := mouseX - (DragStartX - DragWinX)
    newY := mouseY - (DragStartY - DragWinY)
    
    WinMove, ahk_id %TargetWinID%,, newX, newY  ; 移动目标窗口
    
    ; 如果仍在拖动状态，10ms后继续更新
    if (IsDragging)
        SetTimer, UpdateWindowPosition, -10
return

; ====================== 辅助工具函数 ======================
ForceShowBorder(action, WinID) {
    WinGetPos, X, Y, W, H, ahk_id %WinID%  ; 获取当前尺寸
    
    if (action = "enable") {
        WinSet, Style, +0x40000, ahk_id %WinID%  ; 添加WS_SIZEBOX
        WinGet, winStyle, Style, ahk_id %WinID%  ; 获取窗口样式
        if !(winStyle & 0xC00000)  ; 如果无标题栏
            WinSet, Style, +0x00800000, ahk_id %WinID%  ; 添加WS_BORDER
    } else {
        WinSet, Style, -0x00800000, ahk_id %WinID%  ; 移除WS_BORDER
    }
    
    ; 通过临时调整窗口大小强制重绘
    WinMove, ahk_id %WinID%,, X, Y, W+1, H+1  ; 先稍微增大
    WinMove, ahk_id %WinID%,, X, Y, W, H      ; 再恢复原尺寸
}
; ====================== 菜单项功能函数 ======================
ToggleScript:
    IsScriptEnabled := !IsScriptEnabled  ; 切换状态
    
    ; 更新菜单项状态和图标
    if (IsScriptEnabled) {
        Menu, Tray, Check, 启用脚本  ; 添加对勾
    } else {
        Menu, Tray, Uncheck, 启用脚本  ; 移除对勾
        
        ; 禁用时清理拖动模式
        if (IsDragModeActive) {
            DestroyOverlay()  ; 移除透明层
            
            ; 注销热键
            Hotkey, ~LButton, Off
            Hotkey, ~LButton Up, Off
            
            ; 重置状态
            IsDragModeActive := false
            IsDragging := false
            SetTimer, UpdateWindowPosition, Off  ; 停止定时器
        }
    }
return

ShowAbout:
    MsgBox, 64, 关于 无边框窗口控制,
    (
无边框窗口控制
---------------------------------
    功能说明：
Alt+Ctrl+F = 有边框+调整窗口
Alt+Ctrl+H = 无边框
Alt+Ctrl+G = 窗口拖动模式
---------------------------------
版本：AutoHotkey V1(V1.5)
作者：Little-data
GitHub：https://github.com/Little-Data/showtitlebar-v2
原作者：WindowsTime
    )
return

ExitScript:
    if (g_hOverlayGui)  ; 清理透明层
        DestroyOverlay()
    ExitApp  ; 退出程序
return
