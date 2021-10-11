{$R splash.res}
const
  ClassName='SplashWndClass';
  Title='GIS Imager';
  Version='2.22';
  Copyright='©2000-2001 by Assarbad';

var rect:trect;
    BMP,mytimer:DWORD;
    deskh, deskw:integer;
    SplashWC:TWndClassEx=(
        cbSize:SizeOf(TWndClassEx);
        style:CS_HREDRAW OR CS_VREDRAW;
        cbClsExtra:0;
        cbWndExtra:0;
        hIcon:0;
        lpszMenuName:NIL;
        lpszClassName:ClassName;
        hIconSm:0);

  windowwidth:integer=240;
  windowheight:integer=150;
  windowleft:integer=100;
  windowtop:integer=100;
  bmpw:integer=240;
  bmph:integer=151;

function WndProc(hWnd,uMsg,wParam,lParam:DWORD):LRESULT; stdcall;
var oldBMP,
    dc,memdc:DWORD;
    ps:TPaintstruct;
begin
     Result:=0;
     case uMsg of
          WM_SYSCOMMAND,
          WM_COMMAND:result:=0;

          WM_DESTROY:
             begin
                  PostQuitMessage(GetLastError);
             end;
          WM_CREATE:
             begin
                  mytimer:=SetTimer(hWnd,1,3000,nil);
             end;
          WM_TIMER:
             begin
                  KillTimer(hWnd,mytimer);
                  destroywindow(hwnd);
             end;
          WM_PAINT:
             begin
                  dc:=Beginpaint(hwnd,ps);
                  memdc:=CreateCompatibleDC(dc);
                  oldBMP:=SelectObject(memdc,BMP);
                  StretchBlt(dc,0,0,bmpw,bmph,memdc,0,0,bmpw,bmph,SRCCOPY);
                  SelectObject(memdc,oldBMP);
                  setbkmode(dc,TRANSPARENT);
                  settextcolor(dc,$002222FF);
                  textout(dc,20,10,title,length(title));
                  settextcolor(dc,$00888888);
                  textout(dc,40,30,version,length(version));
                  settextcolor(dc,$00888888);
                  textout(dc,55,53,copyright,length(copyright));
                  deletedc(memdc);
                  endpaint(hwnd,ps);
             end;
          else
              Result:=DefWindowProc(hWnd,uMsg,wParam,lParam);
     end;
end;

procedure showsplash;
var msg:TMsg;
    wnd:DWORD;
begin
     SplashWC.lpfnWndProc:=@WndProc;
     SplashWC.hInstance:=hInstance;
     SplashWC.hbrBackground:=GetStockobject(BLACK_BRUSH);
     SplashWC.hCursor:=LoadCursor(hInstance,IDC_ARROW);
     systemparametersinfo(SPI_GETWORKAREA,0,@rect,0);
     deskw:=rect.Right-rect.Left;
     deskh:=rect.Bottom-rect.Top;
     Windowleft:=(deskw DIV 2)-(windowwidth DIV 2);
     Windowtop:=(deskh DIV 2)-(windowheight DIV 2);
     RegisterClassEx(SplashWC);
     BMP:=LoadBitmap(hInstance,MAKEINTRESOURCE(1));
     wnd:=CreateWindowEx(WS_EX_APPWINDOW or WS_EX_TOPMOST,ClassName,nil,WS_POPUP,
                     windowleft,windowtop,
                     windowwidth,windowheight,
                     0,0,hInstance,nil);
     Showwindow(wnd,SW_SHOW);
     while TRUE do begin
           if not GetMessage(msg,0,0,0) then break;
           TranslateMessage(msg);
           DispatchMessage(msg);
     end;
     deleteobject(BMP);
     BMP:=0;
end;
