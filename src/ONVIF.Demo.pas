unit ONVIF.Demo;

interface

uses
  ONVIF.Types,
  ONVIF.Client;

type
  TONVIFTreeLine = record
    Depth: Integer;
    Text: string;
  end;

  TONVIFTreeLines = TArray<TONVIFTreeLine>;

function ServiceTypeToText(const AServiceType: TONVIFServiceType): string;
function MediaApiKindToText(const AKind: TONVIFMediaApiKind): string;
function BuildProbeMatchTreeLines(const ProbeMatch: TProbeMatch): TONVIFTreeLines;
function BuildProfileTreeLines(const Profile: TProfile): TONVIFTreeLines;
function BuildCapabilitiesTreeLines(const Capabilities: TONVIFCapabilities): TONVIFTreeLines;
function BuildConnectedDeviceTreeLines(const Device: TONVIFDevice): TONVIFTreeLines;
function DefaultProfileToken(const Device: TONVIFDevice): string;
function DefaultVideoSourceToken(const Device: TONVIFDevice): string;

implementation

uses
  System.SysUtils,
  ONVIF.Device,
  ONVIF.Media,
  ONVIF.PTZ,
  ONVIF.Imaging,
  ONVIF.Analytics,
  ONVIF.Recording,
  ONVIF.Events;

procedure AddLine(var Lines: TONVIFTreeLines; Depth: Integer; const Text: string);
begin
  SetLength(Lines, Length(Lines) + 1);
  Lines[High(Lines)].Depth := Depth;
  Lines[High(Lines)].Text := Text;
end;

function ServiceTypeToText(const AServiceType: TONVIFServiceType): string;
begin
  case AServiceType of
    stDevice: Result := 'Device';
    stMedia: Result := 'Media';
    stMedia2: Result := 'Media2';
    stPTZ: Result := 'PTZ';
    stImaging: Result := 'Imaging';
    stEvents: Result := 'Events';
    stAnalytics: Result := 'Analytics';
    stRecording: Result := 'Recording';
    stSearch: Result := 'Search';
    stReplay: Result := 'Replay';
    stDeviceIO: Result := 'DeviceIO';
  else
    Result := 'Unknown';
  end;
end;

function MediaApiKindToText(const AKind: TONVIFMediaApiKind): string;
begin
  case AKind of
    makMedia10: Result := 'ONVIF Media ver10';
    makMedia20: Result := 'ONVIF Media2 ver20';
  else
    Result := 'Unknown';
  end;
end;

function DefaultProfileToken(const Device: TONVIFDevice): string;
begin
  Result := '';
  if (Device <> nil) and (Length(Device.Profiles) > 0) then
    Result := Device.Profiles[0].token;
end;

function DefaultVideoSourceToken(const Device: TONVIFDevice): string;
begin
  Result := '';
  if (Device <> nil) and (Length(Device.Profiles) > 0) then
    Result := Device.Profiles[0].VideoSourceConfiguration.SourceToken;
end;

function BuildProbeMatchTreeLines(const ProbeMatch: TProbeMatch): TONVIFTreeLines;
var
  S: string;
begin
  Result := nil;
  AddLine(Result, 0, 'IP4: ' + ProbeMatch.XAddrs);
  if Length(ProbeMatch.XAddrsV6) > 0 then
    AddLine(Result, 1, 'IP6: ' + ProbeMatch.XAddrsV6);
  AddLine(Result, 1, 'Type:');
  if ptNetworkVideoTransmitter in ProbeMatch.Types then
    AddLine(Result, 2, 'NetworkVideoTransmitter');
  if ptDevice in ProbeMatch.Types then
    AddLine(Result, 2, 'Device');
  if ptNetworkVideoDisplay in ProbeMatch.Types then
    AddLine(Result, 2, 'NetworkVideoDisplay');
  AddLine(Result, 1, 'Scopes:');
  for S in ProbeMatch.Scopes do
    AddLine(Result, 2, S);
  AddLine(Result, 1, 'MetadataVersion: ' + ProbeMatch.MetadataVersion.ToString);
end;

function BuildProfileTreeLines(const Profile: TProfile): TONVIFTreeLines;
begin
  Result := nil;
  AddLine(Result, 0, 'Name: ' + Profile.Name);
  AddLine(Result, 1, 'fixed: ' + Profile.fixed.ToString(True));
  AddLine(Result, 1, 'token: ' + Profile.token);

  AddLine(Result, 1, 'VideoSourceConfiguration');
  AddLine(Result, 2, 'Name: ' + Profile.VideoSourceConfiguration.Name);
  AddLine(Result, 2, 'token: ' + Profile.VideoSourceConfiguration.token);
  AddLine(Result, 2, 'SourceToken: ' + Profile.VideoSourceConfiguration.SourceToken);
  AddLine(Result, 2, 'Bounds: ' + Format('(x:%d, y:%d, w:%d, h:%d)',
    [Profile.VideoSourceConfiguration.Bounds.x, Profile.VideoSourceConfiguration.Bounds.y,
     Profile.VideoSourceConfiguration.Bounds.width, Profile.VideoSourceConfiguration.Bounds.height]));

  AddLine(Result, 1, 'VideoEncoderConfiguration');
  AddLine(Result, 2, 'Encoding: ' + Profile.VideoEncoderConfiguration.Encoding);
  AddLine(Result, 2, 'Resolution: ' + Format('%dx%d',
    [Profile.VideoEncoderConfiguration.Resolution.width,
     Profile.VideoEncoderConfiguration.Resolution.height]));
  AddLine(Result, 2, 'Quality: ' + Profile.VideoEncoderConfiguration.Quality.ToString);
  AddLine(Result, 2, 'H264Profile: ' + Profile.VideoEncoderConfiguration.H264.H264Profile);

  if Profile.MetadataConfiguration.token <> '' then
  begin
    AddLine(Result, 1, 'MetadataConfiguration');
    AddLine(Result, 2, 'token: ' + Profile.MetadataConfiguration.token);
    AddLine(Result, 2, 'Analytics: ' + Profile.MetadataConfiguration.Analytics.ToString(True));
  end;

  if Profile.PTZConfiguration.token <> '' then
  begin
    AddLine(Result, 1, 'PTZConfiguration');
    AddLine(Result, 2, 'token: ' + Profile.PTZConfiguration.token);
    AddLine(Result, 2, 'NodeToken: ' + Profile.PTZConfiguration.NodeToken);
  end;

  if Length(Profile.VideoAnalyticsConfiguration.AnalyticsEngineConfiguration) > 0 then
    AddLine(Result, 1, 'AnalyticsModules: ' +
      Length(Profile.VideoAnalyticsConfiguration.AnalyticsEngineConfiguration).ToString);
  if Length(Profile.VideoAnalyticsConfiguration.RuleEngineConfiguration) > 0 then
    AddLine(Result, 1, 'Rules: ' +
      Length(Profile.VideoAnalyticsConfiguration.RuleEngineConfiguration).ToString);
end;

function BuildCapabilitiesTreeLines(const Capabilities: TONVIFCapabilities): TONVIFTreeLines;
var
  S: TONVIFServiceEndpoint;
begin
  Result := nil;
  AddLine(Result, 0, 'DeviceXAddr: ' + Capabilities.DeviceXAddr);
  AddLine(Result, 0, 'Services:');
  for S in Capabilities.Services do
    AddLine(Result, 1, Format('%s -> %s', [ServiceTypeToText(S.ServiceType), S.XAddr]));
end;

function BuildConnectedDeviceTreeLines(const Device: TONVIFDevice): TONVIFTreeLines;
var
  I: Integer;
  Profile: TProfile;
  CapLines, SubLines: TONVIFTreeLines;
  Xml: string;
  DateTime: TONVIFDateTime;
  Hostname: TONVIFHostnameInformation;
  Sources: TVideoSources;
  VS: TVideoSource;
  Status: TPTZStatus;
  Settings: TImagingSettings;
  Modules: TArray<TAnalyticsModule>;
  Rules: TArray<TRule>;
  Recordings: TONVIFRecordings;
  Summary: TONVIFRecordingSummary;
  ProfileToken, VideoSourceToken: string;
  StreamUri: TStreamUri;
  SnapUri: TSnapshotUri;
  Subscription: TONVIFSubscription;
  Messages: TONVIFEventMessages;
  M: TONVIFEventMessage;
begin
  Result := nil;
  if (Device = nil) or not Device.Connected then
    Exit;

  AddLine(Result, 0, 'Connection');
  AddLine(Result, 1, 'Media API: ' + MediaApiKindToText(Device.MediaApi));
  AddLine(Result, 1, 'Media endpoint: ' + Device.MediaEndpoint);

  AddLine(Result, 0, 'DeviceInformation');
  AddLine(Result, 1, 'Manufacturer: ' + Device.DeviceInfo.Manufacturer);
  AddLine(Result, 1, 'Model: ' + Device.DeviceInfo.Model);
  AddLine(Result, 1, 'Firmware: ' + Device.DeviceInfo.FirmwareVersion);
  AddLine(Result, 1, 'Serial: ' + Device.DeviceInfo.SerialNumber);

  CapLines := BuildCapabilitiesTreeLines(Device.Capabilities);
  for I := 0 to High(CapLines) do
    AddLine(Result, CapLines[I].Depth, CapLines[I].Text);

  Xml := ONVIFGetSystemDateAndTime(Device.DeviceXAddr);
  if XMLSystemDateAndTimeToDateTime(Xml, DateTime) then
  begin
    AddLine(Result, 0, 'SystemDateAndTime');
    AddLine(Result, 1, 'UTC: ' + DateTimeToStr(DateTime.UTCDateTime));
    AddLine(Result, 1, 'TimeZone: ' + DateTime.TimeZone);
  end;

  Xml := ONVIFGetHostname(Device.DeviceXAddr, Device.UserName, Device.Password);
  if XMLHostnameToHostname(Xml, Hostname) then
  begin
    AddLine(Result, 0, 'Hostname');
    AddLine(Result, 1, Hostname.Name);
  end;

  if Device.MediaEndpoint <> '' then
  begin
    Xml := ONVIFGetVideoSources(Device.MediaEndpoint, Device.UserName, Device.Password);
    if XMLVideoSourcesToVideoSources(Xml, Sources) then
    begin
      AddLine(Result, 0, 'VideoSources');
      for VS in Sources do
        AddLine(Result, 1, Format('%s (%dx%d @ %.1f fps)',
          [VS.token, VS.ResolutionWidth, VS.ResolutionHeight, VS.Framerate]));
    end;
  end;

  AddLine(Result, 0, 'Profiles (' + Length(Device.Profiles).ToString + ')');
  for Profile in Device.Profiles do
  begin
    SubLines := BuildProfileTreeLines(Profile);
    for I := 0 to High(SubLines) do
      AddLine(Result, SubLines[I].Depth + 1, SubLines[I].Text);
  end;

  ProfileToken := DefaultProfileToken(Device);
  if ProfileToken <> '' then
  begin
    StreamUri := Device.GetStreamUri(ProfileToken, 'RTP-Unicast', 'RTSP');
    if StreamUri.Uri <> '' then
    begin
      AddLine(Result, 0, 'StreamUri');
      AddLine(Result, 1, StreamUri.Uri);
    end;
    SnapUri := Device.GetSnapshotUri(ProfileToken);
    if SnapUri.Uri <> '' then
    begin
      AddLine(Result, 0, 'SnapshotUri');
      AddLine(Result, 1, SnapUri.Uri);
    end;
  end;

  if Device.PTZEndpoint <> '' then
  begin
    AddLine(Result, 0, 'PTZ');
    AddLine(Result, 1, 'Endpoint: ' + Device.PTZEndpoint);
    if ProfileToken <> '' then
    begin
      Xml := ONVIFPTZGetStatus(Device.PTZEndpoint, Device.UserName, Device.Password, ProfileToken);
      if XMLPTZStatusToStatus(Xml, Status) then
      begin
        AddLine(Result, 1, Format('Position Pan=%.2f Tilt=%.2f Zoom=%.2f',
          [Status.Position.Pan, Status.Position.Tilt, Status.Position.Zoom]));
        AddLine(Result, 1, 'MoveStatus: ' + Status.MoveStatus);
      end;
    end;
  end;

  VideoSourceToken := DefaultVideoSourceToken(Device);
  if (Device.ImagingEndpoint <> '') and (VideoSourceToken <> '') then
  begin
    Xml := ONVIFGetImagingSettings(Device.ImagingEndpoint, Device.UserName, Device.Password,
      VideoSourceToken);
    if XMLImagingSettingsToSettings(Xml, Settings) then
    begin
      AddLine(Result, 0, 'Imaging');
      AddLine(Result, 1, Format('Brightness=%.1f Contrast=%.1f Sharpness=%.1f',
        [Settings.Brightness, Settings.Contrast, Settings.Sharpness]));
    end;
  end;

  if (Device.AnalyticsEndpoint <> '') and (ProfileToken <> '') and
     (Device.Profiles[0].VideoAnalyticsConfiguration.token <> '') then
  begin
    Xml := ONVIFGetAnalyticsModules(Device.AnalyticsEndpoint, Device.UserName, Device.Password,
      Device.Profiles[0].VideoAnalyticsConfiguration.token);
    if XMLAnalyticsModulesToModules(Xml, Modules) then
      AddLine(Result, 0, 'Analytics modules: ' + Length(Modules).ToString);
    Xml := ONVIFGetRules(Device.AnalyticsEndpoint, Device.UserName, Device.Password,
      Device.Profiles[0].VideoAnalyticsConfiguration.token);
    if XMLRulesToRules(Xml, Rules) then
      AddLine(Result, 0, 'Analytics rules: ' + Length(Rules).ToString);
  end;

  if Device.EventsEndpoint <> '' then
  begin
    AddLine(Result, 0, 'Events');
    AddLine(Result, 1, 'Endpoint: ' + Device.EventsEndpoint);
    if Device.CreateEventSubscription(Subscription) then
    begin
      AddLine(Result, 1, 'Subscription: ' + Subscription.Reference);
      if Device.PullEvents(Subscription.Reference, Messages) then
        AddLine(Result, 1, 'Pulled messages: ' + Length(Messages).ToString)
      else
        AddLine(Result, 1, 'PullMessages: (no messages)');
      for M in Messages do
        AddLine(Result, 2, M.Topic + ' @ ' + DateTimeToStr(M.UtcTime));
    end
    else
      AddLine(Result, 1, 'Subscription: not available');
  end;

  if Device.RecordingEndpoint <> '' then
  begin
    Xml := ONVIFGetRecordings(Device.RecordingEndpoint, Device.UserName, Device.Password);
    if XMLRecordingsToRecordings(Xml, Recordings) then
      AddLine(Result, 0, 'Recordings: ' + Length(Recordings).ToString);
    Xml := ONVIFGetRecordingSummary(Device.RecordingEndpoint, Device.UserName, Device.Password);
    if XMLRecordingSummaryToSummary(Xml, Summary) then
      AddLine(Result, 1, Format('Archive %s .. %s (%d)',
        [DateTimeToStr(Summary.DataFrom), DateTimeToStr(Summary.DataUntil),
         Summary.NumberRecordings]));
  end;

  if Device.ReplayEndpoint <> '' then
    AddLine(Result, 0, 'Replay endpoint: ' + Device.ReplayEndpoint);
end;

end.
