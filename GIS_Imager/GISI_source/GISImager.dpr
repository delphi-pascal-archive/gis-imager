program GISImager;

uses
  windows,
  messages,
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  histogram in 'histogram.pas' {Histowindow},
  RGBchoice in 'RGBchoice.pas' {RGBch};

{$R icons.res}
{$R fileinfo.res}

begin
  showsplash;
  Application.Initialize;
  application.Icon.Handle:=loadicon(hInstance,makeintresource(1));
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(THistowindow, Histowindow);
  Application.Run;
end.
