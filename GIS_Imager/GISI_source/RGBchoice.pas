unit RGBchoice;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TRGBch = class(TForm)
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RGBch: TRGBch;

implementation

uses Unit1;

{$R *.DFM}

procedure TRGBch.Button1Click(Sender: TObject);
begin
     modalresult:=mrok;
end;

procedure TRGBch.FormShow(Sender: TObject);
var i:integer;
begin
     combobox1.Items:=form1.listbox2.items;
     for i:=0 to combobox1.Items.Count-1 do
         combobox1.Items[i]:=extractfilename(combobox1.Items[i]);
     combobox2.Items:=combobox1.Items;
     combobox3.Items:=combobox1.Items;
     combobox1.ItemIndex:=0;
     combobox2.ItemIndex:=0;
     combobox3.ItemIndex:=0;
end;

end.
