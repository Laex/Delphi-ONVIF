unit ONVIF.Types;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Messaging;

type
  TLogMessage = class(TMessage)
  private
    FMsg: string;
  public
    constructor Create(const AMsg: string); reintroduce;
    property Msg: string read FMsg;
  end;

  TProbeType = (ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay);
  TProbeTypeSet = set of TProbeType;

  TONVIFProbeMode = (pmMulticast, pmUnicast, pmSubnet);

  TONVIFSubnetProbeOptions = record
    NetworkAddress: string;
    PrefixLength: Byte;
    FirstHost: Byte;
    LastHost: Byte;
  end;

  TBindToAllAvailableLocalIPsType = (ptBindToAllAvailableLocalIPs);
  TBindToAllAvailableLocalIPsTypeSet = set of TBindToAllAvailableLocalIPsType;

  TProbeMatchXMLArray = TArray<string>;

  TProbeMatch = record
    Types: TProbeTypeSet;
    Scopes: TArray<string>;
    XAddrs: string;
    XAddrsV6: string;
    MetadataVersion: Integer;
    XML: string;
  end;

  TProbeMatchArray = TArray<TProbeMatch>;

  TProbeMatchNotify = procedure(const ProbeMatch: TProbeMatch) of object;
  TProbeMatchXMLNotify = procedure(const ProbeMatchXML: string) of object;
  TLogMessageNotify = procedure(const Msg: string) of object;

  TDeviceInformation = record
    Manufacturer: string;
    Model: string;
    FirmwareVersion: string;
    SerialNumber: string;
    HardwareId: string;
  end;

  TSimpleItem = record
    Name: string;
    Value: string;
  end;

  TRealPoint = record
    x: Real;
    y: Real;
  end;

  TElementItemXY = TRealPoint;

  TElementItemLayout = record
    Columns: Integer;
    Rows: Integer;
    Translate: TElementItemXY;
    Scale: TElementItemXY;
  end;

  TPolygon = TRealPoint;
  TElementItemField = TArray<TPolygon>;

  TElementItemTransform = record
    Translate: TElementItemXY;
    Scale: TElementItemXY;
  end;

  TElementItem = record
    Name: string;
    Layout: TElementItemLayout;
    Field: TElementItemField;
    Transform: TElementItemTransform;
  end;

  TAnalyticsModule = record
    Type_: string;
    Name: string;
    SimpleItem: TArray<TSimpleItem>;
    ElementItem: TArray<TElementItem>;
  end;

  TRule = TAnalyticsModule;

  TMulticastAddress = record
    Type_: string;
    IPv4Address: string;
  end;

  TMulticastConfiguration = record
    Address: TMulticastAddress;
    Port: Word;
    TTL: Integer;
    AutoStart: Boolean;
  end;

  TMetadataConfiguration = record
    token: string;
    Name: string;
    UseCount: Integer;
    Analytics: Boolean;
    Multicast: TMulticastConfiguration;
    SessionTimeout: string;
  end;

  TProfile = record
    fixed: Boolean;
    token: string;
    Name: string;

    VideoSourceConfiguration: record
      token: string;
      Name: string;
      UseCount: Integer;
      SourceToken: string;
      Bounds: record
        x: Integer;
        y: Integer;
        width: Integer;
        height: Integer;
      end;
    end;

    VideoEncoderConfiguration: record
      token: string;
      Name: string;
      UseCount: Integer;
      Encoding: string;
      Resolution: record
        width: Integer;
        height: Integer;
      end;
      Quality: Double;
      RateControl: record
        FrameRateLimit: Integer;
        EncodingInterval: Integer;
        BitrateLimit: Integer;
      end;
      H264: record
        GovLength: Integer;
        H264Profile: string;
      end;
      Multicast: TMulticastConfiguration;
      SessionTimeout: string;
    end;

    AudioEncoderConfiguration: record
      token: string;
      Name: string;
      UseCount: Integer;
      Encoding: string;
      Bitrate: Integer;
      SampleRate: Integer;
      Multicast: TMulticastConfiguration;
      SessionTimeout: string;
    end;

    VideoAnalyticsConfiguration: record
      token: string;
      Name: string;
      UseCount: Integer;
      AnalyticsEngineConfiguration: TArray<TAnalyticsModule>;
      RuleEngineConfiguration: TArray<TRule>;
    end;

    PTZConfiguration: record
      token: string;
      Name: string;
      UseCount: Integer;
      NodeToken: string;
      DefaultContinuousPanTiltVelocitySpace: string;
      DefaultContinuousZoomVelocitySpace: string;
      DefaultPTZTimeout: string;
    end;

    MetadataConfiguration: TMetadataConfiguration;

    Extension: record
      AudioOutputConfiguration: record
        token: string;
        Name: string;
        UseCount: Integer;
        OutputToken: string;
        SendPrimacy: string;
        OutputLevel: Integer;
      end;
      AudioDecoderConfiguration: record
        token: string;
        Name: string;
        UseCount: Integer;
      end;
    end;
  end;

  TProfiles = TArray<TProfile>;

  TStreamUri = record
    Uri: string;
    InvalidAfterConnect: Boolean;
    InvalidAfterReboot: Boolean;
    Timeout: string;
  end;

  TSnapshotUri = TStreamUri;

  TONVIFAddrType = (atDeviceService, atMedia);

  TONVIFServiceType = (
    stDevice, stMedia, stMedia2, stPTZ, stImaging, stEvents, stAnalytics,
    stRecording, stSearch, stReplay, stDeviceIO, stUnknown);

  TONVIFMediaApiKind = (makMedia10, makMedia20);

  TONVIFServiceEndpoint = record
    ServiceType: TONVIFServiceType;
    Namespace: string;
    XAddr: string;
    MajorVersion: Integer;
    MinorVersion: Integer;
  end;

  TONVIFServiceEndpoints = TArray<TONVIFServiceEndpoint>;

  TONVIFSoapFault = record
  public
    Code: string;
    Subcode: string;
    Reason: string;
    Detail: string;
    function HasFault: Boolean;
  end;

  TONVIFRequestResult = record
  public
    Success: Boolean;
    HttpCode: Integer;
    RawXml: string;
    BodyXml: string;
    Fault: TONVIFSoapFault;
    function ErrorMessage: string;
  end;

  TONVIFCapabilities = record
    DeviceXAddr: string;
    Services: TONVIFServiceEndpoints;
    function FindEndpoint(AServiceType: TONVIFServiceType): string;
    function HasService(AServiceType: TONVIFServiceType): Boolean;
  end;

  TONVIFDateTime = record
    DateTimeType: string;
    DaylightSavings: Boolean;
    TimeZone: string;
    UTCDateTime: TDateTime;
  end;

  TONVIFHostnameInformation = record
    FromDHCP: Boolean;
    Name: string;
  end;

  TONVIFDNSInformation = record
    FromDHCP: Boolean;
    DNSManual: TArray<string>;
  end;

  TONVIFUser = record
    Username: string;
    UserLevel: string;
    Password: string;
  end;

  TONVIFUsers = TArray<TONVIFUser>;

  TONVIFNetworkInterface = record
    token: string;
    Enabled: Boolean;
    IPv4Address: string;
    IPv4PrefixLength: Integer;
    FromDHCP: Boolean;
  end;

  TONVIFNetworkInterfaces = TArray<TONVIFNetworkInterface>;

  TONVIFScope = record
    ScopeDef: string;
    ScopeItem: string;
  end;

  TONVIFScopes = TArray<TONVIFScope>;

  TVideoSource = record
    token: string;
    Framerate: Real;
    ResolutionWidth: Integer;
    ResolutionHeight: Integer;
  end;

  TVideoSources = TArray<TVideoSource>;

  TPTZVector = record
    Pan: Real;
    Tilt: Real;
    Zoom: Real;
  end;

  TPTZStatus = record
    Position: TPTZVector;
    MoveStatus: string;
    Error: string;
    UtcTime: TDateTime;
  end;

  TPTZPreset = record
    token: string;
    Name: string;
  end;

  TPTZPresets = TArray<TPTZPreset>;

  TPTZConfiguration = record
    token: string;
    Name: string;
    NodeToken: string;
  end;

  TPTZConfigurations = TArray<TPTZConfiguration>;

  TImagingSettings = record
    Brightness: Real;
    ColorSaturation: Real;
    Contrast: Real;
    Sharpness: Real;
  end;

  TImagingOptions = record
    BrightnessMin, BrightnessMax: Real;
    ContrastMin, ContrastMax: Real;
    SharpnessMin, SharpnessMax: Real;
    ColorSaturationMin, ColorSaturationMax: Real;
  end;

  TONVIFEventProperty = record
    Name: string;
    Source: Boolean;
    IsProperty: Boolean;
  end;

  TONVIFEventProperties = TArray<TONVIFEventProperty>;

  TONVIFSubscription = record
    Reference: string;
    CurrentTime: TDateTime;
    TerminationTime: TDateTime;
  end;

  TONVIFEventMessage = record
    Topic: string;
    Source: string;
    Data: string;
    UtcTime: TDateTime;
    PropertyOperation: string;
  end;

  TONVIFEventMessages = TArray<TONVIFEventMessage>;

  TONVIFRecording = record
    token: string;
    Configuration: string;
    Tracks: TArray<string>;
  end;

  TONVIFRecordings = TArray<TONVIFRecording>;

  TONVIFRecordingSummary = record
    DataFrom: TDateTime;
    DataUntil: TDateTime;
    NumberRecordings: Integer;
  end;

  TONVIFRecordingSearchResult = record
    RecordingToken: string;
    TrackToken: string;
    TimeSpanStart: TDateTime;
    TimeSpanEnd: TDateTime;
  end;

  TONVIFRecordingSearchResults = TArray<TONVIFRecordingSearchResult>;

  TVMSAlarmEvent = record
    CameraId: string;
    Topic: string;
    Timestamp: TDateTime;
    Payload: string;
    Source: string;
  end;

  TVMSCameraEntry = record
    Id: string;
    XAddr: string;
    UserName: string;
    Password: string;
    Manufacturer: string;
    Model: string;
    LastSeen: TDateTime;
    Online: Boolean;
    Capabilities: TONVIFCapabilities;
  end;

  TVMSCameraEntries = TArray<TVMSCameraEntry>;

  TIPv4 = record
    a, b, c, d: Byte;
  end;

  TProbeMathNotify = TProbeMatchNotify;
  TProbeMathXMLNotify = TProbeMatchXMLNotify;

implementation

constructor TLogMessage.Create(const AMsg: string);
begin
  inherited Create;
  FMsg := AMsg;
end;

function TONVIFSoapFault.HasFault: Boolean;
begin
  Result := (Code <> '') or (Reason <> '');
end;

function TONVIFRequestResult.ErrorMessage: string;
begin
  if Fault.HasFault then
    Result := Fault.Reason
  else if not Success then
    Result := Format('HTTP %d', [HttpCode])
  else
    Result := '';
end;

function TONVIFCapabilities.FindEndpoint(AServiceType: TONVIFServiceType): string;
var
  S: TONVIFServiceEndpoint;
begin
  Result := '';
  for S in Services do
    if S.ServiceType = AServiceType then
      Exit(S.XAddr);
end;

function TONVIFCapabilities.HasService(AServiceType: TONVIFServiceType): Boolean;
begin
  Result := FindEndpoint(AServiceType) <> '';
end;

end.
