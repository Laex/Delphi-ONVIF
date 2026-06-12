program OnvifTestFmx;

uses
  System.StartUpCopy,
  FMX.Forms,
  OnviftTest in 'OnviftTest.pas' {FormOnvifTest},
  IPCameraLoginDlg in 'IPCameraLoginDlg.pas' {IPCameraLoginDlgDlg},
  Xml.VerySimple in '..\..\src\ThirdParty\Xml.VerySimple.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormOnvifTest, FormOnvifTest);
  Application.CreateForm(TIPCameraLoginDlgDlg, IPCameraLoginDlgDlg);
  Application.Run;
end.
