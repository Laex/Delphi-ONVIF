unit IPCameraLoginDlg;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

type
  TIPCameraLoginDlgDlg = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    EdUser: TEdit;
    EdPsw: TEdit;
    CBOK: TCornerButton;
    CBCancel: TCornerButton;
    RLogin: TRectangle;
    LbHost: TLabel;
    procedure CBOKClick(Sender: TObject);
    procedure CBCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    ret: boolean;
    procModule: TProc;
  end;

var
  IPCameraLoginDlgDlg: TIPCameraLoginDlgDlg;

implementation

{$R *.fmx}

procedure TIPCameraLoginDlgDlg.CBCancelClick(Sender: TObject);
begin
  ret := false;
  procModule;
end;

procedure TIPCameraLoginDlgDlg.CBOKClick(Sender: TObject);
begin
  ret := true;
  procModule;
end;

end.
