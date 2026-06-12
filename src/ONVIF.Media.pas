unit ONVIF.Media;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_MEDIA = 'xmlns:trt="http://www.onvif.org/ver10/media/wsdl"';
  ONVIF_NS_SCHEMA = 'xmlns:tt="http://www.onvif.org/ver10/schema"';

function PrepareGetProfilesRequest(const UserName, Password: string): string;
function ONVIFGetProfiles(const Addr, UserName, Password: string): string;
function XMLProfilesToProfiles(const XMLProfiles: string; var Profiles: TProfiles): Boolean;

function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol,
  ProfileToken: string; UseTunnel: Boolean = False): string;
function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol,
  ProfileToken: string; UseTunnel: Boolean = False): string;
function XMLStreamUriToStreamUri(const XMLStreamUri: string; var StreamUri: TStreamUri): Boolean;

function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: string;
  var SnapshotUri: TSnapshotUri): Boolean;

function PrepareGetVideoSourcesRequest(const UserName, Password: string): string;
function ONVIFGetVideoSources(const Addr, UserName, Password: string): string;
function XMLVideoSourcesToVideoSources(const AXml: string; var Sources: TVideoSources): Boolean;

function PrepareStartMulticastStreamingRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFStartMulticastStreaming(const Addr, UserName, Password,
  ProfileToken: string): TONVIFRequestResult;

function PrepareStopMulticastStreamingRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFStopMulticastStreaming(const Addr, UserName, Password,
  ProfileToken: string): TONVIFRequestResult;

implementation

uses
  System.SysUtils,
  ONVIF.Core,
  ONVIF.Xml;

procedure ParseMulticastNode(const M: IONVIFXmlNode; var Multicast: TMulticastConfiguration);
var
  K, Addr: IONVIFXmlNode;
begin
  Addr := M.FindChild('Address');
  if Addr <> nil then
  begin
    Multicast.Address.Type_ := Addr.FindChild('Type').Text;
    Multicast.Address.IPv4Address := Addr.FindChild('IPv4Address').Text;
  end;
  K := M.FindChild('Port');
  if K <> nil then
    Multicast.Port := K.Text.ToInteger;
  K := M.FindChild('TTL');
  if K <> nil then
    Multicast.TTL := K.Text.ToInteger;
  K := M.FindChild('AutoStart');
  if K <> nil then
    Multicast.AutoStart := K.Text.ToBoolean;
end;

procedure ParseAnalyticsModule(const K: IONVIFXmlNode; var A: TAnalyticsModule);
var
  SI, EI, Item, Child: IONVIFXmlNode;
  I, J: Integer;
  S: TSimpleItem;
  E: TElementItem;
begin
  A.Type_ := K.Attr['Type'];
  if A.Type_ = '' then
    A.Type_ := K.FindChild('Type').Text;
  A.Name := K.Attr['Name'];
  if A.Name = '' then
    A.Name := K.FindChild('Name').Text;
  SI := K.FindChild('Parameters');
  if SI <> nil then
    SI := SI.FindChild('SimpleItem');
  if SI <> nil then
    for I := 0 to K.ChildCount - 1 do
    begin
      Child := K.Children[I];
      if SameText(Child.LocalName, 'Parameters') then
        for J := 0 to Child.ChildCount - 1 do
        begin
          Item := Child.Children[J];
          if SameText(Item.LocalName, 'SimpleItem') then
          begin
            S.Name := Item.Attr['Name'];
            S.Value := Item.Attr['Value'];
            SetLength(A.SimpleItem, Length(A.SimpleItem) + 1);
            A.SimpleItem[High(A.SimpleItem)] := S;
          end;
        end;
    end;
  EI := K.FindChild('Parameters');
  if EI <> nil then
    for I := 0 to EI.ChildCount - 1 do
    begin
      Item := EI.Children[I];
      if SameText(Item.LocalName, 'ElementItem') then
      begin
        E.Name := Item.Attr['Name'];
        SetLength(A.ElementItem, Length(A.ElementItem) + 1);
        A.ElementItem[High(A.ElementItem)] := E;
      end;
    end;
end;

procedure ParseEncoderCodec(const N: IONVIFXmlNode; var Profile: TProfile);
var
  M, K: IONVIFXmlNode;
begin
  M := N.FindChild('H264');
  if M <> nil then
  begin
    K := M.FindChild('GovLength');
    if K <> nil then
      Profile.VideoEncoderConfiguration.H264.GovLength := K.Text.ToInteger;
    K := M.FindChild('H264Profile');
    if K <> nil then
      Profile.VideoEncoderConfiguration.H264.H264Profile := K.Text;
  end;
  M := N.FindChild('JPEG');
  if M <> nil then
  begin
    Profile.VideoEncoderConfiguration.Encoding := 'JPEG';
    K := M.FindChild('GovLength');
    if K <> nil then
      Profile.VideoEncoderConfiguration.H264.GovLength := K.Text.ToInteger;
  end;
  M := N.FindChild('MPEG4');
  if M <> nil then
    Profile.VideoEncoderConfiguration.Encoding := 'MPEG4';
  M := N.FindChild('H265');
  if M <> nil then
    Profile.VideoEncoderConfiguration.Encoding := 'H265';
end;

procedure ParseProfileNode(const Node: IONVIFXmlNode; var Profile: TProfile);
var
  N, M, K: IONVIFXmlNode;
  J: Integer;
  A: TAnalyticsModule;
  FormatSettings: TFormatSettings;
begin
  FormatSettings := System.SysUtils.FormatSettings;
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';

  if Node.HasAttribute('fixed') then
    Profile.fixed := Node.Attr['fixed'].ToBoolean;
  Profile.token := Node.Attr['token'];
  N := Node.FindChild('Name');
  if N <> nil then
    Profile.Name := N.Text;

  N := Node.FindChild('VideoSourceConfiguration');
  if N <> nil then
  begin
    Profile.VideoSourceConfiguration.token := N.Attr['token'];
    M := N.FindChild('Name');
    if M <> nil then
      Profile.VideoSourceConfiguration.Name := M.Text;
    M := N.FindChild('UseCount');
    if M <> nil then
      Profile.VideoSourceConfiguration.UseCount := M.Text.ToInteger;
    M := N.FindChild('SourceToken');
    if M <> nil then
      Profile.VideoSourceConfiguration.SourceToken := M.Text;
    M := N.FindChild('Bounds');
    if M <> nil then
    begin
      Profile.VideoSourceConfiguration.Bounds.x := M.Attr['x'].ToInteger;
      Profile.VideoSourceConfiguration.Bounds.y := M.Attr['y'].ToInteger;
      Profile.VideoSourceConfiguration.Bounds.width := M.Attr['width'].ToInteger;
      Profile.VideoSourceConfiguration.Bounds.height := M.Attr['height'].ToInteger;
    end;
  end;

  N := Node.FindChild('VideoEncoderConfiguration');
  if N <> nil then
  begin
    Profile.VideoEncoderConfiguration.token := N.Attr['token'];
    M := N.FindChild('Name');
    if M <> nil then
      Profile.VideoEncoderConfiguration.Name := M.Text;
    M := N.FindChild('Encoding');
    if M <> nil then
      Profile.VideoEncoderConfiguration.Encoding := M.Text;
    M := N.FindChild('Resolution');
    if M <> nil then
    begin
      Profile.VideoEncoderConfiguration.Resolution.width := M.FindChild('Width').Text.ToInteger;
      Profile.VideoEncoderConfiguration.Resolution.height := M.FindChild('Height').Text.ToInteger;
    end;
    M := N.FindChild('Quality');
    if M <> nil then
      Profile.VideoEncoderConfiguration.Quality := Double.Parse(M.Text, FormatSettings);
    M := N.FindChild('RateControl');
    if M <> nil then
    begin
      Profile.VideoEncoderConfiguration.RateControl.FrameRateLimit :=
        M.FindChild('FrameRateLimit').Text.ToInteger;
      Profile.VideoEncoderConfiguration.RateControl.EncodingInterval :=
        M.FindChild('EncodingInterval').Text.ToInteger;
      Profile.VideoEncoderConfiguration.RateControl.BitrateLimit :=
        M.FindChild('BitrateLimit').Text.ToInteger;
    end;
    ParseEncoderCodec(N, Profile);
    M := N.FindChild('Multicast');
    if M <> nil then
      ParseMulticastNode(M, Profile.VideoEncoderConfiguration.Multicast);
    M := N.FindChild('SessionTimeout');
    if M <> nil then
      Profile.VideoEncoderConfiguration.SessionTimeout := M.Text;
  end;

  N := Node.FindChild('MetadataConfiguration');
  if N <> nil then
  begin
    Profile.MetadataConfiguration.token := N.Attr['token'];
    M := N.FindChild('Name');
    if M <> nil then
      Profile.MetadataConfiguration.Name := M.Text;
    M := N.FindChild('Analytics');
    if M <> nil then
      Profile.MetadataConfiguration.Analytics := M.Text.ToBoolean;
    M := N.FindChild('Multicast');
    if M <> nil then
      ParseMulticastNode(M, Profile.MetadataConfiguration.Multicast);
  end;

  N := Node.FindChild('VideoAnalyticsConfiguration');
  if N <> nil then
  begin
    Profile.VideoAnalyticsConfiguration.token := N.Attr['token'];
    M := N.FindChild('AnalyticsEngineConfiguration');
    if M <> nil then
      for J := 0 to M.ChildCount - 1 do
      begin
        K := M.Children[J];
        if SameText(K.LocalName, 'AnalyticsModule') then
        begin
          A := default(TAnalyticsModule);
          ParseAnalyticsModule(K, A);
          SetLength(Profile.VideoAnalyticsConfiguration.AnalyticsEngineConfiguration,
            Length(Profile.VideoAnalyticsConfiguration.AnalyticsEngineConfiguration) + 1);
          Profile.VideoAnalyticsConfiguration.AnalyticsEngineConfiguration[
            High(Profile.VideoAnalyticsConfiguration.AnalyticsEngineConfiguration)] := A;
        end;
      end;
    M := N.FindChild('RuleEngineConfiguration');
    if M <> nil then
      for J := 0 to M.ChildCount - 1 do
      begin
        K := M.Children[J];
        if SameText(K.LocalName, 'Rule') then
        begin
          A := default(TAnalyticsModule);
          ParseAnalyticsModule(K, A);
          SetLength(Profile.VideoAnalyticsConfiguration.RuleEngineConfiguration,
            Length(Profile.VideoAnalyticsConfiguration.RuleEngineConfiguration) + 1);
          Profile.VideoAnalyticsConfiguration.RuleEngineConfiguration[
            High(Profile.VideoAnalyticsConfiguration.RuleEngineConfiguration)] := A;
        end;
      end;
  end;

  N := Node.FindChild('AudioEncoderConfiguration');
  if N <> nil then
  begin
    Profile.AudioEncoderConfiguration.token := N.Attr['token'];
    M := N.FindChild('Encoding');
    if M <> nil then
      Profile.AudioEncoderConfiguration.Encoding := M.Text;
    M := N.FindChild('Bitrate');
    if M <> nil then
      Profile.AudioEncoderConfiguration.Bitrate := M.Text.ToInteger;
    M := N.FindChild('SampleRate');
    if M <> nil then
      Profile.AudioEncoderConfiguration.SampleRate := M.Text.ToInteger;
  end;

  N := Node.FindChild('PTZConfiguration');
  if N <> nil then
  begin
    Profile.PTZConfiguration.token := N.Attr['token'];
    M := N.FindChild('NodeToken');
    if M <> nil then
      Profile.PTZConfiguration.NodeToken := M.Text;
  end;
end;

function PrepareGetProfilesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA,
    '<trt:GetProfiles/>', UserName, Password);
end;

function ONVIFGetProfiles(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetProfilesRequest(UserName, Password), Result);
end;

function XMLProfilesToProfiles(const XMLProfiles: string; var Profiles: TProfiles): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  Profile: TProfile;
begin
  SetLength(Profiles, 0);
  Result := False;
  Doc := LoadONVIFXml(XMLProfiles);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetProfilesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not (SameText(Node.LocalName, 'Profiles') or SameText(Node.LocalName, 'Profile')) then
      Continue;
    Profile := default(TProfile);
    ParseProfileNode(Node, Profile);
    SetLength(Profiles, Length(Profiles) + 1);
    Profiles[High(Profiles)] := Profile;
  end;
  Result := True;
end;

function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol,
  ProfileToken: string; UseTunnel: Boolean): string;
const
  BodyFmtTunnel =
    '<trt:GetStreamUri><trt:StreamSetup><tt:Stream>%s</tt:Stream>' +
    '<tt:Transport><tt:Protocol>%s</tt:Protocol><tt:Tunnel/></tt:Transport>' +
    '</trt:StreamSetup><trt:ProfileToken>%s</trt:ProfileToken></trt:GetStreamUri>';
  BodyFmtNoTunnel =
    '<trt:GetStreamUri><trt:StreamSetup><tt:Stream>%s</tt:Stream>' +
    '<tt:Transport><tt:Protocol>%s</tt:Protocol></tt:Transport>' +
    '</trt:StreamSetup><trt:ProfileToken>%s</trt:ProfileToken></trt:GetStreamUri>';
begin
  if UseTunnel then
    Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA + ' ' + ONVIF_NS_SCHEMA,
      Format(BodyFmtTunnel, [Stream, Protocol, ProfileToken]), UserName, Password)
  else
    Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA + ' ' + ONVIF_NS_SCHEMA,
      Format(BodyFmtNoTunnel, [Stream, Protocol, ProfileToken]), UserName, Password);
end;

function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol,
  ProfileToken: string; UseTunnel: Boolean): string;
begin
  ONVIFRequest(Addr, PrepareGetStreamUriRequest(UserName, Password, Stream, Protocol,
    ProfileToken, UseTunnel), Result);
end;

function XMLStreamUriToStreamUri(const XMLStreamUri: string; var StreamUri: TStreamUri): Boolean;
begin
  Result := ParseMediaUriResponse(XMLStreamUri, 'GetStreamUriResponse', StreamUri);
end;

function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA,
    Format('<trt:GetSnapshotUri><trt:ProfileToken>%s</trt:ProfileToken></trt:GetSnapshotUri>',
      [ProfileToken]), UserName, Password);
end;

function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetSnapshotUriRequest(UserName, Password, ProfileToken), Result);
end;

function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: string;
  var SnapshotUri: TSnapshotUri): Boolean;
begin
  Result := ParseMediaUriResponse(XMLSnapshotUri, 'GetSnapshotUriResponse', SnapshotUri);
end;

function PrepareGetVideoSourcesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA,
    '<trt:GetVideoSources/>', UserName, Password);
end;

function ONVIFGetVideoSources(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetVideoSourcesRequest(UserName, Password), Result);
end;

function XMLVideoSourcesToVideoSources(const AXml: string; var Sources: TVideoSources): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node, Res: IONVIFXmlNode;
  I: Integer;
  VS: TVideoSource;
  FormatSettings: TFormatSettings;
begin
  SetLength(Sources, 0);
  Result := False;
  FormatSettings := TFormatSettings.Invariant;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetVideoSourcesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'VideoSources') then
      Continue;
    VS.token := Node.Attr['token'];
    Res := Node.FindChild('Resolution');
    if Res <> nil then
    begin
      VS.ResolutionWidth := Res.FindChild('Width').Text.ToInteger;
      VS.ResolutionHeight := Res.FindChild('Height').Text.ToInteger;
    end;
    VS.Framerate := StrToFloatDef(Node.FindChild('Framerate').Text, 0, FormatSettings);
    SetLength(Sources, Length(Sources) + 1);
    Sources[High(Sources)] := VS;
  end;
  Result := Length(Sources) > 0;
end;

function PrepareStartMulticastStreamingRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := Format('<trt:StartMulticastStreaming><trt:ProfileToken>%s</trt:ProfileToken></trt:StartMulticastStreaming>',
    [ProfileToken]);
end;

function ONVIFStartMulticastStreaming(const Addr, UserName, Password,
  ProfileToken: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_MEDIA,
    PrepareStartMulticastStreamingRequest(UserName, Password, ProfileToken), UserName, Password);
end;

function PrepareStopMulticastStreamingRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := Format('<trt:StopMulticastStreaming><trt:ProfileToken>%s</trt:ProfileToken></trt:StopMulticastStreaming>',
    [ProfileToken]);
end;

function ONVIFStopMulticastStreaming(const Addr, UserName, Password,
  ProfileToken: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_MEDIA,
    PrepareStopMulticastStreamingRequest(UserName, Password, ProfileToken), UserName, Password);
end;

end.
