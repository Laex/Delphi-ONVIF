unit ONVIF;

interface

uses
  System.Classes,
  System.SysUtils,
{$IFDEF ANDROID}
  Androidapi.JNI.Net,
{$ENDIF ANDROID}
  ONVIF.Types,
  ONVIF.Core,
  ONVIF.Device,
  ONVIF.Media,
  ONVIF.Media2,
  ONVIF.PTZ,
  ONVIF.Imaging,
  ONVIF.Events,
  ONVIF.Analytics,
  ONVIF.Recording,
  ONVIF.Client,
  ONVIF.Services,
  ONVIF.Discovery,
  ONVIF.Platform;

type
  TLogMessage = ONVIF.Types.TLogMessage;
  TProbeType = ONVIF.Types.TProbeType;
  TProbeTypeSet = ONVIF.Types.TProbeTypeSet;
  TONVIFProbeMode = ONVIF.Types.TONVIFProbeMode;
  TONVIFSubnetProbeOptions = ONVIF.Types.TONVIFSubnetProbeOptions;
  TBindToAllAvailableLocalIPsType = ONVIF.Types.TBindToAllAvailableLocalIPsType;
  TBindToAllAvailableLocalIPsTypeSet = ONVIF.Types.TBindToAllAvailableLocalIPsTypeSet;
  TProbeMatchXMLArray = ONVIF.Types.TProbeMatchXMLArray;
  TProbeMatch = ONVIF.Types.TProbeMatch;
  TProbeMatchArray = ONVIF.Types.TProbeMatchArray;
  TProbeMatchNotify = ONVIF.Types.TProbeMatchNotify;
  TProbeMatchXMLNotify = ONVIF.Types.TProbeMatchXMLNotify;
  TProbeMathNotify = ONVIF.Types.TProbeMathNotify;
  TProbeMathXMLNotify = ONVIF.Types.TProbeMathXMLNotify;
  TLogMessageNotify = ONVIF.Types.TLogMessageNotify;
  TONVIFProbe = ONVIF.Discovery.TONVIFProbe;
  TONVIFProbeThread = ONVIF.Discovery.TONVIFProbeThread;
  TIPv4 = ONVIF.Types.TIPv4;
  TDeviceInformation = ONVIF.Types.TDeviceInformation;
  TSimpleItem = ONVIF.Types.TSimpleItem;
  TRealPoint = ONVIF.Types.TRealPoint;
  TElementItemXY = ONVIF.Types.TElementItemXY;
  TElementItemLayout = ONVIF.Types.TElementItemLayout;
  TPolygon = ONVIF.Types.TPolygon;
  TElementItemField = ONVIF.Types.TElementItemField;
  TElementItemTransform = ONVIF.Types.TElementItemTransform;
  TElementItem = ONVIF.Types.TElementItem;
  TAnalyticsModule = ONVIF.Types.TAnalyticsModule;
  TRule = ONVIF.Types.TRule;
  TMulticastAddress = ONVIF.Types.TMulticastAddress;
  TMulticastConfiguration = ONVIF.Types.TMulticastConfiguration;
  TProfile = ONVIF.Types.TProfile;
  TProfiles = ONVIF.Types.TProfiles;
  TStreamUri = ONVIF.Types.TStreamUri;
  TSnapshotUri = ONVIF.Types.TSnapshotUri;
  TONVIFAddrType = ONVIF.Types.TONVIFAddrType;
  TONVIFServiceType = ONVIF.Types.TONVIFServiceType;
  TONVIFMediaApiKind = ONVIF.Types.TONVIFMediaApiKind;
  TONVIFServiceEndpoint = ONVIF.Types.TONVIFServiceEndpoint;
  TONVIFSoapFault = ONVIF.Types.TONVIFSoapFault;
  TONVIFRequestResult = ONVIF.Types.TONVIFRequestResult;
  TONVIFCapabilities = ONVIF.Types.TONVIFCapabilities;
  TONVIFDateTime = ONVIF.Types.TONVIFDateTime;
  TPTZVector = ONVIF.Types.TPTZVector;
  TPTZStatus = ONVIF.Types.TPTZStatus;
  TImagingSettings = ONVIF.Types.TImagingSettings;
  TONVIFSubscription = ONVIF.Types.TONVIFSubscription;
  TONVIFEventMessage = ONVIF.Types.TONVIFEventMessage;
  TONVIFDevice = ONVIF.Client.TONVIFDevice;

const
  atDeviceService = ONVIF.Types.atDeviceService;
  atMedia = ONVIF.Types.atMedia;

function ONVIFProbe: TProbeMatchArray;
function ONVIFUnicastProbe(const Host: string; Timeout: Cardinal = 1000): TProbeMatchArray;
function ONVIFSubnetProbe(const Options: TONVIFSubnetProbeOptions;
  Timeout: Cardinal = 3000): TProbeMatchArray;
function DefaultSubnetProbeOptions: TONVIFSubnetProbeOptions;
function ParseSubnetSpec(const Spec: string; out Options: TONVIFSubnetProbeOptions): Boolean;
function EnumerateSubnetHosts(const Options: TONVIFSubnetProbeOptions): TArray<string>;
function NormalizeDeviceXAddr(const HostOrUrl: string): string;
function ParseIPv4Address(const S: string; out A, B, C, D: Byte): Boolean;
function XMLToProbeMatch(const ProbeMatchXML: string; var ProbeMatch: TProbeMatch): Boolean;
function UniqueProbeMatch(const ProbeMatch: TProbeMatchArray): TProbeMatchArray;

function ONVIFGetDeviceInformation(const Addr, UserName, Password: string): string;
function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: string;
  var DeviceInformation: TDeviceInformation): Boolean;
function PrepareGetDeviceInformationRequest(const UserName, Password: string): string;

function ONVIFGetProfiles(const Addr, UserName, Password: string): string;
function XMLProfilesToProfiles(const XMLProfiles: string; var Profiles: TProfiles): Boolean;
function PrepareGetProfilesRequest(const UserName, Password: string): string;

function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol,
  ProfileToken: string): string;
function XMLStreamUriToStreamUri(const XMLStreamUri: string; var StreamUri: TStreamUri): Boolean;
function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol,
  ProfileToken: string): string;

function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: string;
  var SnapshotUri: TSnapshotUri): Boolean;
function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;

function GetSnapshot(const SnapshotUri: string; const Stream: TStream): Boolean; overload;
function GetSnapshot(const SnapshotUri, UserName, Password: string;
  const Stream: TStream; out ContentType: string): Boolean; overload;

procedure ONVIFRequest(const Addr: string; const InStream, OutStream: TStringStream); overload;
procedure ONVIFRequest(const Addr, Request: string; var Answer: string); overload;

procedure GetONVIFPasswordDigest(const UserName, Password: string;
  var PasswordDigest, Nonce, Created: string);
function GetONVIFDateTime(const DateTime: TDateTime): string;
function BytesToString(Data: TBytes): string;
function StringToBytes(const AData: string): TBytes;
function SHA1(const Data: TBytes): TBytes;

function GetONVIFAddr(const XAddr: string; const ONVIFAddrType: TONVIFAddrType): string;
function GetIPFromHost(var IPaddr: string): Boolean;

function ParseSoapFault(const AXml: string): TONVIFSoapFault;
function ExecuteSoapRequest(const Addr, EnvelopeNs, BodyXml, UserName, Password: string): TONVIFRequestResult;
function XMLToProbeMatches(const ProbeMatchXML: string): TProbeMatchArray;
function DiscoverCapabilities(const DeviceXAddr, UserName, Password: string): TONVIFCapabilities;

{$IFDEF ANDROID}
function GetWiFiManager: JWifiManager;
{$ENDIF ANDROID}

procedure Register;

implementation

function ONVIFProbe: TProbeMatchArray;
begin
  Result := ONVIF.Discovery.ONVIFProbe;
end;

function ONVIFUnicastProbe(const Host: string; Timeout: Cardinal): TProbeMatchArray;
begin
  Result := ONVIF.Discovery.ONVIFUnicastProbe(Host, Timeout);
end;

function ONVIFSubnetProbe(const Options: TONVIFSubnetProbeOptions;
  Timeout: Cardinal): TProbeMatchArray;
begin
  Result := ONVIF.Discovery.ONVIFSubnetProbe(Options, Timeout);
end;

function DefaultSubnetProbeOptions: TONVIFSubnetProbeOptions;
begin
  Result := ONVIF.Discovery.DefaultSubnetProbeOptions;
end;

function ParseSubnetSpec(const Spec: string; out Options: TONVIFSubnetProbeOptions): Boolean;
begin
  Result := ONVIF.Discovery.ParseSubnetSpec(Spec, Options);
end;

function EnumerateSubnetHosts(const Options: TONVIFSubnetProbeOptions): TArray<string>;
begin
  Result := ONVIF.Discovery.EnumerateSubnetHosts(Options);
end;

function NormalizeDeviceXAddr(const HostOrUrl: string): string;
begin
  Result := ONVIF.Core.NormalizeDeviceXAddr(HostOrUrl);
end;

function ParseIPv4Address(const S: string; out A, B, C, D: Byte): Boolean;
begin
  Result := ONVIF.Core.ParseIPv4Address(S, A, B, C, D);
end;

function XMLToProbeMatch(const ProbeMatchXML: string; var ProbeMatch: TProbeMatch): Boolean;
begin
  Result := ONVIF.Core.XMLToProbeMatch(ProbeMatchXML, ProbeMatch);
end;

function UniqueProbeMatch(const ProbeMatch: TProbeMatchArray): TProbeMatchArray;
begin
  Result := ONVIF.Core.UniqueProbeMatch(ProbeMatch);
end;

function ONVIFGetDeviceInformation(const Addr, UserName, Password: string): string;
begin
  Result := ONVIF.Services.ONVIFGetDeviceInformation(Addr, UserName, Password);
end;

function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: string;
  var DeviceInformation: TDeviceInformation): Boolean;
begin
  Result := ONVIF.Services.XMLDeviceInformationToDeviceInformation(XMLDeviceInformation, DeviceInformation);
end;

function PrepareGetDeviceInformationRequest(const UserName, Password: string): string;
begin
  Result := ONVIF.Services.PrepareGetDeviceInformationRequest(UserName, Password);
end;

function ONVIFGetProfiles(const Addr, UserName, Password: string): string;
begin
  Result := ONVIF.Services.ONVIFGetProfiles(Addr, UserName, Password);
end;

function XMLProfilesToProfiles(const XMLProfiles: string; var Profiles: TProfiles): Boolean;
begin
  Result := ONVIF.Services.XMLProfilesToProfiles(XMLProfiles, Profiles);
end;

function PrepareGetProfilesRequest(const UserName, Password: string): string;
begin
  Result := ONVIF.Services.PrepareGetProfilesRequest(UserName, Password);
end;

function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol,
  ProfileToken: string): string;
begin
  Result := ONVIF.Services.ONVIFGetStreamUri(Addr, UserName, Password, Stream, Protocol, ProfileToken);
end;

function XMLStreamUriToStreamUri(const XMLStreamUri: string; var StreamUri: TStreamUri): Boolean;
begin
  Result := ONVIF.Services.XMLStreamUriToStreamUri(XMLStreamUri, StreamUri);
end;

function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol,
  ProfileToken: string): string;
begin
  Result := ONVIF.Services.PrepareGetStreamUriRequest(UserName, Password, Stream, Protocol, ProfileToken);
end;

function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
begin
  Result := ONVIF.Services.ONVIFGetSnapshotUri(Addr, UserName, Password, ProfileToken);
end;

function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: string;
  var SnapshotUri: TSnapshotUri): Boolean;
begin
  Result := ONVIF.Services.XMLSnapshotUriToSnapshotUri(XMLSnapshotUri, SnapshotUri);
end;

function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := ONVIF.Services.PrepareGetSnapshotUriRequest(UserName, Password, ProfileToken);
end;

function GetSnapshot(const SnapshotUri: string; const Stream: TStream): Boolean;
begin
  Result := ONVIF.Core.GetSnapshot(SnapshotUri, Stream);
end;

function GetSnapshot(const SnapshotUri, UserName, Password: string;
  const Stream: TStream; out ContentType: string): Boolean;
begin
  Result := ONVIF.Core.GetSnapshot(SnapshotUri, UserName, Password, Stream, ContentType);
end;

procedure ONVIFRequest(const Addr: string; const InStream, OutStream: TStringStream);
begin
  ONVIF.Core.ONVIFRequest(Addr, InStream, OutStream);
end;

procedure ONVIFRequest(const Addr, Request: string; var Answer: string);
begin
  ONVIF.Core.ONVIFRequest(Addr, Request, Answer);
end;

procedure GetONVIFPasswordDigest(const UserName, Password: string;
  var PasswordDigest, Nonce, Created: string);
begin
  ONVIF.Core.GetONVIFPasswordDigest(UserName, Password, PasswordDigest, Nonce, Created);
end;

function GetONVIFDateTime(const DateTime: TDateTime): string;
begin
  Result := ONVIF.Core.GetONVIFDateTime(DateTime);
end;

function BytesToString(Data: TBytes): string;
begin
  Result := ONVIF.Core.BytesToString(Data);
end;

function StringToBytes(const AData: string): TBytes;
begin
  Result := ONVIF.Core.StringToBytes(AData);
end;

function SHA1(const Data: TBytes): TBytes;
begin
  Result := ONVIF.Core.SHA1(Data);
end;

function GetONVIFAddr(const XAddr: string; const ONVIFAddrType: TONVIFAddrType): string;
begin
  Result := ONVIF.Core.GetONVIFAddr(XAddr, ONVIFAddrType);
end;

function GetIPFromHost(var IPaddr: string): Boolean;
begin
  Result := ONVIF.Platform.GetIPFromHost(IPaddr);
end;

function ParseSoapFault(const AXml: string): TONVIFSoapFault;
begin
  Result := ONVIF.Core.ParseSoapFault(AXml);
end;

function ExecuteSoapRequest(const Addr, EnvelopeNs, BodyXml, UserName, Password: string): TONVIFRequestResult;
begin
  Result := ONVIF.Core.ExecuteSoapRequest(Addr, EnvelopeNs, BodyXml, UserName, Password);
end;

function XMLToProbeMatches(const ProbeMatchXML: string): TProbeMatchArray;
begin
  Result := ONVIF.Core.XMLToProbeMatches(ProbeMatchXML);
end;

function DiscoverCapabilities(const DeviceXAddr, UserName, Password: string): TONVIFCapabilities;
begin
  Result := ONVIF.Device.DiscoverCapabilities(DeviceXAddr, UserName, Password);
end;

{$IFDEF ANDROID}
function GetWiFiManager: JWifiManager;
begin
  Result := ONVIF.Platform.GetWiFiManager;
end;
{$ENDIF ANDROID}

procedure Register;
begin
  RegisterComponents('ONVIF', [TONVIFProbe]);
end;

end.
