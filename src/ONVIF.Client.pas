unit ONVIF.Client;

interface

uses
  System.SysUtils,
  ONVIF.Types;

type
  TONVIFDevice = class
  private
    FDeviceXAddr: string;
    FUserName: string;
    FPassword: string;
    FCapabilities: TONVIFCapabilities;
    FMediaApi: TONVIFMediaApiKind;
    FDeviceInfo: TDeviceInformation;
    FProfiles: TProfiles;
    FConnected: Boolean;
    function GetMediaEndpoint: string;
    function GetPTZEndpoint: string;
    function GetImagingEndpoint: string;
    function GetEventsEndpoint: string;
    function GetAnalyticsEndpoint: string;
    function GetRecordingEndpoint: string;
    function GetSearchEndpoint: string;
    function GetReplayEndpoint: string;
    procedure LoadProfiles;
  public
    constructor Create;
    destructor Destroy; override;
    function Connect(const XAddr, UserName, Password: string): Boolean;
    procedure Disconnect;
    property Connected: Boolean read FConnected;
    property DeviceXAddr: string read FDeviceXAddr;
    property UserName: string read FUserName;
    property Password: string read FPassword;
    property Capabilities: TONVIFCapabilities read FCapabilities;
    property MediaApi: TONVIFMediaApiKind read FMediaApi;
    property DeviceInfo: TDeviceInformation read FDeviceInfo;
    property Profiles: TProfiles read FProfiles;
    property MediaEndpoint: string read GetMediaEndpoint;
    property PTZEndpoint: string read GetPTZEndpoint;
    property ImagingEndpoint: string read GetImagingEndpoint;
    property EventsEndpoint: string read GetEventsEndpoint;
    property AnalyticsEndpoint: string read GetAnalyticsEndpoint;
    property RecordingEndpoint: string read GetRecordingEndpoint;
    property SearchEndpoint: string read GetSearchEndpoint;
    property ReplayEndpoint: string read GetReplayEndpoint;
    function GetStreamUri(const ProfileToken, Stream, Protocol: string;
      UseTunnel: Boolean = False): TStreamUri;
    function GetSnapshotUri(const ProfileToken: string): TSnapshotUri;
    function PTZContinuousMove(const ProfileToken: string; const Velocity: TPTZVector): Boolean;
    function PTZStop(const ProfileToken: string): Boolean;
    function GetImagingSettings(const VideoSourceToken: string): TImagingSettings;
    function SetImagingSettings(const VideoSourceToken: string;
      const Settings: TImagingSettings): Boolean;
    function CreateEventSubscription(out Subscription: TONVIFSubscription): Boolean;
    function PullEvents(const SubscriptionAddr: string; out Messages: TONVIFEventMessages): Boolean;
    function HealthCheck: Boolean;
  end;

implementation

uses
  ONVIF.Device,
  ONVIF.Media,
  ONVIF.Media2,
  ONVIF.PTZ,
  ONVIF.Imaging,
  ONVIF.Events,
  ONVIF.Core;

constructor TONVIFDevice.Create;
begin
  inherited;
  FMediaApi := makMedia10;
end;

destructor TONVIFDevice.Destroy;
begin
  inherited;
end;

function TONVIFDevice.Connect(const XAddr, UserName, Password: string): Boolean;
var
  Xml: string;
begin
  Disconnect;
  FDeviceXAddr := NormalizeDeviceXAddr(XAddr);
  if FDeviceXAddr = '' then
    Exit(False);
  FUserName := UserName;
  FPassword := Password;
  FCapabilities := DiscoverCapabilities(FDeviceXAddr, UserName, Password);
  if Length(FCapabilities.Services) = 0 then
    Exit(False);
  Xml := ONVIFGetDeviceInformation(FCapabilities.DeviceXAddr, UserName, Password);
  if SoapHasFault(Xml) or not XMLDeviceInformationToDeviceInformation(Xml, FDeviceInfo) then
    Exit(False);
  if FCapabilities.HasService(stMedia2) and
     Media2GetProfilesWorks(FCapabilities.FindEndpoint(stMedia2), UserName, Password) then
    FMediaApi := makMedia20
  else
    FMediaApi := makMedia10;
  LoadProfiles;
  FConnected := True;
  Result := True;
end;

procedure TONVIFDevice.Disconnect;
begin
  FConnected := False;
  FDeviceXAddr := '';
  FUserName := '';
  FPassword := '';
  FCapabilities := default(TONVIFCapabilities);
  FDeviceInfo := default(TDeviceInformation);
  SetLength(FProfiles, 0);
end;

procedure TONVIFDevice.LoadProfiles;
var
  Xml: string;
  Addr: string;
begin
  SetLength(FProfiles, 0);
  if FMediaApi = makMedia20 then
  begin
    Addr := FCapabilities.FindEndpoint(stMedia2);
    if Addr = '' then
      Exit;
    Xml := ONVIFMedia2GetProfiles(Addr, FUserName, FPassword);
    XMLMedia2ProfilesToProfiles(Xml, FProfiles);
  end
  else
  begin
    Addr := GetMediaEndpoint;
    if Addr = '' then
      Exit;
    Xml := ONVIFGetProfiles(Addr, FUserName, FPassword);
    XMLProfilesToProfiles(Xml, FProfiles);
  end;
end;

function TONVIFDevice.GetMediaEndpoint: string;
begin
  if FMediaApi = makMedia20 then
    Result := FCapabilities.FindEndpoint(stMedia2)
  else
    Result := FCapabilities.FindEndpoint(stMedia);
  if Result = '' then
    Result := FCapabilities.FindEndpoint(stMedia);
end;

function TONVIFDevice.GetPTZEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stPTZ);
end;

function TONVIFDevice.GetImagingEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stImaging);
end;

function TONVIFDevice.GetEventsEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stEvents);
end;

function TONVIFDevice.GetAnalyticsEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stAnalytics);
end;

function TONVIFDevice.GetRecordingEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stRecording);
end;

function TONVIFDevice.GetSearchEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stSearch);
end;

function TONVIFDevice.GetReplayEndpoint: string;
begin
  Result := FCapabilities.FindEndpoint(stReplay);
end;

function TONVIFDevice.GetStreamUri(const ProfileToken, Stream, Protocol: string;
  UseTunnel: Boolean): TStreamUri;
var
  Xml: string;
begin
  Result := default(TStreamUri);
  if FMediaApi = makMedia20 then
  begin
    Xml := ONVIFMedia2GetStreamUri(GetMediaEndpoint, FUserName, FPassword, Protocol, ProfileToken);
    XMLMedia2StreamUriToStreamUri(Xml, Result);
  end
  else
  begin
    Xml := ONVIFGetStreamUri(GetMediaEndpoint, FUserName, FPassword, Stream, Protocol,
      ProfileToken, UseTunnel);
    XMLStreamUriToStreamUri(Xml, Result);
  end;
end;

function TONVIFDevice.GetSnapshotUri(const ProfileToken: string): TSnapshotUri;
var
  Xml: string;
begin
  Result := default(TSnapshotUri);
  if FMediaApi = makMedia20 then
  begin
    Xml := ONVIFMedia2GetSnapshotUri(GetMediaEndpoint, FUserName, FPassword, ProfileToken);
    XMLMedia2SnapshotUriToSnapshotUri(Xml, Result);
  end
  else
  begin
    Xml := ONVIFGetSnapshotUri(GetMediaEndpoint, FUserName, FPassword, ProfileToken);
    XMLSnapshotUriToSnapshotUri(Xml, Result);
  end;
end;

function TONVIFDevice.PTZContinuousMove(const ProfileToken: string;
  const Velocity: TPTZVector): Boolean;
begin
  Result := ONVIFPTZContinuousMove(GetPTZEndpoint, FUserName, FPassword, ProfileToken,
    Velocity).Success;
end;

function TONVIFDevice.PTZStop(const ProfileToken: string): Boolean;
begin
  Result := ONVIFPTZStop(GetPTZEndpoint, FUserName, FPassword, ProfileToken).Success;
end;

function TONVIFDevice.GetImagingSettings(const VideoSourceToken: string): TImagingSettings;
var
  Xml: string;
begin
  Result := default(TImagingSettings);
  Xml := ONVIFGetImagingSettings(GetImagingEndpoint, FUserName, FPassword, VideoSourceToken);
  XMLImagingSettingsToSettings(Xml, Result);
end;

function TONVIFDevice.SetImagingSettings(const VideoSourceToken: string;
  const Settings: TImagingSettings): Boolean;
begin
  Result := ONVIFSetImagingSettings(GetImagingEndpoint, FUserName, FPassword, VideoSourceToken,
    Settings).Success;
end;

function TONVIFDevice.CreateEventSubscription(out Subscription: TONVIFSubscription): Boolean;
var
  Xml: string;
begin
  Subscription := default(TONVIFSubscription);
  if GetEventsEndpoint = '' then
    Exit(False);
  Xml := ONVIFCreatePullPointSubscription(GetEventsEndpoint, FUserName, FPassword);
  if SoapHasFault(Xml) then
    Exit(False);
  Result := XMLPullPointSubscriptionToSubscription(Xml, Subscription);
end;

function TONVIFDevice.PullEvents(const SubscriptionAddr: string;
  out Messages: TONVIFEventMessages): Boolean;
var
  Xml: string;
begin
  SetLength(Messages, 0);
  if SubscriptionAddr = '' then
    Exit(False);
  Xml := ONVIFPullMessages(SubscriptionAddr, FUserName, FPassword);
  if SoapHasFault(Xml) then
    Exit(False);
  Result := XMLPullMessagesToMessages(Xml, Messages);
end;

function TONVIFDevice.HealthCheck: Boolean;
var
  Xml: string;
  Info: TDeviceInformation;
begin
  if not FConnected then
    Exit(False);
  Xml := ONVIFGetDeviceInformation(FCapabilities.DeviceXAddr, FUserName, FPassword);
  Result := XMLDeviceInformationToDeviceInformation(Xml, Info) and not SoapHasFault(Xml);
end;

end.
