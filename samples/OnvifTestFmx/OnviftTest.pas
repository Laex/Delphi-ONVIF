unit OnviftTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Messaging,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, ONVIF,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.TreeView,
  FMX.Gestures, IPCameraLoginDlg, FMX.ScrollBox, FMX.Memo;

type
  TFormOnvifTest = class(TForm)
    TreeView1: TTreeView;
    CBProbe: TCornerButton;
    ONVIFProbe1: TONVIFProbe;
    GestureManager1: TGestureManager;
    Memo1: TMemo;
    Panel1: TPanel;
    procedure CBProbeClick(Sender: TObject);
    procedure ONVIFProbe1Completed(Sender: TObject);
    procedure ONVIFProbe1ProbeMath(const ProbeMatch: TProbeMatch);
    procedure TreeView1DblClick(Sender: TObject);
    procedure TreeView1Gesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ONVIFProbe1LogMessage(const msg: string);
  private
    MessageListener: TMessageListenerMethod;
    F: TProbeMatchArray;
    TviSel: TTreeViewItem;
    UserName: String;
    Password: String;
    Host: String;
    function AddTVItem(parent: TFmxObject; itemText: String): TTreeViewItem;
    procedure SetDeviceInfo(T: TTreeViewItem; Host: String; UserName: String; Password: String);
  public
    procedure LoginDone;
  end;

var
  FormOnvifTest: TFormOnvifTest;

implementation

{$R *.fmx}

procedure TFormOnvifTest.CBProbeClick(Sender: TObject);
begin
  TreeView1.Clear;
  CBProbe.Enabled := False;
  Memo1.Lines.Add('Probe start');
  ONVIFProbe1.ExecuteAsync;
end;

procedure TFormOnvifTest.FormCreate(Sender: TObject);
begin
  //MessageListener := self.ProcessMessage;
  //TMessageManager.DefaultManager.SubscribeToMessage(TReadObjectMessage,
  //MessageListener);
end;

procedure TFormOnvifTest.ONVIFProbe1Completed(Sender: TObject);
var
  ProbeMatch: TProbeMatch;
  s: string;
  T, T1: TTreeViewItem;
begin
  Memo1.Lines.Add('Probe completed');
  F := UniqueProbeMatch(ONVIFProbe1.ProbeMatchArray);
  TreeView1.Clear;
  for ProbeMatch in F do
  begin
    T := AddTVItem(TreeView1, 'IP4: ' + ProbeMatch.XAddrs);
  Memo1.Lines.Add('IP4: ' + ProbeMatch.XAddrs);

    if Length(ProbeMatch.XAddrsV6) > 0 then
      T1 := AddTVItem(T, 'IP6: ' + ProbeMatch.XAddrsV6);

    T1 := AddTVItem(T, 'Type:');

    if ptNetworkVideoTransmitter in ProbeMatch.Types then
      AddTVItem(T1, 'NetworkVideoTransmitter');

    if ptDevice in ProbeMatch.Types then
      AddTVItem(T1, 'Device');

    if ptNetworkVideoDisplay in ProbeMatch.Types then
      AddTVItem(T1, 'NetworkVideoDisplay');

    T1 := AddTVItem(T, 'Scopes:');

    for s in ProbeMatch.Scopes do
      AddTVItem(T1, s);

    AddTVItem(T, 'MetadataVersion: ' + ProbeMatch.MetadataVersion.ToString);
  end;
  CBProbe.Enabled := True;
end;

procedure TFormOnvifTest.ONVIFProbe1LogMessage(const msg: string);
begin
  Memo1.Lines.Add(msg);
end;

function TFormOnvifTest.AddTVItem(parent: TFmxObject; itemText: String): TTreeViewItem;
begin
  Result := TTreeViewItem.Create(Self);
  Result.Text := itemText;
  Result.Parent := parent;
end;

procedure TFormOnvifTest.ONVIFProbe1ProbeMath(const ProbeMatch: TProbeMatch);
var
  T: TTreeViewItem;
begin
  T := TTreeViewItem.Create(Self);
  T.Text := ProbeMatch.XAddrs;
  T.Parent := TreeView1;
end;

procedure TFormOnvifTest.TreeView1DblClick(Sender: TObject);
begin
  if Assigned(TreeView1.Selected) then
  begin
    TviSel := TreeView1.Selected;
    while not(TviSel.ParentItem = nil) and (TviSel.ParentItem.ClassType = TTreeViewItem) do
      TviSel := TviSel.ParentItem;
    Host := F[TviSel.Index].XAddrs;
    IPCameraLoginDlgDlg := TIPCameraLoginDlgDlg.Create(nil);
    begin
      while IPCameraLoginDlgDlg.ChildrenCount>0 do
        IPCameraLoginDlgDlg.Children[0].Parent:= Panel1;
      IPCameraLoginDlgDlg.EdUser.Text := UserName;
      IPCameraLoginDlgDlg.EdUser.SetFocus;
      IPCameraLoginDlgDlg.EdPsw.Text := Password;
      IPCameraLoginDlgDlg.LbHost.Text := 'Camera: ' + Host;
      IPCameraLoginDlgDlg.procModule := LoginDone;
    end;
  end;
end;

procedure TFormOnvifTest.LoginDone;
begin
  if IPCameraLoginDlgDlg.ret = True then
  begin
    UserName := IPCameraLoginDlgDlg.EdUser.Text;
    Password := IPCameraLoginDlgDlg.EdPsw.Text;
    SetDeviceInfo(TviSel, Host, UserName, Password);
  end;
  IPCameraLoginDlgDlg.DisposeOf;
end;

procedure TFormOnvifTest.SetDeviceInfo(T: TTreeViewItem; Host: String; UserName: String; Password: String);
var
  T1, T2, T3, T4: TTreeViewItem;
  XML: String;
  DeviceInformation: TDeviceInformation;
  Profiles: TProfiles;
  i: Integer;
begin
  XML := ONVIFGetDeviceInformation(Host, UserName, Password);
  if XMLDeviceInformationToDeviceInformation(XML, DeviceInformation) then
  begin
    T1 := T.Items[T.Count - 1];
    if (Pos('DeviceInformation', T1.Text) = 0) and (Pos('Profiles', T1.Text) = 0) then
    begin
      T1 := AddTVItem(T, 'DeviceInformation');
      AddTVItem(T1, 'Manufacturer: ' + DeviceInformation.Manufacturer);
      AddTVItem(T1, 'Model: ' + DeviceInformation.Model);
      AddTVItem(T1, 'FirmwareVersion: ' + DeviceInformation.FirmwareVersion);
      AddTVItem(T1, 'SerialNumber: ' + DeviceInformation.SerialNumber);
      AddTVItem(T1, 'HardwareId: ' + DeviceInformation.HardwareId);
    end;
  end;
  T1 := T.Items[T.Count - 1];
  if Pos('Profiles', T1.Text) = 0 then
  begin
    T1 := AddTVItem(T, 'Profiles');
    XMLProfilesToProfiles(ONVIFGetProfiles(GetONVIFAddr(F[T.Index].XAddrs, atMedia), UserName, Password), Profiles);
    for i := 0 to High(Profiles) do
    begin
      T2 := AddTVItem(T1, 'Name: ' + Profiles[i].Name);
      AddTVItem(T2, 'fixed: ' + Profiles[i].fixed.ToString(True));
      AddTVItem(T2, 'token: ' + Profiles[i].token);
      T3 := AddTVItem(T2, 'VideoSourceConfiguration');
      AddTVItem(T3, 'Name: ' + Profiles[i].VideoSourceConfiguration.Name);
      AddTVItem(T3, 'token: ' + Profiles[i].VideoSourceConfiguration.token);
      AddTVItem(T3, 'UseCount: ' + Profiles[i].VideoSourceConfiguration.UseCount.ToString);
      AddTVItem(T3, 'SourceToken: ' + Profiles[i].VideoSourceConfiguration.SourceToken);
      AddTVItem(T3, 'Bounds: ' + Format('(x:%d, y:%d, width:%d, height:%d)', [Profiles[i].VideoSourceConfiguration.Bounds.x,
        Profiles[i].VideoSourceConfiguration.Bounds.y, Profiles[i].VideoSourceConfiguration.Bounds.width,
        Profiles[i].VideoSourceConfiguration.Bounds.Height]));
      T3 := AddTVItem(T2, 'VideoEncoderConfiguration');
      AddTVItem(T3, 'Name: ' + Profiles[i].VideoEncoderConfiguration.Name);
      AddTVItem(T3, 'token: ' + Profiles[i].VideoEncoderConfiguration.token);
      AddTVItem(T3, 'UseCount: ' + Profiles[i].VideoEncoderConfiguration.UseCount.ToString);
      AddTVItem(T3, 'Encoding: ' + Profiles[i].VideoEncoderConfiguration.Encoding);
      AddTVItem(T3, 'Resolution: ' + Format('(width:%d, height:%d)', [Profiles[i].VideoEncoderConfiguration.Resolution.width,
        Profiles[i].VideoEncoderConfiguration.Resolution.Height]));
      AddTVItem(T3, 'Quality: ' + Profiles[i].VideoEncoderConfiguration.Quality.ToString);
      T4 := AddTVItem(T3, 'RateControl');
      AddTVItem(T4, 'FrameRateLimit: ' + Profiles[i].VideoEncoderConfiguration.RateControl.FrameRateLimit.ToString);
      AddTVItem(T4, 'EncodingInterval: ' + Profiles[i].VideoEncoderConfiguration.RateControl.EncodingInterval.ToString);
      AddTVItem(T4, 'BitrateLimit: ' + Profiles[i].VideoEncoderConfiguration.RateControl.BitrateLimit.ToString);
      T4 := AddTVItem(T3, 'H264');
      AddTVItem(T4, 'GovLength: ' + Profiles[i].VideoEncoderConfiguration.H264.GovLength.ToString);
      AddTVItem(T4, 'GovLength: ' + Profiles[i].VideoEncoderConfiguration.H264.H264Profile);
      T4 := AddTVItem(T3, 'Multicast');
      AddTVItem(T4, 'Address type: ' + Profiles[i].VideoEncoderConfiguration.Multicast.Address.Type_);
      AddTVItem(T4, 'Address IPv4Address: ' + Profiles[i].VideoEncoderConfiguration.Multicast.Address.IPv4Address);
      AddTVItem(T4, 'Port: ' + Profiles[i].VideoEncoderConfiguration.Multicast.Port.ToString);
      AddTVItem(T4, 'TTL: ' + Profiles[i].VideoEncoderConfiguration.Multicast.TTL.ToString);
      AddTVItem(T4, 'AutoStart: ' + Profiles[i].VideoEncoderConfiguration.Multicast.AutoStart.ToString(True));

      AddTVItem(T3, 'SessionTimeout: ' + Profiles[i].VideoEncoderConfiguration.SessionTimeout);
    end;
  end;
end;

procedure TFormOnvifTest.TreeView1Gesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if EventInfo.GestureID = igiDoubleTap then
    TreeView1DblClick(nil);
end;

end.
