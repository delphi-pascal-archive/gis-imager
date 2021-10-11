@echo off
echo ICON resources
echo.
brcc32.exe icons.rc icons.res
echo.
echo EXE file infos
echo.
brcc32.exe fileinfo.rc fileinfo.res
echo.
echo RGB choice dialog resource
echo.
brcc32.exe RGBchoice.rc RGBchoice.res
brcc32.exe hlpdlg.rc hlpdlg.res
brcc32.exe hyperlink.rc hyperlink.res
echo.
echo finished ...
