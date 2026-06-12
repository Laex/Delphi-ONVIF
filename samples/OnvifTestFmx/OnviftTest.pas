unit OnviftTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Messaging,
  System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, ONVIF, ONVIF.Types, ONVIF.Demo,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.TreeView,
  FMX.Gestures, IPCameraLoginDlg, FMX.ScrollBox, FMX.Memo, FMX.Edit,
  VMS.CameraRegistry, VMS.EventHub, VMS.RecordingEngine, VMS.PlaybackService, ONVIF.Recording,
  FMX.Memo.Types, ONVIF.Discovery;

type
  TFormOnvifTest = class(TForm)
    TreeView1: TTreeView;
    CBProbe: TCornerButton;
    ONVIFProbe1: TONVIFProbe;
    GestureManager1: TGestureManager;
    Memo1: TMemo;
    Panel1: TPanel;
    LayoutActions: TLayout;
    btnConnect: TButton;
    btnStream: TButton;
    btnSnapshot: TButton;
    btnImaging: TButton;
    btnPTZLeft: TButton;
    btnPTZRight: TButton;
    btnPTZUp: TButton;
    btnPTZDown: TButton;
    btnPTZStop: TButton;
    btnPullEvents: TButton;
    btnEvents: TButton;
    btnRegistry: TButton;
    btnRecord: TButton;
    btnReplay: TButton;
    LayoutDiscovery: TLayout;
    edtDirectHost: TEdit;
    edtDirectUser: TEdit;
    edtDirectPass: TEdit;
    btnDirectConnect: TButton;
    edtUnicastHost: TEdit;
    btnUnicastProbe: TButton;
    edtSubnet: TEdit;
    btnSubnetScan: TButton;
    procedure CBProbeClick(Sender: TObject);
    procedure btnDirectConnectClick(Sender: TObject);
    procedure btnUnicastProbeClick(Sender: TObject);
    procedure btnSubnetScanClick(Sender: TObject);
    procedure ONVIFProbe1Completed(Sender: TObject);
    procedure ONVIFProbe1ProbeMath(const ProbeMatch: TProbeMatch);
    procedure TreeView1DblClick(Sender: TObject);
    procedure TreeView1Gesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ONVIFProbe1LogMessage(const msg: string);
    procedure btnConnectClick(Sender: TObject);
    procedure btnStreamClick(Sender: TObject);
    procedure btnSnapshotClick(Sender: TObject);
    procedure btnImagingClick(Sender: TObject);
    procedure btnPTZLeftClick(Sender: TObject);
    procedure btnPTZRightClick(Sender: TObject);
    procedure btnPTZUpClick(Sender: TObject);
    procedure btnPTZDownClick(Sender: TObject);
    procedure btnPTZStopClick(Sender: TObject);
    procedure btnPullEventsClick(Sender: TObject);
    procedure btnEventsClick(Sender: TObject);
    procedure btnRegistryClick(Sender: TObject);
    procedure btnRecordClick(Sender: TObject);
    procedure btnReplayClick(Sender: TObject);
  private
    F: TProbeMatchArray;
    TviSel: TTreeViewItem;
    FDevice: TONVIFDevice;
    FRegistry: TVMSCameraRegistry;
    FEventHub: TVMSEventHub;
    FRecordingEngine: TVMSRecordingEngine;
    UserName: string;
    Password: string;
    Host: string;
    FPendingAlarm: TVMSAlarmEvent;
    procedure DoShowAlarm;
    function AddTVItem(Parent: TFmxObject; const ItemText: string): TTreeViewItem;
    procedure AddTreeLines(Parent: TFmxObject; const Lines: TONVIFTreeLines);
    procedure Log(const Msg: string);
    procedure OnAlarm(const Event: TVMSAlarmEvent);
    procedure RefreshDeviceTree(T: TTreeViewItem);
    function ConnectCurrentHost: Boolean;
    function ConnectToHost(const AXAddr, AUser, APass: string): Boolean;
    procedure PTZMove(Pan, Tilt, Zoom: Real);
    procedure BeginProbe;
    procedure EndProbe;
    procedure ApplyProbeResults;
  public
    procedure LoginDone;
  end;

var
  FormOnvifTest: TFormOnvifTest;

implementation

{$R *.fmx}

procedure TFormOnvifTest.FormCreate(Sender: TObject);
begin
  FDevice := TONVIFDevice.Create;
  FRegistry := TVMSCameraRegistry.Create;
  FEventHub := TVMSEventHub.Create(OnAlarm);
  FRecordingEngine := TVMSRecordingEngine.Create;
end;

procedure TFormOnvifTest.FormDestroy(Sender: TObject);
begin
  FRecordingEngine.Free;
  FEventHub.Free;
  FRegistry.Free;
  FDevice.Free;
end;

procedure TFormOnvifTest.Log(const Msg: string);
begin
  Memo1.Lines.Add(Msg);
end;

procedure TFormOnvifTest.DoShowAlarm;
begin
  Log(Format('ALARM [%s] %s', [FPendingAlarm.CameraId, FPendingAlarm.Topic]));
end;

procedure TFormOnvifTest.OnAlarm(const Event: TVMSAlarmEvent);
begin
  FPendingAlarm := Event;
  TThread.Synchronize(nil, DoShowAlarm);
end;

function TFormOnvifTest.AddTVItem(Parent: TFmxObject; const ItemText: string): TTreeViewItem;
begin
  Result := TTreeViewItem.Create(Self);
  Result.Text := ItemText;
  Result.Parent := Parent;
end;

procedure TFormOnvifTest.AddTreeLines(Parent: TFmxObject; const Lines: TONVIFTreeLines);
var
  Line: TONVIFTreeLine;
  Parents: TArray<TFmxObject>;
begin
  for Line in Lines do
  begin
    if Length(Parents) <= Line.Depth then
      SetLength(Parents, Line.Depth + 1);
    if Line.Depth = 0 then
      Parents[0] := AddTVItem(Parent, Line.Text)
    else
      Parents[Line.Depth] := AddTVItem(Parents[Line.Depth - 1], Line.Text);
  end;
end;

procedure TFormOnvifTest.BeginProbe;
begin
  TreeView1.Clear;
  CBProbe.Enabled := False;
  btnUnicastProbe.Enabled := False;
  btnSubnetScan.Enabled := False;
end;

procedure TFormOnvifTest.EndProbe;
begin
  CBProbe.Enabled := True;
  btnUnicastProbe.Enabled := True;
  btnSubnetScan.Enabled := True;
end;

procedure TFormOnvifTest.ApplyProbeResults;
var
  ProbeMatch: TProbeMatch;
begin
  F := UniqueProbeMatch(ONVIFProbe1.ProbeMatchArray);
  TreeView1.Clear;
  for ProbeMatch in F do
  begin
    AddTreeLines(TreeView1, BuildProbeMatchTreeLines(ProbeMatch));
    Log('Found: ' + ProbeMatch.XAddrs);
  end;
  Log('Probe found ' + Length(F).ToString + ' device(s).');
end;

procedure TFormOnvifTest.CBProbeClick(Sender: TObject);
begin
  if not CBProbe.Enabled then
    Exit;
  BeginProbe;
  Log('Multicast probe...');
  if not ONVIFProbe1.ExecuteAsync then
  begin
    Log('Probe already running.');
    EndProbe;
  end;
end;

procedure TFormOnvifTest.btnUnicastProbeClick(Sender: TObject);
begin
  if Trim(edtUnicastHost.Text) = '' then
  begin
    Log('Enter unicast IP.');
    Exit;
  end;
  if not CBProbe.Enabled then
    Exit;
  BeginProbe;
  Log('Unicast probe: ' + edtUnicastHost.Text);
  if not ONVIFProbe1.ExecuteUnicastAsync(Trim(edtUnicastHost.Text)) then
  begin
    Log('Probe already running.');
    EndProbe;
  end;
end;

procedure TFormOnvifTest.btnSubnetScanClick(Sender: TObject);
var
  Options: TONVIFSubnetProbeOptions;
  Hosts: TArray<string>;
begin
  if not ParseSubnetSpec(edtSubnet.Text, Options) then
  begin
    Log('Invalid subnet. Example: 192.168.1.0/24');
    Exit;
  end;
  Hosts := EnumerateSubnetHosts(Options);
  if Length(Hosts) = 0 then
  begin
    Log('No hosts in subnet.');
    Exit;
  end;
  if not CBProbe.Enabled then
    Exit;
  BeginProbe;
  Log(Format('Subnet scan %s (%d hosts)...', [edtSubnet.Text, Length(Hosts)]));
  ONVIFProbe1.Timeout := 3000;
  if not ONVIFProbe1.ExecuteSubnetAsync(Options) then
  begin
    Log('Probe already running.');
    EndProbe;
  end;
end;

procedure TFormOnvifTest.ONVIFProbe1Completed(Sender: TObject);
begin
  ApplyProbeResults;
  EndProbe;
end;

function TFormOnvifTest.ConnectToHost(const AXAddr, AUser, APass: string): Boolean;
begin
  Host := AXAddr;
  UserName := AUser;
  Password := APass;
  FDevice.Disconnect;
  Result := FDevice.Connect(AXAddr, AUser, APass);
  if Result then
    Log('Connected: ' + FDevice.DeviceInfo.Manufacturer + ' ' + FDevice.DeviceInfo.Model)
  else
    Log('Connect failed: ' + AXAddr);
end;

procedure TFormOnvifTest.btnDirectConnectClick(Sender: TObject);
var
  XAddr, User, Pass: string;
begin
  XAddr := NormalizeDeviceXAddr(edtDirectHost.Text);
  if XAddr = '' then
  begin
    Log('Enter IP or ONVIF URL.');
    Exit;
  end;
  User := Trim(edtDirectUser.Text);
  Pass := edtDirectPass.Text;
  if User = '' then
  begin
    Host := XAddr;
    IPCameraLoginDlgDlg := TIPCameraLoginDlgDlg.Create(nil);
    try
      while IPCameraLoginDlgDlg.ChildrenCount > 0 do
        IPCameraLoginDlgDlg.Children[0].Parent := Panel1;
      IPCameraLoginDlgDlg.EdUser.Text := UserName;
      IPCameraLoginDlgDlg.EdPsw.Text := Password;
      IPCameraLoginDlgDlg.LbHost.Text := 'Camera: ' + XAddr;
      IPCameraLoginDlgDlg.procModule := LoginDone;
    except
      IPCameraLoginDlgDlg.Free;
      raise;
    end;
    Exit;
  end;
  if ConnectToHost(XAddr, User, Pass) then
  begin
    SetLength(F, 1);
    F[0].XAddrs := XAddr;
    TviSel := AddTVItem(TreeView1, XAddr);
    RefreshDeviceTree(TviSel);
  end;
end;

procedure TFormOnvifTest.ONVIFProbe1LogMessage(const msg: string);
begin
  Log(msg);
end;

procedure TFormOnvifTest.ONVIFProbe1ProbeMath(const ProbeMatch: TProbeMatch);
begin
  AddTVItem(TreeView1, ProbeMatch.XAddrs);
end;

function TFormOnvifTest.ConnectCurrentHost: Boolean;
begin
  Result := ConnectToHost(Host, UserName, Password);
  if Result then
    Log('Media API: ' + MediaApiKindToText(FDevice.MediaApi));
end;

procedure TFormOnvifTest.RefreshDeviceTree(T: TTreeViewItem);
var
  I: Integer;
begin
  while T.Count > 0 do
    T.RemoveObject(T.Items[0]);
  AddTreeLines(T, BuildConnectedDeviceTreeLines(FDevice));
  for I := 0 to T.Count - 1 do
    T.Items[I].IsExpanded := True;
end;

procedure TFormOnvifTest.TreeView1DblClick(Sender: TObject);
begin
  if not Assigned(TreeView1.Selected) then
    Exit;
  TviSel := TreeView1.Selected;
  while not(TviSel.ParentItem = nil) and (TviSel.ParentItem.ClassType = TTreeViewItem) do
    TviSel := TviSel.ParentItem;
  Host := F[TviSel.Index].XAddrs;
  IPCameraLoginDlgDlg := TIPCameraLoginDlgDlg.Create(nil);
  try
    while IPCameraLoginDlgDlg.ChildrenCount > 0 do
      IPCameraLoginDlgDlg.Children[0].Parent := Panel1;
    IPCameraLoginDlgDlg.EdUser.Text := UserName;
    IPCameraLoginDlgDlg.EdUser.SetFocus;
    IPCameraLoginDlgDlg.EdPsw.Text := Password;
    IPCameraLoginDlgDlg.LbHost.Text := 'Camera: ' + Host;
    IPCameraLoginDlgDlg.procModule := LoginDone;
  except
    IPCameraLoginDlgDlg.DisposeOf;
    raise;
  end;
end;

procedure TFormOnvifTest.LoginDone;
begin
  if IPCameraLoginDlgDlg.ret then
  begin
    UserName := IPCameraLoginDlgDlg.EdUser.Text;
    Password := IPCameraLoginDlgDlg.EdPsw.Text;
    edtDirectUser.Text := UserName;
    edtDirectPass.Text := Password;
    if ConnectCurrentHost then
    begin
      if not Assigned(TviSel) then
      begin
        SetLength(F, 1);
        F[0].XAddrs := Host;
        TreeView1.Clear;
        TviSel := AddTVItem(TreeView1, Host);
      end;
      RefreshDeviceTree(TviSel);
    end;
  end;
  IPCameraLoginDlgDlg.Free;
end;

procedure TFormOnvifTest.btnConnectClick(Sender: TObject);
begin
  if Host = '' then
  begin
    Log('Select camera (double-tap tree root).');
    Exit;
  end;
  if ConnectCurrentHost then
    RefreshDeviceTree(TviSel);
end;

procedure TFormOnvifTest.btnStreamClick(Sender: TObject);
var
  Uri: TStreamUri;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  Uri := FDevice.GetStreamUri(DefaultProfileToken(FDevice), 'RTP-Unicast', 'RTSP');
  Log('Stream: ' + Uri.Uri);
end;

procedure TFormOnvifTest.btnSnapshotClick(Sender: TObject);
var
  Snap: TSnapshotUri;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  Snap := FDevice.GetSnapshotUri(DefaultProfileToken(FDevice));
  Log('Snapshot: ' + Snap.Uri);
end;

procedure TFormOnvifTest.PTZMove(Pan, Tilt, Zoom: Real);
var
  V: TPTZVector;
  Token: string;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  if FDevice.PTZEndpoint = '' then
  begin
    Log('PTZ not supported.');
    Exit;
  end;
  Token := DefaultProfileToken(FDevice);
  V.Pan := Pan;
  V.Tilt := Tilt;
  V.Zoom := Zoom;
  if FDevice.PTZContinuousMove(Token, V) then
    Log(Format('PTZ Pan=%.1f Tilt=%.1f', [Pan, Tilt]))
  else
    Log('PTZ move failed.');
end;

procedure TFormOnvifTest.btnImagingClick(Sender: TObject);
var
  Settings: TImagingSettings;
  Token: string;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  Token := DefaultVideoSourceToken(FDevice);
  if Token = '' then
  begin
    Log('No video source token.');
    Exit;
  end;
  Settings := FDevice.GetImagingSettings(Token);
  Log(Format('Imaging B=%.0f C=%.0f S=%.0f',
    [Settings.Brightness, Settings.Contrast, Settings.Sharpness]));
  if FDevice.SetImagingSettings(Token, Settings) then
    Log('Imaging settings applied.');
  if Assigned(TviSel) then
    RefreshDeviceTree(TviSel);
end;

procedure TFormOnvifTest.btnPTZLeftClick(Sender: TObject);
begin
  PTZMove(-0.5, 0, 0);
end;

procedure TFormOnvifTest.btnPTZRightClick(Sender: TObject);
begin
  PTZMove(0.5, 0, 0);
end;

procedure TFormOnvifTest.btnPTZUpClick(Sender: TObject);
begin
  PTZMove(0, 0.5, 0);
end;

procedure TFormOnvifTest.btnPTZDownClick(Sender: TObject);
begin
  PTZMove(0, -0.5, 0);
end;

procedure TFormOnvifTest.btnPTZStopClick(Sender: TObject);
begin
  if FDevice.Connected and FDevice.PTZStop(DefaultProfileToken(FDevice)) then
    Log('PTZ stopped.');
end;

procedure TFormOnvifTest.btnPullEventsClick(Sender: TObject);
var
  Sub: TONVIFSubscription;
  Msgs: TArray<TONVIFEventMessage>;
  M: TONVIFEventMessage;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  if FDevice.EventsEndpoint = '' then
  begin
    Log('Events not supported.');
    Exit;
  end;
  if FDevice.CreateEventSubscription(Sub) then
  begin
    Log('Subscription: ' + Sub.Reference);
    if FDevice.PullEvents(Sub.Reference, Msgs) then
      for M in Msgs do
        Log('Event: ' + M.Topic);
  end
  else
    Log('CreatePullPointSubscription failed.');
end;

procedure TFormOnvifTest.btnEventsClick(Sender: TObject);
var
  Entry: TVMSCameraEntry;
  Dev: TONVIFDevice;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  Entry := FRegistry.AddOrUpdate(Host, UserName, Password);
  Dev := FRegistry.GetDevice(Entry.Id);
  if Dev <> nil then
  begin
    FEventHub.StartMonitoring(Entry.Id, Dev);
    Log('EventHub monitoring started for ' + Entry.Id);
  end;
end;

procedure TFormOnvifTest.btnRegistryClick(Sender: TObject);
var
  Entry: TVMSCameraEntry;
begin
  if Host = '' then
  begin
    Log('Select camera (double-tap tree root).');
    Exit;
  end;
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  Entry := FRegistry.AddOrUpdate(Host, UserName, Password);
  Log(Format('Registry: %s %s %s online=%s',
    [Entry.Manufacturer, Entry.Model, Entry.Id, BoolToStr(Entry.Online, True)]));
  if FRegistry.HealthCheck(Entry.Id) then
    Log('Health check OK');
end;

procedure TFormOnvifTest.btnRecordClick(Sender: TObject);
var
  Entry: TVMSCameraEntry;
  Uri: TStreamUri;
begin
  if Host = '' then
  begin
    Log('Select camera first.');
    Exit;
  end;
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  Entry := FRegistry.AddOrUpdate(Host, UserName, Password);
  Uri := FDevice.GetStreamUri(DefaultProfileToken(FDevice), 'RTP-Unicast', 'RTSP');
  if FRecordingEngine.StartRecording(Entry.Id, Uri.Uri,
    IncludeTrailingPathDelimiter(TPath.GetTempPath) + Entry.Id + '.mp4') then
    Log('Recording started (stub): ' + Uri.Uri)
  else
    Log('Recording failed.');
end;

procedure TFormOnvifTest.btnReplayClick(Sender: TObject);
var
  Xml: string;
  Recordings: TONVIFRecordings;
  Uri: TStreamUri;
begin
  if not FDevice.Connected and not ConnectCurrentHost then
    Exit;
  if FDevice.ReplayEndpoint = '' then
  begin
    Log('Replay not supported.');
    Exit;
  end;
  Xml := ONVIFGetRecordings(FDevice.RecordingEndpoint, FDevice.UserName, FDevice.Password);
  if not XMLRecordingsToRecordings(Xml, Recordings) or (Length(Recordings) = 0) then
  begin
    Log('No recordings on device.');
    Exit;
  end;
  if TVMSPlaybackService.GetDeviceReplayUri(FDevice, Recordings[0].token, Uri) then
    Log('Replay URI: ' + Uri.Uri)
  else
    Log('GetReplayUri failed.');
end;

procedure TFormOnvifTest.TreeView1Gesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if EventInfo.GestureID = igiDoubleTap then
    TreeView1DblClick(nil);
end;

end.
