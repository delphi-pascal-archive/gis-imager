unit histogram;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Spin, ExtDlgs, CheckLst, ComCtrls;

const WM_MYREPAINT=WM_USER+1;

type
  THistowindow = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label2: TLabel;
    SavePictureDialog1: TSavePictureDialog;
    Image2: TImage;
    Checklistbox1: TComboBox;
    Label3: TLabel;
    CheckBox1: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure MyRepaint(var msg:TMessage);message WM_MYREPAINT;
    procedure ComboBox1Change(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Image3MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
     TPrepBMP=record
//since the BMP is represented by a plain (1D) array of bytes, we urgently
//need to have some information about the spatial dimensions
        name                 :string;
        width,height         :integer;
//the BMP as array of byte
//the size can be gained by a simple LENGTH() call
        BMP                  :array of byte;
//probability values pre-calculated!
        PROBs                :array[0..255] of DOUBLE;
        pmax,sum,mean,stddev :extended;
//up to now, there's no more necessary
     end;

     LS_layers=array of TPrepBMP;

var
  Histowindow: THistowindow;
  xLS:LS_layers;

//publication of functions
function prob(names:array of string):LS_layers;

implementation
uses unit1, math;

{$R *.DFM}

function prob(names:array of string):LS_layers;
var i,j,k:integer;
    counter:LongWord;
    bmp:TBitmap;
    colsum:array[0..255] of DOUBLE;
begin
//at this point has to be proved that the file have the same format
//e.g. they must be 8bit gray w/ same width/height ...
     Zeromemory(@colsum,sizeof(colsum));
     setlength(result,length(names));
     if length(names)>7 then begin
        messagebox(0,'Sorry, the number of pictures exceeds 7. Correct it and try again.','Error',MB_OK);
        exit;
     end;
     for i:=0 to length(names)-1 do begin
         application.ProcessMessages;
         bmp:=TBitmap.Create;
         bmp.LoadFromFile(names[i]);
         setlength(result[i].BMP,bmp.Width*bmp.Height);
         result[i].name:=extractfilename(names[i]);
         result[i].width:=bmp.Width;
         result[i].height:=bmp.Height;
         counter:=0;
         for j:=0 to bmp.Height-1 do
             for k:=0 to bmp.Width-1 do begin
                 result[i].BMP[counter]:=lo(bmp.Canvas.Pixels[k,j]);
                 colsum[lo(bmp.Canvas.Pixels[k,j])]:=colsum[lo(bmp.Canvas.Pixels[k,j])]+lo(bmp.Canvas.Pixels[k,j]);
                 inc(counter);//assuming no file bigger than 2^32 byte = 4 Gig I think!
             end;
         bmp.free;
         result[i].Sum:=Sum(colsum);
         if result[i].Sum<>0 then begin
            MeanAndStdDev(colsum,result[i].mean,result[i].stddev);
            for j:=0 to 255 do
                result[i].probs[j]:=colsum[j]/result[i].Sum;
            result[i].pmax:=maxvalue(result[i].probs);
            for j:=0 to 255 do
                result[i].probs[j]:=result[i].probs[j]/result[i].pmax;
         end else begin
             messagebox(0,pchar('The picture ('+result[i].name+') seems to be black!'),'Operation aborted',0);
             exit;
         end;
     end;
     xLS:=result;
end;

procedure THistowindow.MyRepaint(var msg:TMessage);
var i:integer;
begin
     image1.Canvas.brush.Style:=bsSolid;
     image1.Canvas.brush.Color:=clWhite;
     image1.Canvas.FillRect(image1.ClientRect);
     with self.image1 do begin
          for i:=0 to 255 do begin
              canvas.MoveTo(i,height-1);
              canvas.LineTo(i,(height-1)-round(height*(xLS[checklistbox1.ItemIndex].Probs[i])));
          end;
          canvas.Font.Size:=6;
          canvas.Font.Color:=clBlack;
          for i:=1 to 5 do begin
              canvas.TextOut(267,height-round(height*(i/5)),format('%3d',[20*i]));
              canvas.Pixels[264,height-round(height*(i/5))]:=clBlack;
              canvas.Pixels[265,height-round(height*(i/5))]:=clBlack;
          end;
          canvas.TextOut(270,height-15,'[%]');
          for i:=1 to 2 do begin
              canvas.MoveTo(261+i,0);
              canvas.LineTo(261+i,height);
          end;
     end;
//Maﬂstab
end;

procedure THistowindow.FormShow(Sender: TObject);
var i,j:LongWord;
begin
     self.Left:=form1.left+form1.width-self.width-50;
     self.top:=form1.top+15;
     form1.Button1.Enabled:=false;
     checklistbox1.Clear;
     for i:=0 to length(xLS)-1 do
         checklistbox1.Items.Append(xLS[i].name);
     checklistbox1.ItemIndex:=0;
     for i:=0 to 255 do
         for j:=0 to 4 do
             image2.canvas.Pixels[i,j]:=rgb(i,i,i);
     sendmessage(self.windowhandle,WM_MYREPAINT,0,0);
end;

procedure THistowindow.ComboBox1Change(Sender: TObject);
begin
     sendmessage(self.windowhandle,WM_MYREPAINT,0,0);
end;

procedure THistowindow.Image1DblClick(Sender: TObject);
var dummy:string;
begin
     dummy:=extractfilename(checklistbox1.items[checklistbox1.itemindex]);
     dummy:='histogram_for_'+dummy;
     if fileexists(dummy) then
           if messagedlg('The file ('+dummy+') already exists, do you want to overwrite it?',mtConfirmation,[mbyes,mbno],0)=mrno then exit;
     image1.Picture.Bitmap.PixelFormat:=pf1bit;
     image1.Picture.Bitmap.SaveToFile(dummy);
     form1.debugview('Success: Histogram saved as "'+dummy+'"');
end;


procedure THistowindow.Image3MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var cpt:TPoint;
begin
     if checkbox1.Checked then begin
           if x in [0..255] then begin
              if xLS[checklistbox1.itemindex].probs[x]=0 then begin
                 dec(x,1);
                 if not (x in [0..255]) then x:=0;
                 if xLS[checklistbox1.itemindex].probs[x]=0 then begin
                    inc(x,2);
                    if not (x in [0..255]) then x:=255;
                    if xLS[checklistbox1.itemindex].probs[x]=0 then dec(x,1);
                 end;
                 cpt:=point(x,y);
                 cpt:=image1.ClientToScreen(cpt);
                 setcursorpos(cpt.x,cpt.y);
              end;
              label3.Caption:=format('Probability at intensity %d = %3.5f %%',[x,xLS[checklistbox1.itemindex].probs[x]*100]);
           end;
     end else begin
         label3.Caption:=format('Probability at intensity %d = %3.5f %%',[x,xLS[checklistbox1.itemindex].probs[x]*100]);
     end;
end;

procedure THistowindow.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
     form1.Button1.Enabled:=true;
end;

end.
