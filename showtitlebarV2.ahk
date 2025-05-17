#SingleInstance force  ; 强制单实例运行，如有新实例则自动替换旧实例
#Requires AutoHotkey v2.0  ; 要求使用AHK v2.0或更高版本
A_IconTip := "ShowtitlebarV2"  ; 设置托盘图标的悬浮提示文本
Persistent()  ; 保持脚本持续运行（防止自动退出）

; ====================== 全局变量声明 ======================
global IsScriptEnabled := true       ; 脚本总开关状态
global IsDragModeActive := false     ; 拖动模式激活标志
global IsDragging := false           ; 正在拖动窗口标志
global TargetWinID := 0              ; 当前目标窗口ID
global DragStartX, DragStartY        ; 拖动起始坐标（鼠标）
global DragWinX, DragWinY            ; 拖动起始坐标（窗口）
global g_hOverlayGui := 0            ; 透明覆盖层窗口句柄

; ====================== 托盘菜单设置 ======================
Tray := A_TrayMenu  ; 获取系统托盘菜单对象
Tray.Delete()       ; 清除默认菜单项

; 添加自定义菜单项
Tray.Add("启用脚本", ToggleScript)  ; 添加启用/禁用切换菜单项
Tray.Check("启用脚本")              ; 初始状态设为选中(打钩)
Tray.Add()                         ; 添加分隔线
Tray.Add("关于", ShowAbout)        ; 添加关于对话框菜单项
Tray.Add("退出", ExitScript)       ; 添加退出脚本菜单项
Tray.Default := "启用脚本" ; 设置默认选项（双击托盘图标触发）

; ====================== 窗口风格调整快捷键 ======================
; Alt+Ctrl+F - 启用窗口调整（添加标题栏和边框）
!^f:: {
    if (!IsScriptEnabled || IsDragModeActive)  ; 检查脚本状态
        return
    
    ; 添加窗口样式标志
    WinSetStyle("+0xC00000", "A")  ; 添加WS_CAPTION（标题栏）
    WinSetStyle("+0x40000", "A")   ; 添加WS_SIZEBOX（可调整大小边框）
    WinSetStyle("+0x20000", "A")   ; 添加WS_MINIMIZEBOX（最小化按钮）
    WinSetStyle("+0x10000", "A")   ; 添加WS_MAXIMIZEBOX（最大化按钮）
    ForceShowBorder("enable")      ; 强制刷新边框显示
}

; Alt+Ctrl+H - 禁用窗口调整（移除标题栏和边框）
!^h:: {
    if (!IsScriptEnabled || IsDragModeActive)  ; 检查脚本状态
        return
    
    ; 移除窗口样式标志
    WinSetStyle("-0xC00000", "A")  ; 移除WS_CAPTION
    WinSetStyle("-0x40000", "A")   ; 移除WS_SIZEBOX
    WinSetStyle("-0x20000", "A")   ; 移除WS_MINIMIZEBOX
    WinSetStyle("-0x10000", "A")   ; 移除WS_MAXIMIZEBOX
    ForceShowBorder("disable")     ; 强制刷新边框显示
}

; ====================== 窗口拖动功能 ======================
; Alt+Ctrl+G - 切换拖动模式
!^g:: {
    global IsDragModeActive, IsDragging, TargetWinID, g_hOverlayGui
    
    if (!IsScriptEnabled)  ; 检查脚本是否启用
        return
    
    IsDragModeActive := !IsDragModeActive  ; 切换拖动模式状态
    
    if (IsDragModeActive) {
        ; 进入拖动模式流程 ------
        TargetWinID := WinExist("A")  ; 获取当前活动窗口ID
        if !TargetWinID {  ; 如果没有活动窗口则退出
            IsDragModeActive := false
            return
        }
        
        CreateOverlay()  ; 创建透明覆盖层拦截鼠标
        
        ; 设置移动光标样式
        try DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32646, "ptr"))  ; IDC_SIZEALL (四向箭头)
        
        ToolTip("拖动模式激活 (左键按住拖动，Alt+Ctrl+G 退出)",,, 1)  ; 显示提示
        
        ; 注册鼠标热键挂钩
        Hotkey "~LButton", DragStartHandler, "On"     ; 左键按下处理
        Hotkey "~LButton Up", DragEndHandler, "On"    ; 左键释放处理
        
    } else {
        ; 退出拖动模式流程 ------
        DestroyOverlay()  ; 销毁透明覆盖层
        
        ; 注销鼠标热键
        Hotkey "~LButton", "Off"
        Hotkey "~LButton Up", "Off"
        
        ; 重置状态
        IsDragging := false
        TargetWinID := 0
        ToolTip(,,, 1)  ; 关闭提示
        
        ; 恢复默认光标
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32512, "ptr"))  ; IDC_ARROW (标准箭头)
    }
}

; ====================== 透明覆盖层相关函数 ======================
; 创建透明覆盖层窗口
CreateOverlay() {
    global g_hOverlayGui
    
    ; 创建GUI对象（置顶、无标题栏、作为子窗口、工具窗口样式）
    g_hOverlayGui := Gui("+AlwaysOnTop -Caption +Owner +ToolWindow +E0x20")
    g_hOverlayGui.BackColor := "FFFFFF"  ; 设置背景色（实际透明不可见）
    g_hOverlayGui.SetFont("s1")          ; 最小化字体大小（节省资源）
    g_hOverlayGui.Opt("+LastFound")      ; 使窗口成为LastFound窗口
    
    WinSetTransparent(1)  ; 设置完全透明（1-255透明度，1为几乎不可见）
    
    ; 显示全屏窗口（不激活）
    g_hOverlayGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")
    
    ; 特殊设置：先启用再禁用透明属性，确保完全拦截输入
    WinSetExStyle("+0x20", g_hOverlayGui.Hwnd)  ; 添加WS_EX_TRANSPARENT（允许鼠标穿透）
    WinSetExStyle("-0x20", g_hOverlayGui.Hwnd)  ; 移除WS_EX_TRANSPARENT（禁止鼠标穿透）
}

; 销毁透明覆盖层
DestroyOverlay() {
    global g_hOverlayGui
    
    if (g_hOverlayGui) {
        g_hOverlayGui.Destroy()  ; 销毁GUI对象
        g_hOverlayGui := 0       ; 重置句柄
    }
}

; ====================== 拖动事件处理函数 ======================
; 开始拖动处理（左键按下）
DragStartHandler(*) {
    global IsDragging, DragStartX, DragStartY, DragWinX, DragWinY, TargetWinID
    
    if (!IsDragModeActive || !TargetWinID)  ; 安全检查
        return
    
    ; 记录初始位置信息
    WinGetPos(&winX, &winY,,, TargetWinID)  ; 获取窗口当前位置
    MouseGetPos(&mouseX, &mouseY)           ; 获取鼠标当前位置
    
    DragStartX := mouseX  ; 鼠标起始X
    DragStartY := mouseY  ; 鼠标起始Y
    DragWinX := winX      ; 窗口起始X
    DragWinY := winY      ; 窗口起始Y
    
    IsDragging := true  ; 标记为正在拖动
    
    ; 启动定时器立即更新窗口位置（负值表示只执行一次）
    SetTimer(UpdateWindowPosition, -1)
}

; 结束拖动处理（左键释放）
DragEndHandler(*) {
    global IsDragging
    
    IsDragging := false          ; 标记拖动结束
    SetTimer(UpdateWindowPosition, 0)  ; 停止定时器
}

; 窗口位置更新函数（由定时器定期调用）
UpdateWindowPosition() {
    global IsDragging, DragStartX, DragStartY, DragWinX, DragWinY, TargetWinID
    
    if (!IsDragging || !TargetWinID)  ; 安全检查
        return
    
    MouseGetPos(&mouseX, &mouseY)  ; 获取当前鼠标位置
    
    ; 计算新位置（两种算法）
    newX := DragWinX + (mouseX - DragStartX)  ; 方法1：基于位移差
    newY := DragWinY + (mouseY - DragStartY)
    
    ; 方法2：相对坐标计算（减少抖动）
    newX := mouseX - (DragStartX - DragWinX)
    newY := mouseY - (DragStartY - DragWinY)
    
    try {
        WinMove(newX, newY,,, TargetWinID)  ; 移动目标窗口
    }
    
    ; 如果仍在拖动状态，10ms后继续更新（负值确保单次执行）
    if (IsDragging)
        SetTimer(UpdateWindowPosition, -10)
}

; ====================== 辅助工具函数 ======================
; 强制显示/隐藏窗口边框（通过重绘窗口）
ForceShowBorder(action) {
    WinID := WinExist("A")  ; 获取活动窗口
    WinGetPos(&X, &Y, &W, &H, WinID)  ; 获取当前尺寸
    
    if (action = "enable") {
        WinSetStyle("+0x40000", WinID)  ; 添加WS_SIZEBOX（可调整大小边框）
        if (!(WinGetStyle(WinID) & 0xC00000))  ; 如果无标题栏
            WinSetStyle("+0x00800000", WinID)  ; 添加WS_BORDER（细边框）
    } else {
        WinSetStyle("-0x00800000", WinID)  ; 移除WS_BORDER
    }
    
    ; 通过临时调整窗口大小强制重绘
    try {
        WinMove(X, Y, W+1, H+1, WinID)  ; 先稍微增大
        WinMove(X, Y, W, H, WinID)      ; 再恢复原尺寸
    }
}

; ====================== 菜单项功能函数 ======================
; 切换脚本启用状态
ToggleScript(ItemName, ItemPos, MyMenu) {
    global IsScriptEnabled, IsDragModeActive, IsDragging, g_hOverlayGui
    
    IsScriptEnabled := !IsScriptEnabled  ; 切换状态
    
    ; 更新菜单项状态和图标
    if (IsScriptEnabled) {
        Tray.Check("启用脚本")  ; 添加对勾
        Tray.Icon := "shell32.dll, 110"  ; 绿色勾图标
    } else {
        Tray.Uncheck("启用脚本")  ; 移除对勾
        Tray.Icon := "shell32.dll, 131"  ; 红色叉图标
    }
    
    ; 禁用时清理拖动模式
    if (!IsScriptEnabled && IsDragModeActive) {
        DestroyOverlay()  ; 移除透明层
        
        ; 注销热键
        Hotkey "~LButton", "Off"
        Hotkey "~LButton Up", "Off"
        
        ; 重置状态
        IsDragModeActive := false
        IsDragging := false
        SetTimer(UpdateWindowPosition, 0)  ; 停止定时器
        ToolTip(,,, 1)  ; 关闭提示
    }
}

; 显示关于对话框
ShowAbout(*) {
    MsgBox(
        "无边框窗口控制`n"
        "---------------------------------`n"
        "`t功能说明：`n"
        "Alt+Ctrl+F = 有边框+调整窗口`n"
        "Alt+Ctrl+H = 无边框`n"
        "Alt+Ctrl+G = 窗口拖动模式`n"
        "---------------------------------`n"
        "版本：v1.5`n"
        "作者：Little-data`n"
        "GitHub：https://github.com/Little-Data/showtitlebar-v2`n"
        "原作者：WindowsTime`n",
        "关于 无边框窗口控制",
        "Iconi"
    )
}

; 退出脚本
ExitScript(*) {
    global g_hOverlayGui
    
    try {
        if (g_hOverlayGui)  ; 清理透明层
            DestroyOverlay()
    }
    ExitApp  ; 退出程序
}