#SingleInstance force  ; ǿ�Ƶ�ʵ������
#Persistent            ; ���ֽű���������
Menu, Tray, Tip, ShowtitlebarV2  ; ��������ͼ���������ʾ�ı�

; ====================== ȫ�ֱ������� ======================
global IsScriptEnabled := true       ; �ű��ܿ���״̬
global IsDragModeActive := false     ; �϶�ģʽ�����־
global IsDragging := false           ; �����϶����ڱ�־
global TargetWinID := 0              ; ��ǰĿ�괰��ID
global DragStartX, DragStartY        ; �϶���ʼ���꣨��꣩
global DragWinX, DragWinY            ; �϶���ʼ���꣨���ڣ�
global g_hOverlayGui := 0            ; ͸�����ǲ㴰�ھ��
global FirstTime := true

; ====================== ���̲˵����� ======================
Menu, Tray, NoStandard  ; ���Ĭ�ϲ˵���

; ����Զ���˵���
Menu, Tray, Add, ���ýű�, ToggleScript
Menu, Tray, Check, ���ýű�  ; ��ʼ״̬��Ϊѡ��(��)
Menu, Tray, Add  ; ��ӷָ���
Menu, Tray, Add, ����, ShowAbout
Menu, Tray, Add, �˳�, ExitScript
Menu, Tray, Default, ���ýű�  ; ����Ĭ��ѡ�˫������ͼ�괥����

; ====================== ���ڷ�������ݼ� ======================
!^f::  ; Alt+Ctrl+F - ���ô��ڵ�������ӱ������ͱ߿�
    if (!IsScriptEnabled || IsDragModeActive)  ; ���ű�״̬
        return
    
    WinGet, activeWin, ID, A  ; ��ȡ�����ID
    
    ; ��Ӵ�����ʽ��־
    WinSet, Style, +0xC00000, ahk_id %activeWin%  ; ���WS_CAPTION����������
    WinSet, Style, +0x40000, ahk_id %activeWin%   ; ���WS_SIZEBOX���ɵ�����С�߿�
    WinSet, Style, +0x20000, ahk_id %activeWin%   ; ���WS_MINIMIZEBOX����С����ť��
    WinSet, Style, +0x10000, ahk_id %activeWin%   ; ���WS_MAXIMIZEBOX����󻯰�ť��
    
    ForceShowBorder("enable", activeWin)  ; ǿ��ˢ�±߿���ʾ
return

!^h::  ; Alt+Ctrl+H - ���ô��ڵ������Ƴ��������ͱ߿�
    if (!IsScriptEnabled || IsDragModeActive)  ; ���ű�״̬
        return
    
    WinGet, activeWin, ID, A  ; ��ȡ�����ID
    
    ; �Ƴ�������ʽ��־
    WinSet, Style, -0xC00000, ahk_id %activeWin%  ; �Ƴ�WS_CAPTION
    WinSet, Style, -0x40000, ahk_id %activeWin%   ; �Ƴ�WS_SIZEBOX
    WinSet, Style, -0x20000, ahk_id %activeWin%   ; �Ƴ�WS_MINIMIZEBOX
    WinSet, Style, -0x10000, ahk_id %activeWin%   ; �Ƴ�WS_MAXIMIZEBOX
    
    ForceShowBorder("disable", activeWin)  ; ǿ��ˢ�±߿���ʾ
return

; ====================== �����϶����� ======================
!^g::  ; Alt+Ctrl+G - �л��϶�ģʽ
    if (!IsScriptEnabled)  ; ���ű��Ƿ�����
        return
    
    IsDragModeActive := !IsDragModeActive  ; �л��϶�ģʽ״̬
    
    if (IsDragModeActive) {
        ; �����϶�ģʽ���� ------
        ; ��һ�ν���ʱ��ʾ��ʾ
        if (FirstTime = true) {
            MsgBox, 64, �϶�ģʽ, �϶�ģʽ���� (�����ס�϶���Alt+Ctrl+G �˳�)
            FirstTime := false  ; �´β�������ʾ
        }
        WinGet, TargetWinID, ID, A  ; ��ȡ��ǰ�����ID
        if !TargetWinID {  ; ���û�л�������˳�
            IsDragModeActive := false
            return
        }
        CreateOverlay()  ; ����͸�����ǲ��������
        
        ; �����ƶ������ʽ
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32646, "ptr"))  ; IDC_SIZEALL (�����ͷ)
        
        ; ע������ȼ�
        Hotkey, ~LButton, DragStartHandler, On     ; ������´���
        Hotkey, ~LButton Up, DragEndHandler, On    ; ����ͷŴ���
        
    } else {
        ; �˳��϶�ģʽ���� ------
        DestroyOverlay()  ; ����͸�����ǲ�
        
        ; ע������ȼ�
        Hotkey, ~LButton, Off
        Hotkey, ~LButton Up, Off
        
        ; ����״̬
        IsDragging := false
        TargetWinID := 0
        ToolTip,,,, 1  ; �ر���ʾ
        
        ; �ָ�Ĭ�Ϲ��
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32512, "ptr"))  ; IDC_ARROW (��׼��ͷ)
    }
return

; ====================== ͸�����ǲ���غ��� ======================
CreateOverlay() {
    global g_hOverlayGui
    
    Gui, Overlay:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Overlay:Color, FFFFFF
    Gui, Overlay:Font, s1
    Gui, Overlay:+LastFound
    WinSet, Transparent, 1
    WinSet, ExStyle, +0x20  ; ���WS_EX_TRANSPARENT
    WinSet, ExStyle, -0x20  ; �Ƴ�WS_EX_TRANSPARENT
    
    ; ��ʾȫ������
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

; ====================== �϶��¼������� ======================
DragStartHandler:
    if (!IsDragModeActive || !TargetWinID)  ; ��ȫ���
        return
    
    ; ��¼��ʼλ����Ϣ
    WinGetPos, winX, winY,,, ahk_id %TargetWinID%  ; ��ȡ���ڵ�ǰλ��
    MouseGetPos, mouseX, mouseY           ; ��ȡ��굱ǰλ��
    
    DragStartX := mouseX  ; �����ʼX
    DragStartY := mouseY  ; �����ʼY
    DragWinX := winX      ; ������ʼX
    DragWinY := winY      ; ������ʼY
    
    IsDragging := true  ; ���Ϊ�����϶�
    
    ; ������ʱ���������´���λ��
    SetTimer, UpdateWindowPosition, -1
return

DragEndHandler:
    IsDragging := false          ; ����϶�����
    SetTimer, UpdateWindowPosition, Off  ; ֹͣ��ʱ��
return

UpdateWindowPosition:
    if (!IsDragging || !TargetWinID)  ; ��ȫ���
        return
    
    MouseGetPos, mouseX, mouseY  ; ��ȡ��ǰ���λ��
    
    ; ������λ��
    newX := mouseX - (DragStartX - DragWinX)
    newY := mouseY - (DragStartY - DragWinY)
    
    WinMove, ahk_id %TargetWinID%,, newX, newY  ; �ƶ�Ŀ�괰��
    
    ; ��������϶�״̬��10ms���������
    if (IsDragging)
        SetTimer, UpdateWindowPosition, -10
return

; ====================== �������ߺ��� ======================
ForceShowBorder(action, WinID) {
    WinGetPos, X, Y, W, H, ahk_id %WinID%  ; ��ȡ��ǰ�ߴ�
    
    if (action = "enable") {
        WinSet, Style, +0x40000, ahk_id %WinID%  ; ���WS_SIZEBOX
        WinGet, winStyle, Style, ahk_id %WinID%  ; ��ȡ������ʽ
        if !(winStyle & 0xC00000)  ; ����ޱ�����
            WinSet, Style, +0x00800000, ahk_id %WinID%  ; ���WS_BORDER
    } else {
        WinSet, Style, -0x00800000, ahk_id %WinID%  ; �Ƴ�WS_BORDER
    }
    
    ; ͨ����ʱ�������ڴ�Сǿ���ػ�
    WinMove, ahk_id %WinID%,, X, Y, W+1, H+1  ; ����΢����
    WinMove, ahk_id %WinID%,, X, Y, W, H      ; �ٻָ�ԭ�ߴ�
}
; ====================== �˵���ܺ��� ======================
ToggleScript:
    IsScriptEnabled := !IsScriptEnabled  ; �л�״̬
    
    ; ���²˵���״̬��ͼ��
    if (IsScriptEnabled) {
        Menu, Tray, Check, ���ýű�  ; ��ӶԹ�
    } else {
        Menu, Tray, Uncheck, ���ýű�  ; �Ƴ��Թ�
        
        ; ����ʱ�����϶�ģʽ
        if (IsDragModeActive) {
            DestroyOverlay()  ; �Ƴ�͸����
            
            ; ע���ȼ�
            Hotkey, ~LButton, Off
            Hotkey, ~LButton Up, Off
            
            ; ����״̬
            IsDragModeActive := false
            IsDragging := false
            SetTimer, UpdateWindowPosition, Off  ; ֹͣ��ʱ��
        }
    }
return

ShowAbout:
    MsgBox, 64, ���� �ޱ߿򴰿ڿ���,
    (
�ޱ߿򴰿ڿ���
---------------------------------
    ����˵����
Alt+Ctrl+F = �б߿�+��������
Alt+Ctrl+H = �ޱ߿�
Alt+Ctrl+G = �����϶�ģʽ
---------------------------------
�汾��AutoHotkey V1(V1.5)
���ߣ�Little-data
GitHub��https://github.com/Little-Data/showtitlebar-v2
ԭ���ߣ�WindowsTime
    )
return

ExitScript:
    if (g_hOverlayGui)  ; ����͸����
        DestroyOverlay()
    ExitApp  ; �˳�����
return
