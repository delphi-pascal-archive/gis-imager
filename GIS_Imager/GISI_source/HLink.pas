{****************************************************************
 ****************************************************************
 ***        Copyright (c) 2001 by -=Assarbad [GoP]=-          ***
 ***       ____________                 ___________           ***
 ***      /\   ________\               /\   _____  \          ***
 ***     /  \  \       /    __________/  \  \    \  \         ***
 ***     \   \  \   __/___ /\   _____  \  \  \____\  \        ***
 ***      \   \  \ /\___  \  \  \    \  \  \   _______\       ***
 ***       \   \  \ /   \  \  \  \    \  \  \  \      /       ***
 ***        \   \  \_____\  \  \  \____\  \  \  \____/        ***
 ***         \   \___________\  \__________\  \__\            ***
 ***          \  /           /  /          /  /  /            ***
 ***           \/___________/ \/__________/ \/__/             ***
 ***                                                          ***
 ***  May the source be with you, stranger ... :-)            ***
 ***                                                          ***
 ***  Greets from -=Assarbad [GoP]=- ...                      ***
 ***  Special greets go 2 Nico, Casper, SA, Pizza, Navarion...***
 ***[for questions/proposals drop a mail to Assarbad@ePost.de]***
 *****************************************ASCII by Assa [GoP]****
 ****************************************************************}

UNIT HLink;
INTERFACE

FUNCTION gettextfile(name:pchar):STRING;
PROCEDURE showmessagebox(hwnd:LongWord;text,appname:STRING);

IMPLEMENTATION
USES windows,
    messages,
    shellapi;

CONST
    AHyperlink='AHyperlinkWndClassEx';
    mylink='http://www.erm.tu-cottbus.de/delphi';
    mymail='mailto: Assarbad@ePost.de';
    IDC_EDIT1=101;
    IDC_LINK1=102;
    IDC_LINK2=103;

VAR
    inactivefont,
        activefont,
        inactivecolor,
        activecolor:Cardinal;

{$R hlpdlg.res}
VAR helptext,
    appname:STRING;
    dlgfont,
    hDlg:DWORD;
    HLcursor:DWORD=0;

FUNCTION gettextfile(name:pchar):STRING;
VAR
    ResSize:dword;
    HG, HI:DWORD;
    P:Pointer;
    PC:pchar;
BEGIN
    result:='';
    HI:=FindResource(hInstance, name, RT_RCDATA);
    IF HI=0 THEN exit;
    HG:=LoadResource(getmodulehandle(NIL), HI);
    IF HG=0 THEN exit;
    ResSize:=SizeOfResource(getmodulehandle(NIL), HI);
    getmem(pc, ressize+2);
    fillmemory(pc, ressize+2, 0);
    TRY
        p:=NIL;
        P:=Pointer(LockResource(HG));
        copymemory(pc, p, ressize);
        result:=STRING(pc);
        UnlockResource(HG);
    FINALLY
        FreeResource(HG);
        freemem(pc, ressize+2);
    END;
END;

FUNCTION dlgproc2(hwnd:hwnd;imsg:dword;wparam:wparam;lparam:lparam):bool; STDCALL;

    FUNCTION fixfont(size, weight:integer;underline:BOOL):DWORD;
    var DC:DWORD;
    BEGIN
        result:=CreateFont(-MulDiv(size, GetDeviceCaps(GetDC(hwnd), LOGPIXELSY), 72), 0, 0, 0, weight, 0, Cardinal(underline), 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, FIXED_PITCH OR FF_MODERN, 'Courier New');
        releaseDC(hwnd,DC);
    END;

BEGIN
    result:=true;
    CASE imsg OF
        WM_INITDIALOG:
            BEGIN
                dlgfont:=fixfont(10,FW_NORMAL,FALSE);
                sendmessage(getdlgitem(hwnd,IDC_EDIT1),WM_SETFONT,dlgfont,Cardinal(TRUE));
                setprop(getdlgitem(hwnd,IDC_Link1),'Link',DWORD(pchar(mylink)));
                setprop(getdlgitem(hwnd,IDC_Link2),'Link',DWORD(pchar(mymail)));
                setwindowtext(getdlgitem(hwnd, IDC_EDIT1), pchar(helptext));
                setwindowtext(hwnd, pchar(appname));
            END;
        WM_COMMAND:
            CASE loword(wparam) OF
                IDOK:destroywindow(hwnd);
            END;
    ELSE result:=false;
    END;
END;

PROCEDURE showmessagebox(hwnd:DWORD;text,appname:STRING);
BEGIN
    helptext:=text;
    HLink.appname:=appname;
    hDlg:=CreateDialog(hInstance, 'DIALOG', hwnd, @dlgproc2);
END;

FUNCTION HyperlinkWndProc(hWnd:HWND;uMsg:UINT;wParam:WPARAM;lParam:LPARAM):LRESULT; STDCALL;
VAR
    prop, DC:DWORD;
    point:TPoint;
    rect:TRect;
    ps:TPaintStruct;
    pc:pchar;

    PROCEDURE paint(txtcolor:Cardinal);
    BEGIN
        GetClientRect(hWnd, rect);
        Fillrect(DC, rect, COLOR_WINDOW);
        IF txtcolor=inactivecolor THEN selectobject(dc, inactivefont)
        ELSE selectobject(dc, activefont);
        SetBkColor(DC, GetSysColor(COLOR_3DFACE));
        Settextcolor(DC, txtcolor);
        Getmem(pc, 1000);
        SendMessage(hWnd, WM_GETTEXT, 1000, LongInt(pc));
        GetWindowRect(hWnd, rect);
        ExtTextOut(DC, 0, 0, 2, @rect, pc, lstrlen(pc), NIL);
        Freemem(pc);
    END;

    FUNCTION varfont(DC:DWORD;size, weight:integer;underline:BOOL):DWORD;
    BEGIN
        result:=CreateFont(-MulDiv(size, GetDeviceCaps(DC, LOGPIXELSY), 72), 0, 0, 0, weight, 0, Cardinal(underline), 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, VARIABLE_PITCH OR FF_ROMAN, 'MS Sans Serif');
    END;

    FUNCTION fixfont(DC:DWORD;size, weight:integer;underline:BOOL):DWORD;
    BEGIN
        result:=CreateFont(-MulDiv(size, GetDeviceCaps(DC, LOGPIXELSY), 72), 0, 0, 0, weight, 0, Cardinal(underline), 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, FIXED_PITCH OR FF_MODERN, 'Courier New');
    END;

BEGIN
    Result:=0;
    CASE uMsg OF
        WM_CREATE:
            BEGIN
                result:=DefWindowProc(hWnd, uMsg, wParam, lParam);
                HLcursor:=LoadCursor(hInstance, 'HandCursor');
                DC:=GetWindowDC(hWnd);
                inactivefont:=fixfont(DC, 8, FW_NORMAL, FALSE);
                activefont:=fixfont(DC, 8, FW_BOLD, TRUE);
                ReleaseDC(hWnd, DC);
                inactivecolor:=rgb($0, $0, $0);
                activecolor:=rgb($0, $0, $FF);
                SendMessage(hWnd, WM_CAPTURECHANGED, 0, 0);
            END;
        WM_RBUTTONUP,
            WM_LBUTTONUP:
            BEGIN
                prop:=getprop(hwnd, 'Link');
                IF prop<>0 THEN shellexecute(0, 'open', pchar(prop), '', '', SW_SHOWNORMAL);
            END;
        WM_CAPTURECHANGED,
            WM_MOUSEMOVE:
            BEGIN
                GetCursorPos(point);
                GetWindowRect(hwnd, rect);
                IF PtInRect(rect, point) THEN BEGIN
                    IF GetCapture<>hWnd THEN BEGIN
                        SetCapture(hWnd);
                        SetCursor(HLcursor);
                        SendMessage(hWnd, WM_PAINT, activecolor, -1);
                    END;
                END ELSE BEGIN
                    ReleaseCapture;
                    SendMessage(hWnd, WM_PAINT, inactivecolor, -1);
                END;
            END;
        WM_PAINT:
            BEGIN
                CASE lParam OF
                    -1:BEGIN
                            DC:=GetWindowDC(hWnd);
                            paint(wParam);
                            ReleaseDC(hWnd, DC);
                        END;
                ELSE BEGIN
                        DC:=BeginPaint(hWnd, ps);
                        paint(wParam);
                        EndPaint(hWnd, ps);
                    END;
                END;
            END;
    ELSE result:=DefWindowProc(hWnd, uMsg, wParam, lParam);
    END;
END;

PROCEDURE initacomctl;
VAR
    wc:TWndClassEx;
BEGIN
    wc.style:=CS_HREDRAW OR CS_VREDRAW OR CS_GLOBALCLASS;
    wc.cbSize:=sizeof(TWNDCLASSEX);
    wc.lpfnWndProc:=@HyperlinkWndProc;
    wc.cbClsExtra:=0;
    wc.cbWndExtra:=0;
    wc.hInstance:=hInstance;
    wc.hbrBackground:=COLOR_WINDOW;
    wc.lpszMenuName:=NIL;
    wc.lpszClassName:=AHyperlink;
    wc.hIcon:=0;
    wc.hIconSm:=0;
    wc.hCursor:=0;
    RegisterClassEx(wc);
END;

{$R hyperlink.res}
INITIALIZATION
    initacomctl;
END.
