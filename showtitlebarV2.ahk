#Requires AutoHotkey v2.0
Persistent()

; 初始化托盘菜单
Tray := A_TrayMenu
Tray.Delete()
Tray.Add("禁用脚本", ToggleScript)
Tray.Add()
Tray.Add("关于", ShowAbout)
Tray.Add("退出", ExitScript)
Tray.Default := "禁用脚本"

IsScriptEnabled := true

!^f:: {
    if (IsScriptEnabled)
        try WinSetStyle("+0xC00000", "A")
}

!^h:: {
    if (IsScriptEnabled)
        try WinSetStyle("-0xC00000", "A")
}

ToggleScript(*) {
    global IsScriptEnabled
    IsScriptEnabled := !IsScriptEnabled
    Tray.ToggleCheck("禁用脚本")
    iconFile := IsScriptEnabled ? "shell32.dll, 110" : "shell32.dll, 131"
}

ShowAbout(*) {
    MsgBox(
        "无边框窗口控制`n"
        "---------------------------------`n"
        "`t功能说明：`n"
        "Alt+Ctrl+F = 显示标题栏`n"
        "Alt+Ctrl+H = 隐藏标题栏`n"
        "---------------------------------`n"
        "版本：v1.0`n"
        "作者：Little-data`n"
        "GitHub：https://github.com/Little-Data/showtitlebar-v2`n"
        "原作者：WindowsTime`n",
        "关于 无边框窗口控制",
        "Iconi"
    )
}

ExitScript(*) {
    ExitApp
}
