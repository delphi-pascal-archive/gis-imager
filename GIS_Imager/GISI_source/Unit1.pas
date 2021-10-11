unit Unit1;
interface

uses
  Windows, Messages, SysUtils, Controls, Graphics, Forms, ARegistry,
  ExtDlgs, StdCtrls, ExtCtrls, ComCtrls, Menus, Classes, Dialogs, math;

const SC_ABOUT=WM_USER+1;
      SC_HELP =WM_USER+2;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    PageControl1: TPageControl;
    TabSheet2: TTabSheet;
    ScrollBox2: TScrollBox;
    Image4: TImage;
    ListBox1: TListBox;
    PopupMenu1: TPopupMenu;
    SaveDialog1: TSaveDialog;
    Panel2: TPanel;
    ListBox2: TListBox;
    Button2: TButton;
    SpeedButton2: TButton;
    SpeedButton3: TButton;
    Button4: TButton;
    Button3: TButton;
    OpenDialog1: TOpenPictureDialog;
    Button1: TButton;
    TabSheet1: TTabSheet;
    Splitter1: TSplitter;
    ScrollBox1: TScrollBox;
    ListView1: TListView;
    Button5: TButton;
    Deleteentry1: TMenuItem;
    Addentry1: TMenuItem;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure debugview(s:string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image4DblClick(Sender: TObject);
    procedure sysmsg(var msg:TMessage);message WM_SYSCOMMAND;
    procedure Help1Click(Sender: TObject);
    procedure Aboutthisprogram1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Addentry1Click(Sender: TObject);
    procedure Deleteentry1Click(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Image2DblClick(Sender: TObject);
    procedure Image3DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


Procedure showsplash;

var
  Form1: TForm1;
  reg:TRegistry;
  tempc:tcolor;
  canpick:boolean;
//there's one little hole ... 7 BMPs are allowed ...
//but by editing the Registry one can overrun the sec-mechanism
  bmpnames:array of string;
const
  appname='GIS Imager';

var pickmode:boolean;
    helptext,
    progname:string;
    hdlg2:DWORD;
    C_R,C_G,C_B:integer;

type DoubleDW=packed record
        hi,lo:LongWord;

     end;

implementation

uses histogram, RGBchoice,HLink;

{$R *.DFM}

procedure Tform1.sysmsg(var msg:TMessage);
begin
     case msg.WParam of
     SC_ABOUT:
        begin
             ShowMessageBox(self.windowhandle,gettextfile('myabout')+#13#10#13#10#13#10#13#10+gettextfile('mycont'),progname);
        end;
     SC_HELP :
        begin
             ShowMessageBox(self.windowhandle,gettextfile('mylic')+#13#10#13#10#13#10#13#10+gettextfile('myhelp'),progname);
        end;
     end;
     inherited;
end;

procedure TForm1.debugview(s:string);
begin
     if checkbox1.Checked then windows.Beep(1000,300);
     listbox1.Items.Append(timetostr(time)+' - '+s);
     listbox1.ItemIndex:=listbox1.Items.Count-1;
end;

procedure TForm1.FormCreate(Sender: TObject);
var rect:TRect;
    hsysmenu:DWORD;
    bla:boolean;
begin
     hsysmenu:=GetSystemMenu(self.windowhandle,FALSE);
     if hsysmenu<>0 then begin
        DeleteMenu(hsysmenu,SC_MAXIMIZE,MF_BYCOMMAND);
        DeleteMenu(hsysmenu,SC_RESTORE,MF_BYCOMMAND);
        DeleteMenu(hsysmenu,SC_MOVE,MF_BYCOMMAND);
        DeleteMenu(hsysmenu,SC_SIZE,MF_BYCOMMAND);
        Appendmenu(hsysmenu,MF_SEPARATOR,0,nil);//SEPARATOR first
        Appendmenu(hsysmenu,MF_BYCOMMAND,SC_HELP,pchar('Help'));
        Appendmenu(hsysmenu,MF_BYCOMMAND,SC_ABOUT,pchar('About'));
     end;

     systemparametersinfo(SPI_GETWORKAREA,0,@rect,0);
     self.Left:=rect.Left;
     self.Top:=rect.Top;
     self.Width:=rect.Right-rect.Left;
     self.Height:=rect.Bottom-rect.Top;
     image4.Height:=0;
     image4.Top:=10;
     image4.Left:=2;
     image1.Height:=0;
     image1.Top:=10;
     image1.Left:=2;
     image2.Height:=0;
     image2.Left:=2;
     image3.Height:=0;
     image3.Left:=2;
     activecontrol:=pagecontrol1;
     debugview('Welcome to '+appname);
     progname:=gettextfile('myCR');
     if progname<>'' then progname:=appname+' - '+progname
        else progname:=appname;
     self.Caption:=progname;
     try
        reg:=Tregistry.create;
        try
           reg.RootKey:=HKEY_LOCAL_MACHINE;
           reg.OpenKey('\Software\Assarbad',TRUE,R);
           Listbox2.Items.CommaText:=reg.ReadString('GISImager.BMPs');
        except on exception do debugview('Error: Failed to load the configuration.');
        end;
     finally
        reg.free;
     end;
     while listbox2.Items.Count>7 do begin
           listbox2.Items.Delete(listbox2.items.count-1);
           bla:=true;
     end;
     if bla then debugview('Error: All items from listbox which exceeded the 7 layers were discarded.');
     listbox2.ItemIndex:=0;
end;

procedure TForm1.Button2Click(Sender: TObject);
var testbmp:tbitmap;
    noBMP:boolean;
begin
     if listbox2.Items.Count>=7 then begin
        debugview('Error: Sorry, LANDSAT has only 7 layers/bands.');
        messagebox(self.windowhandle,'Sorry, LANDSAT has only 7 layers/bands.','Error',MB_OK);
     end
     else if opendialog1.Execute then begin
        if fileexists(opendialog1.FileName) then
           noBMP:=false;
        try
              testbmp:=TBitmap.Create;
              try
                 testbmp.LoadFromFile(opendialog1.FileName);
              except on Exception do NoBMP:=true;
              end;
        finally
              testbmp.free;
        end;
        if noBMP then debugview('Error: "'+opendialog1.FileName+'" is no valid Bitmap.')
           else listbox2.Items.Append(opendialog1.FileName);
     end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     try
        reg:=Tregistry.create;
        try
           reg.RootKey:=HKEY_LOCAL_MACHINE;
           reg.OpenKey('\Software\Assarbad',TRUE,RW);
           reg.WriteString('GISImager.BMPs',listbox2.Items.CommaText);
        except on exception do application.MessageBox('Failed to save the configuration.','Error',MB_OK);
        end;
     finally
        reg.free;
     end;
end;

procedure getrgb(col: tcolor; var r, g, b: byte);
var color: $0..$ffffffff;
begin
     color:=colortorgb(col);
     r:=($000000ff and color);
     g:=($0000ff00 and color) shr 8;
     b:=($00ff0000 and color) shr 16;
end;

procedure TForm1.Help1Click(Sender: TObject);
begin
     sendmessage(self.windowhandle,WM_SYSCOMMAND,SC_HELP,0);
end;

procedure TForm1.Aboutthisprogram1Click(Sender: TObject);
begin
     sendmessage(self.windowhandle,WM_SYSCOMMAND,SC_ABOUT,0);
end;

procedure TForm1.Button3Click(Sender: TObject);
var i:integer;
begin
     debugview('-> Load bitmaps. This may take a while due to several computations which will be applied.');
     setlength(bmpnames,listbox2.Items.Count);
     for i:=0 to length(bmpnames)-1 do
         bmpnames[i]:=listbox2.items[i];
     prob(bmpnames);
     debugview('Success: Loaded the bitmaps (including pre-computations).');
     button5.Enabled:=true;
     button4.Enabled:=true;
     button1.Enabled:=true;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
     button1.Enabled:=false;
     histowindow.show;
end;

procedure TForm1.ListBox1DblClick(Sender: TObject);
var dummy:string;
begin
     dummy:='GISImager.log';
     if fileexists(dummy) then
        if messagebox(self.windowhandle,'There''s already a logfile. Overwrite?','Confirm!',MB_YESNO)=mrno then exit;
     listbox1.Items.SaveToFile(dummy);
end;

procedure TForm1.Button4Click(Sender: TObject);
var i,j,counter:LongWord;
begin
     RGBch:=TRGBch.Create(self);
     RGBch.showmodal;
     C_R:=RGBch.ComboBox1.itemindex;
     C_G:=RGBch.ComboBox2.itemindex;
     C_B:=RGBch.ComboBox3.itemindex;
     RGBch.free;
//combining
     image4.Width:=xLS[C_R].width;
     image4.height:=xLS[C_R].height;
     debugview('-> Starting color combination.');
     counter:=0;
     for i:=0 to image4.Height-1 do
         for j:=0 to image4.Width-1 do begin
             image4.Canvas.Pixels[j,i]:=rgb(xLS[C_R].BMP[counter],xLS[C_G].BMP[counter],xLS[C_B].BMP[counter]);
             inc(counter);
         end;
//end combining
     image4.Visible:=true;
     debugview('Success: Color combination finished.');
end;

{procedure combinedsearch;
type Tbla=array[0..6] of byte;
var i,k,l:integer;
    checkedarr:array of tcolor;
    foundarr:array of TBla;

begin
     application.MessageBox('Well, this requires intense calculation by the machine.','Get a coffe or two ;)',MB_OK);
     setlength(checkedarr,length(xls[0].BMP));
//set evrth to FALSE
     ZeroMemory(checkedarr,sizeof(checkedarr));
//well, considering, we have got pictures of same size and so on
//we may now ry to combine them ;-) ... search unique
//combinations list them ... yaddayaddayadda
     setlength(foundarr,0);
//l is the counter for the arraysize
     l:=0;
     while TRUE do begin
           i:=-1;
           while not LongBool(checkedarr[i]) do
                 inc(i);
//if we found anything leave the loop for a special subloop
           if i<>-1 then begin
              setlength(foundarr,length(foundarr)+1);
              for k:=0 to length(xLS)-1 do foundarr[length(foundarr)-1][k]:=xLS[k].BMP[i];
//delete the found values
           end;
     end;
end;}
{
//     combinedsearch;
//    debugtext:string;i:integer;

     debugtext:='';
     for i:=0 to length(xLS)-1 do
         debugtext:=debugtext+format('%x',[xLS[i].BMP[0]]);
     debugtext:=debugtext+#13#10+format('%x',[arr[0]]);
     showmessagebox(self.windowhandle,debugtext);}

//this is just a nifty measure to increase the speed while comparing the
//"vectors"
//since it is much faster to compare 64 bit integers ... than discrete
//array members
//we now have an array of the values encoded as int64
//looks like: $001122334455667788
//where 00 is not yet used! one can use it e.g. as boolean ;)
//and 1 to 7 are the values of the according layers
procedure TForm1.Button5Click(Sender: TObject);
var temp:array of Int64;
    temp2:array of LongInt;
    newcols:array of LongInt;
    i,j:integer;
    bla:int64;
    k:longint;

{function oops(val,pos:longint):longint;
var tempbyte,tempbyte2:byte;
begin
     tempbyte:=max(xLS[C_R].BMP[pos],xLS[C_G].BMP[pos]);
     tempbyte:=max(xLS[C_B].BMP[pos],tempbyte);

     if tempbyte=xLS[C_B].BMP[pos] then tempbyte2:=64+(xLS[C_B].BMP[pos] div 8);
     if tempbyte=xLS[C_G].BMP[pos] then tempbyte2:=32+(xLS[C_G].BMP[pos] div 8);
     if tempbyte=xLS[C_R].BMP[pos] then tempbyte2:=    xLS[C_R].BMP[pos] div 8;
//R has highest priority!
     val:=val SHL 8;
     val:=val OR tempbyte2;
     asm
        ror val,8
     end;
     result:=val;
end;

function isnear(b:byte):byte;
var l:longint;
begin
     l:=trunc($FF*((xLS[C_R].probs[b]+xLS[C_G].probs[b]+xLS[C_B].probs[b])/3));
     b:=(b div 4);
     result:=(b * 4)+2;
end;}

begin
     if messagedlg('The following computation will take pretty long. Proceed?'+#13#10+'(Note: Best is to give the "natural" RGB combination in the following dialog!)',mtconfirmation,[mbyes,mbno],0)=mrno then exit;
     Button4Click(sender);
     debugview('-> Starting classification. This will take VERY long!');
     setlength(temp,length(xLS[0].BMP));
     setlength(temp2,length(temp));
     setlength(newcols,length(temp));
     for j:=0 to length(xLS[0].BMP)-1 do begin
         temp[j]:=0;
         for i:=0 to length(xLS)-1 do
             temp[j]:=(temp[j] shl 8) or (xLS[i].BMP[j]);//
     end;
//search for zeroes first!
     for i:=0 to length(newcols)-1 do newcols[i]:=clBlack;
     k:=0;
     for i:=0 to length(temp)-1 do
         if temp[i]<>0 then begin
         //found something which was not yet found
            bla:=temp[i];
            inc(k);
            for j:=i to length(temp)-1 do
                if temp[j]<>0 then
                   if temp[j]=bla then begin
                      temp[j]:=0;
                      newcols[j]:=k;
//                      temp2[j]:=oops(k,j);
                   end;
         end;
//at this point should everything be mapped ;
     image1.Width:=xLS[0].width;
     image1.Height:=xLS[0].height;
     image1.Canvas.Brush.Color:=clBlack;
     image1.Canvas.FillRect(image1.clientrect);
     for j:=0 to image1.height-1 do
         for i:=0 to image1.width-1 do
             image1.Canvas.Pixels[i,j]:=newcols[i+(j*image1.width)];
     for j:=0 to 10 do application.ProcessMessages;

     for j:=0 to length(temp)-1 do
         temp2[j]:=rgb(xLS[C_R].BMP[j],xLS[C_G].BMP[j],xLS[C_B].BMP[j]);

     image2.Width:=image1.Width;
     image2.Height:=image1.Height;
     image2.Top:=image1.Top+image1.Height+10;

     for j:=0 to image2.height-1 do
         for i:=0 to image2.width-1 do
             image2.Canvas.Pixels[i,j]:=newcols[i+(j*image1.width)] or temp2[i+(j*image1.width)];

     image3.Width:=image1.Width;
     image3.Height:=image1.Height;
     image3.Top:=image2.Top+image2.Height+10;

     for j:=0 to image2.height-1 do
         for i:=0 to image2.width-1 do
             image3.Canvas.Pixels[i,j]:=newcols[i+(j*image1.width)] and temp2[i+(j*image1.width)];

     debugview('Success: Classification finished. (found '+format('%d',[k])+' distinct pattern)');
     pagecontrol1.ActivePage:=tabsheet1;
end;

procedure TForm1.Addentry1Click(Sender: TObject);
begin
     button2click(sender);
end;

procedure TForm1.Deleteentry1Click(Sender: TObject);
begin
     if listbox2.ItemIndex<0 then listbox2.ItemIndex:=0;
     if listbox2.ItemIndex>(listbox2.Items.Count) then listbox2.ItemIndex:=0;
     if listbox2.Items.Count>0 then listbox2.items.delete(listbox2.ItemIndex);
end;

procedure TForm1.Image1DblClick(Sender: TObject);
begin
     savedialog1.FileName:='ClassifiedRGB24.bmp';
     if savedialog1.Execute then begin
        if fileexists(savedialog1.filename) then
           if messagedlg('The file already exists!'+#13#10+'Overwrite?',mtconfirmation,[mbyes,mbno],0)=mrno then begin
              debugview('Error: Nothing saved. (0)');
              exit;
           end;
        image1.Picture.Bitmap.SaveToFile(savedialog1.filename);
        if fileexists(savedialog1.filename) then debugview('Success: '+savedialog1.FileName+' saved.');
     end;
end;

procedure TForm1.Image2DblClick(Sender: TObject);
begin
     savedialog1.FileName:='ClassifiedRGB24_OR_RGB.bmp';
     if savedialog1.Execute then begin
        if fileexists(savedialog1.filename) then
           if messagedlg('The file already exists!'+#13#10+'Overwrite?',mtconfirmation,[mbyes,mbno],0)=mrno then begin
              debugview('Error: Nothing saved. (0)');
              exit;
           end;
        image2.Picture.Bitmap.SaveToFile(savedialog1.filename);
        if fileexists(savedialog1.filename) then debugview('Success: '+savedialog1.FileName+' saved.');
     end;
end;

procedure TForm1.Image3DblClick(Sender: TObject);
begin
     savedialog1.FileName:='ClassifiedRGB24_AND_RGB.bmp';
     if savedialog1.Execute then begin
        if fileexists(savedialog1.filename) then
           if messagedlg('The file already exists!'+#13#10+'Overwrite?',mtconfirmation,[mbyes,mbno],0)=mrno then begin
              debugview('Error: Nothing saved. (0)');
              exit;
           end;
        image3.Picture.Bitmap.SaveToFile(savedialog1.filename);
        if fileexists(savedialog1.filename) then debugview('Success: '+savedialog1.FileName+' saved.');
     end;
end;

procedure TForm1.Image4DblClick(Sender: TObject);
begin
     savedialog1.FileName:='CombinedRGB.bmp';
     if savedialog1.Execute then begin
        if fileexists(savedialog1.filename) then
           if messagedlg('The file already exists!'+#13#10+'Overwrite?',mtconfirmation,[mbyes,mbno],0)=mrno then begin
              debugview('Error: Nothing saved. (0)');
              exit;
           end;
          image4.Picture.Bitmap.SaveToFile(savedialog1.filename);
          if fileexists(savedialog1.filename) then debugview('Success: '+savedialog1.FileName+' saved.');
     end;
end;

{$I splash.pas}

end.


