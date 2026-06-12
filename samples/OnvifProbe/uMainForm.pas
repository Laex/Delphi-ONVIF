unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ONVIF, ONVIF.Demo, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Imaging.jpeg,
  Vcl.ExtCtrls, ONVIF.Types, VMS.CameraRegistry, VMS.EventHub, VMS.RecordingEngine, VMS.PlaybackService,
  ONVIF.Recording, ONVIF.Discovery, Vcl.Mask;

type
  TForm1 = class(TForm)
    onvfprb1: TONVIFProbe;
    btn1: TButton;
    tv1: TTreeView;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Panel1: TPanel;
    cmURL: TLabeledEdit;
    Button1: TButton;
    Image1: TImage;
    cmUser: TLabeledEdit;
    cmPass: TLabeledEdit;
    pnlActions: TPanel;
    btnConnect: TButton;
    btnStreamUri: TButton;
    btnPTZLeft: TButton;
    btnPTZRight: TButton;
    btnPTZUp: TButton;
    btnPTZDown: TButton;
    btnPTZStop: TButton;
    btnImaging: TButton;
    btnEvents: TButton;
    btnRegistry: TButton;
    btnEventHub: TButton;
    btnRecording: TButton;
    btnReplay: TButton;
    mmoLog: TMemo;
    Splitter1: TSplitter;
    pnlBottom: TPanel;
    edtUnicastHost: TLabeledEdit;
    btnUnicastProbe: TButton;
    edtSubnet: TLabeledEdit;
    btnSubnetScan: TButton;
    edtDirectHost: TLabeledEdit;
    edtDirectUser: TLabeledEdit;
    edtDirectPass: TLabeledEdit;
    btnDirectConnect: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btnUnicastProbeClick(Sender: TObject);
    procedure btnSubnetScanClick(Sender: TObject);
    procedure btnDirectConnectClick(Sender: TObject);
    procedure onvfprb1ProbeMath(const ProbeMatch: TProbeMatch);
    procedure onvfprb1Completed(Sender: TObject);
    procedure tv1DblClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnStreamUriClick(Sender: TObject);
    procedure btnPTZLeftClick(Sender: TObject);
    procedure btnPTZRightClick(Sender: TObject);
    procedure btnPTZUpClick(Sender: TObject);
    procedure btnPTZDownClick(Sender: TObject);
    procedure btnPTZStopClick(Sender: TObject);
    procedure btnImagingClick(Sender: TObject);
    procedure btnEventsClick(Sender: TObject);
    procedure btnRegistryClick(Sender: TObject);
    procedure btnEventHubClick(Sender: TObject);
    procedure btnRecordingClick(Sender: TObject);
    procedure btnReplayClick(Sender: TObject);
  private
    F: TProbeMatchArray;
    FDevice: TONVIFDevice;
    FRegistry: TVMSCameraRegistry;
    FEventHub: TVMSEventHub;
    FRecordingEngine: TVMSRecordingEngine;
    FSelectedIndex: Integer;
    FSelectedNode: TTreeNode;
    FPendingAlarm: TVMSAlarmEvent;
    procedure AddTreeLines(Root: TTreeNode; const Lines: TONVIFTreeLines);
    procedure Log(const Msg: string);
    procedure DoShowAlarm;
    procedure OnAlarm(const Event: TVMSAlarmEvent);
    function ConnectSelectedDevice: Boolean;
    function ConnectToXAddr(const XAddr, UserName, Password: string): Boolean;
    function SelectedXAddr: string;
    procedure RefreshDeviceTree;
    procedure PTZMove(Pan, Tilt, Zoom: Real);
    procedure BeginProbe;
    procedure EndProbe;
    procedure ApplyProbeResults;
  public
  end;

var
  Form1: TForm1;

implementation

uses
  uIPCameraLoginDlg;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  FDevice := TONVIFDevice.Create;
  FRegistry := TVMSCameraRegistry.Create;
  FEventHub := TVMSEventHub.Create(OnAlarm);
  FRecordingEngine := TVMSRecordingEngine.Create;
  FSelectedIndex := -1;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FRecordingEngine.Free;
  FEventHub.Free;
  FRegistry.Free;
  FDevice.Free;
end;

procedure TForm1.DoShowAlarm;
begin
  Log(Format('ALARM [%s] %s', [FPendingAlarm.CameraId, FPendingAlarm.Topic]));
end;

procedure TForm1.OnAlarm(const Event: TVMSAlarmEvent);
begin
  FPendingAlarm := Event;
  TThread.Synchronize(nil, DoShowAlarm);
end;

function TForm1.SelectedXAddr: string;
begin
  Result := '';
  if (FSelectedIndex >= 0) and (FSelectedIndex <= High(F)) then
    Result := F[FSelectedIndex].XAddrs;
end;

procedure TForm1.Log(const Msg: string);
begin
  mmoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + Msg);
end;

procedure TForm1.AddTreeLines(Root: TTreeNode; const Lines: TONVIFTreeLines);
var
  Line: TONVIFTreeLine;
  Parents: TArray<TTreeNode>;
begin
  for Line in Lines do
  begin
    if Length(Parents) <= Line.Depth then
      SetLength(Parents, Line.Depth + 1);
    if Line.Depth = 0 then
    begin
      if Assigned(Root) then
        Parents[0] := tv1.Items.AddChild(Root, Line.Text)
      else
        Parents[0] := tv1.Items.Add(nil, Line.Text);
    end
    else
      Parents[Line.Depth] := tv1.Items.AddChild(Parents[Line.Depth - 1], Line.Text);
  end;
end;

procedure TForm1.BeginProbe;
begin
  tv1.Items.Clear;
  mmoLog.Clear;
  btn1.Enabled := False;
  btnUnicastProbe.Enabled := False;
  btnSubnetScan.Enabled := False;
end;

procedure TForm1.EndProbe;
begin
  btn1.Enabled := True;
  btnUnicastProbe.Enabled := True;
  btnSubnetScan.Enabled := True;
end;

procedure TForm1.ApplyProbeResults;
var
  ProbeMatch: TProbeMatch;
begin
  F := UniqueProbeMatch(onvfprb1.ProbeMatchArray);
  tv1.Items.Clear;
  for ProbeMatch in F do
    AddTreeLines(nil, BuildProbeMatchTreeLines(ProbeMatch));
  Log('Probe found ' + Length(F).ToString + ' device(s). Double-click to connect.');
end;

procedure TForm1.btn1Click(Sender: TObject);
begin
  if not btn1.Enabled then
    Exit;
  BeginProbe;
  if not onvfprb1.ExecuteAsync then
  begin
    Log('Probe already running.');
    EndProbe;
  end;
end;

procedure TForm1.btnUnicastProbeClick(Sender: TObject);
begin
  if Trim(edtUnicastHost.Text) = '' then
  begin
    Log('Enter IP for unicast probe.');
    Exit;
  end;
  if not btn1.Enabled then
    Exit;
  BeginProbe;
  if not onvfprb1.ExecuteUnicastAsync(Trim(edtUnicastHost.Text)) then
  begin
    Log('Probe already running.');
    EndProbe;
  end;
end;

procedure TForm1.btnSubnetScanClick(Sender: TObject);
var
  Options: TONVIFSubnetProbeOptions;
  Hosts: TArray<string>;
begin
  if not ParseSubnetSpec(edtSubnet.Text, Options) then
  begin
    Log('Invalid subnet. Example: 192.168.1.0/24 or 192.168.1');
    Exit;
  end;
  Hosts := EnumerateSubnetHosts(Options);
  if Length(Hosts) = 0 then
  begin
    Log('Subnet has no scannable hosts.');
    Exit;
  end;
  if not btn1.Enabled then
    Exit;
  Log(Format('Subnet scan %s (%d hosts)...', [edtSubnet.Text, Length(Hosts)]));
  BeginProbe;
  onvfprb1.Timeout := 3000;
  if not onvfprb1.ExecuteSubnetAsync(Options) then
  begin
    Log('Probe already running.');
    EndProbe;
  end;
end;

function TForm1.ConnectToXAddr(const XAddr, UserName, Password: string): Boolean;
begin
  FDevice.Disconnect;
  Result := FDevice.Connect(XAddr, UserName, Password);
  if Result then
  begin
    Log('Connected: ' + FDevice.DeviceInfo.Manufacturer + ' ' + FDevice.DeviceInfo.Model);
    Log('Media API: ' + MediaApiKindToText(FDevice.MediaApi));
    cmURL.Text := XAddr;
    cmUser.Text := UserName;
    cmPass.Text := Password;
  end
  else
    Log('Connect failed: ' + XAddr);
end;

procedure TForm1.btnDirectConnectClick(Sender: TObject);
var
  XAddr, UserName, Password: string;
begin
  XAddr := NormalizeDeviceXAddr(edtDirectHost.Text);
  if XAddr = '' then
  begin
    Log('Enter IP, hostname or ONVIF device URL.');
    Exit;
  end;
  UserName := Trim(edtDirectUser.Text);
  Password := edtDirectPass.Text;
  if UserName = '' then
  begin
    if IPCameraLoginDlg(XAddr, UserName, Password) <> mrOk then
      Exit;
    edtDirectUser.Text := UserName;
    edtDirectPass.Text := Password;
  end;
  if ConnectToXAddr(XAddr, UserName, Password) then
  begin
    SetLength(F, 1);
    F[0].XAddrs := XAddr;
    FSelectedIndex := 0;
    tv1.Items.Clear;
    FSelectedNode := tv1.Items.Add(nil, XAddr);
    AddTreeLines(FSelectedNode, BuildConnectedDeviceTreeLines(FDevice));
    FSelectedNode.Expand(True);
  end;
end;

function TForm1.ConnectSelectedDevice: Boolean;
var
  UserName, Password: string;
  XAddr: string;
begin
  Result := False;
  if (FSelectedIndex < 0) or (FSelectedIndex > High(F)) then
  begin
    Log('Select a camera in the tree (double-click probe result).');
    Exit;
  end;
  XAddr := F[FSelectedIndex].XAddrs;
  if IPCameraLoginDlg(XAddr, UserName, Password) <> mrOk then
    Exit;
  Result := ConnectToXAddr(XAddr, UserName, Password);
end;

procedure TForm1.RefreshDeviceTree;
begin
  if not FDevice.Connected then
    Exit;
  if not Assigned(FSelectedNode) then
    Exit;
  FSelectedNode.DeleteChildren;
  AddTreeLines(FSelectedNode, BuildConnectedDeviceTreeLines(FDevice));
  FSelectedNode.Expand(True);
end;

procedure TForm1.btnConnectClick(Sender: TObject);
begin
  if ConnectSelectedDevice then
    RefreshDeviceTree;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Mst: TMemoryStream;
  Jpg: TJPEGImage;
  Snap: TSnapshotUri;
  Token: string;
  ContentType: string;
begin
  if not FDevice.Connected then
  begin
    if not FDevice.Connect(Trim(cmURL.Text), cmUser.Text, cmPass.Text) then
    begin
      Log('Snapshot: connect failed.');
      Exit;
    end;
  end;
  Token := DefaultProfileToken(FDevice);
  if Token = '' then
  begin
    Log('Snapshot: no profile.');
    Exit;
  end;
  Snap := FDevice.GetSnapshotUri(Token);
  Mst := TMemoryStream.Create;
  try
    if GetSnapshot(Snap.Uri, FDevice.UserName, FDevice.Password, Mst, ContentType) or
       GetSnapshot(Snap.Uri, cmUser.Text, cmPass.Text, Mst, ContentType) then
    begin
      Mst.Position := 0;
      Jpg := TJPEGImage.Create;
      try
        Jpg.LoadFromStream(Mst);
        Image1.Picture.Graphic := Jpg;
        Log('Snapshot loaded.');
      finally
        Jpg.Free;
      end;
    end
    else
      Log('Snapshot HTTP failed.');
  finally
    Mst.Free;
  end;
end;

procedure TForm1.btnStreamUriClick(Sender: TObject);
var
  Uri: TStreamUri;
  Token: string;
begin
  if not FDevice.Connected and not ConnectSelectedDevice then
    Exit;
  Token := DefaultProfileToken(FDevice);
  Uri := FDevice.GetStreamUri(Token, 'RTP-Unicast', 'RTSP');
  Log('RTSP: ' + Uri.Uri);
  RefreshDeviceTree;
end;

procedure TForm1.PTZMove(Pan, Tilt, Zoom: Real);
var
  V: TPTZVector;
  Token: string;
begin
  if not FDevice.Connected then
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
    Log(Format('PTZ move Pan=%.1f Tilt=%.1f', [Pan, Tilt]))
  else
    Log('PTZ move failed.');
end;

procedure TForm1.btnPTZLeftClick(Sender: TObject);
begin
  PTZMove(-0.5, 0, 0);
end;

procedure TForm1.btnPTZRightClick(Sender: TObject);
begin
  PTZMove(0.5, 0, 0);
end;

procedure TForm1.btnPTZUpClick(Sender: TObject);
begin
  PTZMove(0, 0.5, 0);
end;

procedure TForm1.btnPTZDownClick(Sender: TObject);
begin
  PTZMove(0, -0.5, 0);
end;

procedure TForm1.btnPTZStopClick(Sender: TObject);
var
  Token: string;
begin
  if not FDevice.Connected then
    Exit;
  Token := DefaultProfileToken(FDevice);
  if FDevice.PTZStop(Token) then
    Log('PTZ stopped.')
  else
    Log('PTZ stop failed.');
end;

procedure TForm1.btnImagingClick(Sender: TObject);
var
  Settings: TImagingSettings;
  Token: string;
begin
  if not FDevice.Connected and not ConnectSelectedDevice then
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
  Settings.Brightness := Settings.Brightness;
  if FDevice.SetImagingSettings(Token, Settings) then
    Log('Imaging settings applied (read-back).');
  RefreshDeviceTree;
end;

procedure TForm1.btnEventsClick(Sender: TObject);
var
  Sub: TONVIFSubscription;
  Msgs: TArray<TONVIFEventMessage>;
  M: TONVIFEventMessage;
begin
  if not FDevice.Connected and not ConnectSelectedDevice then
    Exit;
  if FDevice.EventsEndpoint = '' then
  begin
    Log('Events not supported.');
    Exit;
  end;
  if FDevice.CreateEventSubscription(Sub) then
  begin
    Log('Event subscription: ' + Sub.Reference);
    if FDevice.PullEvents(Sub.Reference, Msgs) then
      for M in Msgs do
        Log('Event: ' + M.Topic);
    RefreshDeviceTree;
  end
  else
    Log('CreatePullPointSubscription failed.');
end;

procedure TForm1.btnRegistryClick(Sender: TObject);
var
  Entry: TVMSCameraEntry;
  XAddr: string;
begin
  XAddr := SelectedXAddr;
  if XAddr = '' then
  begin
    Log('Select a camera first.');
    Exit;
  end;
  if not FDevice.Connected and not ConnectSelectedDevice then
    Exit;
  Entry := FRegistry.AddOrUpdate(XAddr, FDevice.UserName, FDevice.Password);
  Log(Format('Registry: %s %s [%s] online=%s',
    [Entry.Manufacturer, Entry.Model, Entry.Id, BoolToStr(Entry.Online, True)]));
  if FRegistry.HealthCheck(Entry.Id) then
    Log('Health check OK');
end;

procedure TForm1.btnEventHubClick(Sender: TObject);
var
  Entry: TVMSCameraEntry;
  Dev: TONVIFDevice;
  XAddr: string;
begin
  XAddr := SelectedXAddr;
  if XAddr = '' then
  begin
    Log('Select a camera first.');
    Exit;
  end;
  if not FDevice.Connected and not ConnectSelectedDevice then
    Exit;
  Entry := FRegistry.AddOrUpdate(XAddr, FDevice.UserName, FDevice.Password);
  Dev := FRegistry.GetDevice(Entry.Id);
  if Dev <> nil then
  begin
    FEventHub.StartMonitoring(Entry.Id, Dev);
    Log('EventHub monitoring: ' + Entry.Id);
  end;
end;

procedure TForm1.btnRecordingClick(Sender: TObject);
var
  Entry: TVMSCameraEntry;
  Uri: TStreamUri;
  XAddr: string;
begin
  XAddr := SelectedXAddr;
  if XAddr = '' then
  begin
    Log('Select a camera first.');
    Exit;
  end;
  if not FDevice.Connected and not ConnectSelectedDevice then
    Exit;
  Entry := FRegistry.AddOrUpdate(XAddr, FDevice.UserName, FDevice.Password);
  Uri := FDevice.GetStreamUri(DefaultProfileToken(FDevice), 'RTP-Unicast', 'RTSP');
  if FRecordingEngine.StartRecording(Entry.Id, Uri.Uri,
    IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + Entry.Id + '.mp4') then
    Log('Recording session started (stub): ' + Uri.Uri)
  else
    Log('Recording start failed.');
end;

procedure TForm1.btnReplayClick(Sender: TObject);
var
  Xml: string;
  Recordings: TONVIFRecordings;
  Uri: TStreamUri;
begin
  if not FDevice.Connected and not ConnectSelectedDevice then
    Exit;
  if FDevice.ReplayEndpoint = '' then
  begin
    Log('Replay not supported.');
    Exit;
  end;
  Xml := ONVIFGetRecordings(FDevice.RecordingEndpoint, FDevice.UserName, FDevice.Password);
  if not XMLRecordingsToRecordings(Xml, Recordings) or (Length(Recordings) = 0) then
  begin
    Log('No device recordings found.');
    Exit;
  end;
  if TVMSPlaybackService.GetDeviceReplayUri(FDevice, Recordings[0].token, Uri) then
    Log('Replay URI: ' + Uri.Uri)
  else
    Log('GetReplayUri failed.');
end;

procedure TForm1.onvfprb1Completed(Sender: TObject);
begin
  ApplyProbeResults;
  EndProbe;
end;

procedure TForm1.onvfprb1ProbeMath(const ProbeMatch: TProbeMatch);
begin
  tv1.Items.Add(nil, ProbeMatch.XAddrs);
end;

procedure TForm1.tv1DblClick(Sender: TObject);
var
  T: TTreeNode;
begin
  if not Assigned(tv1.Selected) then
    Exit;
  T := tv1.Selected;
  while Assigned(T.Parent) do
    T := T.Parent;
  FSelectedNode := T;
  FSelectedIndex := T.Index;
  if ConnectSelectedDevice then
    RefreshDeviceTree;
end;

end.
