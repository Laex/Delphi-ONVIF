unit ONVIF;

interface

Uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Messaging,
  IdUDPServer,
  IdGlobal,
  IdSocketHandle,
  FMX.Dialogs
{$IFDEF MSWINDOWS}
    , Winsock
{$ENDIF MSWINDOWS}
{$IFDEF ANDROID}
    , Androidapi.Helpers, Androidapi.JNIBridge, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes, Androidapi.JNI, Androidapi.JNI.Net;
{$ELSE}
    ;
{$ENDIF ANDROID}

Type

  TLogMessage = class(TMessage)
  private
    msg: String;
  public
    constructor Create(msg: String); reintroduce;
  end;

  TProbeType = (ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay);
  TProbeTypeSet = set of TProbeType;

  TBindToAllAvailableLocalIPsType = (ptBindToAllAvailableLocalIPs);
  TBindToAllAvailableLocalIPsTypeSet = set of TBindToAllAvailableLocalIPsType;

  TProbeMatchXMLArray = TArray<string>;

  TProbeMatch = record
    Types: TProbeTypeSet;
    Scopes: TArray<string>;
    XAddrs: String;
    XAddrsV6: string;
    MetadataVersion: Integer;
    XML: String;
  end;

  TProbeMatchArray = TArray<TProbeMatch>;

  TProbeMathNotify = procedure(const ProbeMatch: TProbeMatch) of object;
  TProbeMathXMLNotify = procedure(const ProbeMatchXML: String) of object;
  TLogMessageNotify = procedure(const msg: String) of object;

  TONVIFProbeThread = class;

  TONVIFProbe = class(TComponent)
  private
    FONVIFProbeThread: TONVIFProbeThread;
    FOnProbeMathXML: TProbeMathXMLNotify;
    FOnCompleted: TNotifyEvent;
    FOnProbeMath: TProbeMathNotify;
    FProbeType: TProbeTypeSet;
    FBindToAllAvailableLocalIPsType: TBindToAllAvailableLocalIPsTypeSet;
    FTimeout: Cardinal;
    MessageListener: TMessageListenerMethod;
    FOnLogMessage: TLogMessageNotify;
    function GetCount: Integer;
    function GetProbeMatch(const Index: Integer): TProbeMatch;
    function GetProbeMatchXML(const Index: Integer): String;
    function GetProbeMatchArray: TProbeMatchArray;
    procedure ProcessMessage(const Sender: TObject; const M: TMessage);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute: Boolean;
    function ExecuteAsync: Boolean;
    property Count: Integer read GetCount;
    property ProbeMatchXML[const Index: Integer]: String Read GetProbeMatchXML;
    property ProbeMatch[const Index: Integer]: TProbeMatch Read GetProbeMatch;
    property ProbeMatchArray: TProbeMatchArray read GetProbeMatchArray;
  published
    property OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
    property OnProbeMath: TProbeMathNotify read FOnProbeMath write FOnProbeMath;
    property OnProbeMathXML: TProbeMathXMLNotify read FOnProbeMathXML write FOnProbeMathXML;
    property ProbeType: TProbeTypeSet read FProbeType write FProbeType default [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay];
    property Timeout: Cardinal read FTimeout write FTimeout default 1000;
    property OnLogMessage: TLogMessageNotify read FOnLogMessage write FOnLogMessage;
    property BindToAllAvailableLocalIPsType: TBindToAllAvailableLocalIPsTypeSet read FBindToAllAvailableLocalIPsType write FBindToAllAvailableLocalIPsType
      default [ptBindToAllAvailableLocalIPs];
  end;

  TONVIFProbeThread = class(TThread)
  private
    // E: TEvent;
    FProbeMatchXML: TProbeMatchXMLArray;
    FProbeTypeSet: TProbeTypeSet;
    FBindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet;
    FTimeout: Cardinal;
    FUDPCounter: Int64;
    FProbeMatch: TProbeMatchArray;
    FProbeMathNotify: TProbeMathNotify;
    FProbeMathXMLNotify: TProbeMathXMLNotify;
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
  protected
    procedure Execute; override;
  public
    constructor Create(const ProbeMathNotify: TProbeMathNotify = nil; const ProbeMathXMLNotify: TProbeMathXMLNotify = nil;
      const ProbeTypeSet: TProbeTypeSet = [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay];
      const BindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet = [ptBindToAllAvailableLocalIPs]; const Timeout: Cardinal = 1000);
    property ProbeMatchXML: TProbeMatchXMLArray read FProbeMatchXML;
    property ProbeMatch: TProbeMatchArray read FProbeMatch;
  end;

  TSendMessageThread = class(TThread)
  protected
    procedure Execute; override;
  private
    msg: TMessage;
  public
    constructor Create(msg: TMessage); reintroduce;
  end;

type
  TIPv4 = record
    a, b, c, d: byte;
  end;

function ONVIFProbe: TProbeMatchArray;
function XMLToProbeMatch(const ProbeMatchXML: string; Var ProbeMatch: TProbeMatch): Boolean;
function UniqueProbeMatch(const ProbeMatch: TProbeMatchArray): TProbeMatchArray;

Type
  TDeviceInformation = record
    Manufacturer: string;
    Model: string;
    FirmwareVersion: String;
    SerialNumber: String;
    HardwareId: String;
  end;

  // Addr -> http://<host>/onvif/device_service
function ONVIFGetDeviceInformation(const Addr, UserName, Password: String): String;
function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: String; Var DeviceInformation: TDeviceInformation): Boolean;
function PrepareGetDeviceInformationRequest(const UserName, Password: String): String;

Type

  TSimpleItem = record
    Name: String;
    Value: String;
  end;

  TPoint = record
    x: Real;
    y: Real;
  end;

  TElementItemXY = TPoint;

  TElementItemLayout = record
    Columns: Integer;
    Rows: Integer;
    Translate: TElementItemXY;
    Scale: TElementItemXY;
  end;

  TPolygon = TPoint;

  TElementItemField = TArray<TPolygon>;

  TElementItemTransform = record
    Translate: TElementItemXY;
    Scale: TElementItemXY;
  end;

  TElementItem = record
    Name: String;
    Layout: TElementItemLayout;
    Field: TElementItemField;
    Transform: TElementItemTransform;
  end;

  TAnalyticsModule = record
    Type_: String;
    Name: String;
    SimpleItem: TArray<TSimpleItem>;
    ElementItem: TArray<TElementItem>;
  end;

  TRule = TAnalyticsModule;

  TProfile = record
    fixed: Boolean;
    token: string;
    Name: String;

    VideoSourceConfiguration: record
{$REGION 'VideoSourceConfiguration'}
      token: string;
      Name: String;
      UseCount: Integer;
      SourceToken: string;

      Bounds: record
        x: Integer;
        y: Integer;
        width: Integer;
        height: Integer;
      end;
{$ENDREGION}
    end;

    VideoEncoderConfiguration: record
{$REGION 'VideoEncoderConfiguration'}
      token: String;
      Name: String;
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
        H264Profile: String;
      end;

      Multicast: record
        Address: record
          Type_: String;
          IPv4Address: String;
        end;

        Port: Word;
        TTL: Integer;
        AutoStart: Boolean;
      end;

      SessionTimeout: String;
{$ENDREGION}
    end;

    AudioEncoderConfiguration: record
{$REGION 'AudioEncoderConfiguration'}
      token: string;
      Name: string;
      UseCount: Integer;
      Encoding: string;
      Bitrate: Integer;
      SampleRate: Integer;

      Multicast: record
        Address: record
          Type_: string;
          IPv4Address: string;
        end;

        Port: Word;
        TTL: Integer;
        AutoStart: Boolean;
      end;

      SessionTimeout: String;
{$ENDREGION}
    end;

    VideoAnalyticsConfiguration: record
      token: String;
      Name: string;
      UseCount: Integer;
      AnalyticsEngineConfiguration: TArray<TAnalyticsModule>;
      RuleEngineConfiguration: TArray<TRule>;
    end;

    PTZConfiguration: record
      token: String;
      Name: string;
      UseCount: Integer;
      NodeToken: String;
      DefaultContinuousPanTiltVelocitySpace: string;
      DefaultContinuousZoomVelocitySpace: string;
      DefaultPTZTimeout: String;
    end;

    Extension: record
      AudioOutputConfiguration: record
        token: String;
        Name: String;
        UseCount: Integer;
        OutputToken: String;
        SendPrimacy: string;
        OutputLevel: Integer;
      end;

      AudioDecoderConfiguration: record
        token: string;
        Name: String;
        UseCount: Integer;
      end;
    end;
  end;

  TProfiles = TArray<TProfile>;

  // Addr -> http://<host>/onvif/Media
function ONVIFGetProfiles(const Addr, UserName, Password: String): String;
function XMLProfilesToProfiles(const XMLProfiles: String; Var Profiles: TProfiles): Boolean;
function PrepareGetProfilesRequest(const UserName, Password: String): String;

type
  TStreamUri = record
    Uri: string;
    InvalidAfterConnect: Boolean;
    InvalidAfterReboot: Boolean;
    Timeout: String;
  end;

  // Protocol -> HTTP or RTSP
  // Addr -> http://<host>/onvif/Media
function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol, ProfileToken: String): String;
function XMLStreamUriToStreamUri(const XMLStreamUri: String; Var StreamUri: TStreamUri): Boolean;
function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol, ProfileToken: String): String;

type

  TSnapshotUri = record
    Uri: String;
    InvalidAfterConnect: Boolean;
    InvalidAfterReboot: Boolean;
    Timeout: String;
  end;

  // Addr -> http://<host>/onvif/Media
function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: String): String;
function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: String; Var SnapshotUri: TSnapshotUri): Boolean;
function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: String): String;
function GetSnapshot(const SnapshotUri: String; const Stream: TStream): Boolean;
//
// ------------------------
//
procedure ONVIFRequest(const Addr: String; const InStream, OutStream: TStringStream); overload;
procedure ONVIFRequest(const Addr, Request: String; Var Answer: String); overload;
//
// ------------------------
//
procedure GetONVIFPasswordDigest(const UserName, Password: String; Var PasswordDigest, Nonce, Created: String);
function GetONVIFDateTime(const DateTime: TDateTime): String;
function BytesToString(Data: TBytes): String; inline;
function SHA1(const Data: TBytes): TBytes;

Type
  TONVIFAddrType = (atDeviceService, atMedia);

function GetONVIFAddr(const XAddr: string; const ONVIFAddrType: TONVIFAddrType): string;

function GetIPFromHost(var IPaddr: String): Boolean; // drg 24/12/2017
{$IFDEF ANDROID}
function GetWiFiManager: JWifiManager;
{$ENDIF ANDROID}
procedure Register;

implementation

Uses System.Generics.Defaults, System.Generics.Collections, System.NetEncoding, IdHashSHA, IdHTTP, IdURI, XML.VerySimple; // uNativeXML;

procedure Register;
begin
  RegisterComponents('ONVIF', [TONVIFProbe]);
end;

const
  onvifDeviceService = 'device_service';
  onvifMedia         = 'Media';

function ONVIFProbe: TProbeMatchArray;
Var
  F: TONVIFProbeThread;
begin
  F := TONVIFProbeThread.Create;
  try
    F.WaitFor;
    Result := F.ProbeMatch;
  finally
    F.Free;
  end;
end;

function GetONVIFAddr(const XAddr: string; const ONVIFAddrType: TONVIFAddrType): string;
Var
  Uri: TIdURI;
begin
  Uri := TIdURI.Create(XAddr);
  try
    case ONVIFAddrType of
      atDeviceService:
        Uri.Document := onvifDeviceService;
      atMedia:
        Uri.Document := onvifMedia;
    end;
    Result := Uri.Uri;
  finally
    Uri.Free;
  end;
end;

function BytesToString(Data: TBytes): String; inline;
begin
  SetLength(Result, Length(Data));
  Move(Data[0], Result[1], Length(Data));
end;

procedure ONVIFRequest(const Addr, Request: String; Var Answer: String);
Var
  InStream, OutStream: TStringStream;
begin
  InStream := TStringStream.Create(Request);
  OutStream := TStringStream.Create;
  try
    ONVIFRequest(Addr, InStream, OutStream);
    Answer := OutStream.DataString;
  finally
    InStream.Free;
    OutStream.Free;
  end;
end;

procedure ONVIFRequest(const Addr: String; const InStream, OutStream: TStringStream);
Var
  idhtp1: TIdHTTP;
  Uri: TIdURI;
begin
  idhtp1 := TIdHTTP.Create;
  Uri := TIdURI.Create(Addr);
  try
    With idhtp1 do
    begin
      AllowCookies := True;
      HandleRedirects := True;
      Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
      Request.UserAgent := 'Mozilla/3.0 (compatible; Indy Library)';
      Request.Host := '';
      Request.Connection := '';
      Request.Accept := '';
      Request.UserAgent := '';

      Request.CustomHeaders.Clear;
      Request.ContentType := 'text/xml;charset=utf-8';
      Request.CustomHeaders.Add('Host: ' + Uri.Host);

      ProtocolVersion := pv1_1;
      HTTPOptions := [hoNoProtocolErrorException, hoWantProtocolErrorContent];
      Post(Addr, InStream, OutStream);
    end;
  finally
    Uri.Free;
    idhtp1.Free;
  end;
end;

function ONVIFGetDeviceInformation(const Addr, UserName, Password: String): String;
begin
  // Addr -> http://<host>/onvif/device_service
  ONVIFRequest(Addr, PrepareGetDeviceInformationRequest(UserName, Password), Result);
end;

function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: String; Var DeviceInformation: TDeviceInformation): Boolean;
var
  SS: TStringStream;
  XmlNode, Node: TXmlNode;
  XML: TXmlVerySimple;
begin
  XML := TXmlVerySimple.Create;
  SS := TStringStream.Create(XMLDeviceInformation);
  DeviceInformation := default (TDeviceInformation);
  Result := False;
  try
    XML.LoadFromStream(SS);

    XmlNode := XML.DocumentElement.Find('Body');
    if Assigned(XmlNode) then
    begin
      XmlNode := XmlNode.Find('GetDeviceInformationResponse');
      if Assigned(XmlNode) then
      begin
        Node := XmlNode.Find('Manufacturer');
        if Assigned(Node) then
        begin
          DeviceInformation.Manufacturer := Node.Text;
          Result := True;
        end;

        Node := XmlNode.Find('Model');
        if Assigned(Node) then
        begin
          DeviceInformation.Model := Node.Text;
          Result := True;
        end;

        Node := XmlNode.Find('FirmwareVersion');
        if Assigned(Node) then
        begin
          DeviceInformation.FirmwareVersion := Node.Text;
          Result := True;
        end;

        Node := XmlNode.Find('SerialNumber');
        if Assigned(Node) then
        begin
          DeviceInformation.SerialNumber := Node.Text;
          Result := True;
        end;

        Node := XmlNode.Find('HardwareId');
        if Assigned(Node) then
        begin
          DeviceInformation.HardwareId := Node.Text;
          Result := True;
        end;

      end;
    end;
  finally
    XML.Free;
    SS.Free;
  end;
end;

function PrepareGetDeviceInformationRequest(const UserName, Password: String): String;
const
  GetDeviceInformationFmt: String =
  // PasswordDigest,Nonce,Created // http://<host>/onvif/device_service
    '<?xml version="1.0"?> ' + //
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:wsdl="http://www.onvif.org/ver10/device/wsdl"> ' + //
    '<soap:Header>' + //
    '<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" s:mustUnderstand="1"> ' + //
    '<UsernameToken> ' +         //
    '<Username>%s</Username> ' + //
    '<Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">%s</Password> ' +
    '<Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">%s</Nonce> ' +
    '<Created xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">%s</Created> ' + //
    '</UsernameToken> ' + //
    '</Security> ' +                  //
    '</soap:Header>' +                //
    '<soap:Body> ' +                  //
    '<wsdl:GetDeviceInformation/> ' + //
    '</soap:Body> ' +                 //
    '</soap:Envelope>';
Var
  PasswordDigest, Nonce, Created: String;
begin
  GetONVIFPasswordDigest(UserName, Password, PasswordDigest, Nonce, Created);
  Result := Format(GetDeviceInformationFmt, [UserName, PasswordDigest, Nonce, Created]);
end;

function ONVIFGetProfiles(const Addr, UserName, Password: String): String;
begin
  // Addr -> http://<host>/onvif/Media
  ONVIFRequest(Addr, PrepareGetProfilesRequest(UserName, Password), Result);
end;

function XMLProfilesToProfiles(const XMLProfiles: String; Var Profiles: TProfiles): Boolean;
var
  SS: TStringStream;
  XmlNode, Node, N, M, K: TXmlNode;
  XML: TXmlVerySimple;
  i, j: Integer;
  Profile: TProfile;
  a: TAnalyticsModule;
begin
  XML := TXmlVerySimple.Create;
  SS := TStringStream.Create(XMLProfiles);
  Result := False;
  try
    XML.LoadFromStream(SS);
    XmlNode := XML.DocumentElement.Find('Body');
    if Assigned(XmlNode) then
    begin
      XmlNode := XmlNode.Find('GetProfilesResponse');
      if Assigned(XmlNode) then
      begin
        Profile := default (TProfile);
        // for i := 0 to XmlNode.ContainerCount - 1 do
        for i := 0 to XmlNode.ChildNodes.Count - 1 do
        begin
          // Node := XmlNode.Containers[i];
          Node := XmlNode.ChildNodes[i];
          if not(string(Node.Attributes['fixed']) = '') then // drg 24/12/2017
            Profile.fixed := string(Node.Attributes['fixed']).ToBoolean;
          Profile.token := string(Node.Attributes['token']);
          N := Node.Find('Name');
          if Assigned(N) then
            Profile.Name := N.Text;
          N := Node.Find('VideoSourceConfiguration');
          if Assigned(N) then
          begin
            Profile.VideoSourceConfiguration.token := string(N.Attributes['token']);
            M := N.Find('Name');
            if Assigned(M) then
              Profile.VideoSourceConfiguration.Name := M.Text;
            M := N.Find('UseCount');
            if Assigned(M) then
              Profile.VideoSourceConfiguration.UseCount := M.Text.ToInteger;
            M := N.Find('SourceToken');
            if Assigned(M) then
              Profile.VideoSourceConfiguration.SourceToken := M.Text;
            M := N.Find('Bounds');
            if Assigned(M) then
            begin
              Profile.VideoSourceConfiguration.Bounds.x := string(M.Attributes['x']).ToInteger;
              Profile.VideoSourceConfiguration.Bounds.y := string(M.Attributes['y']).ToInteger;
              Profile.VideoSourceConfiguration.Bounds.width := string(M.Attributes['width']).ToInteger;
              Profile.VideoSourceConfiguration.Bounds.height := string(M.Attributes['height']).ToInteger;
            end;
          end;
          N := Node.Find('VideoEncoderConfiguration');
          if Assigned(N) then
          begin
            Profile.VideoEncoderConfiguration.token := string(N.Attributes['token']);
            M := N.Find('Name');
            if Assigned(M) then
              Profile.VideoEncoderConfiguration.Name := M.Text;
            M := N.Find('UseCount');
            if Assigned(M) then
              Profile.VideoEncoderConfiguration.UseCount := M.Text.ToInteger;
            M := N.Find('Encoding');
            if Assigned(M) then
              Profile.VideoEncoderConfiguration.Encoding := M.Text;
            M := N.Find('Resolution');
            if Assigned(M) then
            begin
              K := M.Find('Width');
              Profile.VideoEncoderConfiguration.Resolution.width := K.Text.ToInteger;
              K := M.Find('Height');
              Profile.VideoEncoderConfiguration.Resolution.height := K.Text.ToInteger;
            end;
            M := N.Find('Quality');
            if Assigned(M) then
              Profile.VideoEncoderConfiguration.Quality := M.Text.ToDouble;
            M := N.Find('RateControl');
            if Assigned(M) then
            begin
              K := M.Find('FrameRateLimit');
              Profile.VideoEncoderConfiguration.RateControl.FrameRateLimit := K.Text.ToInteger;
              K := M.Find('EncodingInterval');
              Profile.VideoEncoderConfiguration.RateControl.EncodingInterval := K.Text.ToInteger;
              K := M.Find('BitrateLimit');
              Profile.VideoEncoderConfiguration.RateControl.BitrateLimit := K.Text.ToInteger;
            end;
            M := N.Find('H264');
            if Assigned(M) then
            begin
              K := M.Find('GovLength');
              Profile.VideoEncoderConfiguration.H264.GovLength := K.Text.ToInteger;
              K := M.Find('H264Profile');
              Profile.VideoEncoderConfiguration.H264.H264Profile := K.Text;
            end;
            M := N.Find('Multicast');
            if Assigned(M) then
            begin
              K := M.Find('Address');
              Profile.VideoEncoderConfiguration.Multicast.Address.Type_ := K.Find('Type').Text;
              Profile.VideoEncoderConfiguration.Multicast.Address.IPv4Address := K.Find('IPv4Address').Text;
              K := M.Find('Port');
              Profile.VideoEncoderConfiguration.Multicast.Port := K.Text.ToInteger;
              K := M.Find('TTL');
              Profile.VideoEncoderConfiguration.Multicast.TTL := K.Text.ToInteger;
              K := M.Find('AutoStart');
              Profile.VideoEncoderConfiguration.Multicast.AutoStart := K.Text.ToBoolean;
            end;
            M := N.Find('SessionTimeout');
            if Assigned(M) then
              Profile.VideoEncoderConfiguration.SessionTimeout := M.Text;
          end;

          N := Node.Find('VideoAnalyticsConfiguration');
          if Assigned(N) then
          begin
            Profile.VideoAnalyticsConfiguration.token := string(N.Attributes['token']);
            M := N.Find('Name');
            if Assigned(M) then
              Profile.VideoAnalyticsConfiguration.Name := M.Text;
            M := N.Find('UseCount');
            if Assigned(M) then
              Profile.VideoAnalyticsConfiguration.UseCount := M.Text.ToInteger;

            M := N.Find('AnalyticsEngineConfiguration');
            if Assigned(M) then
            begin
              for j := 0 to M.ChildNodes.Count - 1 do
              begin
                K := M.ChildNodes[j];
                a.Type_ := string(K.Attributes['Type']);
                a.Name := string(K.Attributes['Name']);
                /// /////////////
              end;
            end;

          end;

          N := Node.Find('AudioEncoderConfiguration');
          if Assigned(N) then
          begin
            Profile.AudioEncoderConfiguration.token := string(N.Attributes['token']);
            M := N.Find('Name');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.Name := M.Text;
            M := N.Find('UseCount');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.UseCount := M.Text.ToInteger;

            M := N.Find('Encoding');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.Encoding := M.Text;
            M := N.Find('Bitrate');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.Bitrate := M.Text.ToInteger;
            M := N.Find('SampleRate');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.SampleRate := M.Text.ToInteger;
            M := N.Find('Multicast');
            if Assigned(M) then
            begin
              K := M.Find('Address');
              Profile.AudioEncoderConfiguration.Multicast.Address.Type_ := K.Find('Type').Text;
              Profile.AudioEncoderConfiguration.Multicast.Address.IPv4Address := K.Find('IPv4Address').Text;
              K := M.Find('Port');
              if Assigned(K) then
                Profile.AudioEncoderConfiguration.Multicast.Port := K.Text.ToInteger;
              K := M.Find('TTL');
              if Assigned(K) then
                Profile.AudioEncoderConfiguration.Multicast.TTL := K.Text.ToInteger;
              K := M.Find('AutoStart');
              if Assigned(K) then
                Profile.AudioEncoderConfiguration.Multicast.AutoStart := K.Text.ToBoolean;
            end;
            M := N.Find('Multicast');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.SessionTimeout := M.Text;
            M := N.Find('SessionTimeout');
            if Assigned(M) then
              Profile.AudioEncoderConfiguration.SessionTimeout := M.Text;
          end;

          N := Node.Find('PTZConfiguration');
          if Assigned(N) then
          begin
            Profile.PTZConfiguration.token := string(N.Attributes['token']);
            M := N.Find('Name');
            if Assigned(M) then
              Profile.PTZConfiguration.Name := M.Text;
            M := N.Find('UseCount');
            if Assigned(M) then
              Profile.PTZConfiguration.UseCount := M.Text.ToInteger;
            M := N.Find('NodeToken');
            if Assigned(M) then
              Profile.PTZConfiguration.NodeToken := M.Text;
            M := N.Find('DefaultContinuousPanTiltVelocitySpace');
            if Assigned(M) then
              Profile.PTZConfiguration.DefaultContinuousPanTiltVelocitySpace := M.Text;
            M := N.Find('DefaultContinuousZoomVelocitySpace');
            if Assigned(M) then
              Profile.PTZConfiguration.DefaultContinuousZoomVelocitySpace := M.Text;
            M := N.Find('DefaultPTZTimeout');
            if Assigned(M) then
              Profile.PTZConfiguration.DefaultPTZTimeout := M.Text;
          end;

          N := Node.Find('Extension');
          if Assigned(N) then
          begin
            K := N.Find('AudioOutputConfiguration');
            if Assigned(K) then
            begin
              Profile.Extension.AudioOutputConfiguration.token := string(K.Attributes['token']);
              M := K.Find('Name');
              if Assigned(M) then
                Profile.Extension.AudioOutputConfiguration.Name := M.Text;
              M := K.Find('UseCount');
              if Assigned(M) then
                Profile.Extension.AudioOutputConfiguration.UseCount := M.Text.ToInteger;
              M := K.Find('OutputToken');
              if Assigned(M) then
                Profile.Extension.AudioOutputConfiguration.OutputToken := M.Text;
              M := K.Find('SendPrimacy');
              if Assigned(M) then
                Profile.Extension.AudioOutputConfiguration.SendPrimacy := M.Text;
              M := K.Find('OutputLevel');
              if Assigned(M) then
                Profile.Extension.AudioOutputConfiguration.OutputLevel := M.Text.ToInteger;
            end;
            K := N.Find('AudioDecoderConfiguration');
            if Assigned(K) then
            begin
              Profile.Extension.AudioDecoderConfiguration.token := string(K.Attributes['token']);
              M := K.Find('Name');
              if Assigned(M) then
                Profile.Extension.AudioDecoderConfiguration.Name := M.Text;
              M := K.Find('UseCount');
              if Assigned(M) then
                Profile.Extension.AudioDecoderConfiguration.UseCount := M.Text.ToInteger;
            end;
          end;

          SetLength(Profiles, Length(Profiles) + 1);
          Profiles[High(Profiles)] := Profile;
          Result := True;
        end;
      end;
    end;
  finally
    XML.Free;
    SS.Free;
  end;
end;

function PrepareGetProfilesRequest(const UserName, Password: String): String;
const
  GetProfilesFmt: String =
  // PasswordDigest,Nonce,Created // http://<host>/onvif/Media
    '<?xml version="1.0"?> ' + //
    '<soap:Envelope ' +        //
    'xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ' + //
    'xmlns:wsdl="http://www.onvif.org/ver10/media/wsdl">' + //
    '<soap:Header>' + //
    '<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" s:mustUnderstand="1"> ' + //
    '<UsernameToken> ' + //
    '<Username>%s</Username> ' + //
    '<Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">%s</Password> ' +
    '<Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">%s</Nonce> ' +
    '<Created xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">%s</Created> ' + //
    '</UsernameToken> ' + //
    '</Security> ' +   //
    '</soap:Header>' + //
    '<soap:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> ' + //
    '<GetProfiles xmlns="http://www.onvif.org/ver10/media/wsdl" /> ' + //
    '</soap:Body> ' + //
    '</soap:Envelope>';

Var
  PasswordDigest, Nonce, Created: String;
begin
  GetONVIFPasswordDigest(UserName, Password, PasswordDigest, Nonce, Created);
  Result := Format(GetProfilesFmt, [UserName, PasswordDigest, Nonce, Created]);
end;

function XMLStreamUriToStreamUri(const XMLStreamUri: String; Var StreamUri: TStreamUri): Boolean;
var
  SS: TStringStream;
  XmlNode, Node: TXmlNode;
  XML: TXmlVerySimple;
begin
  XML := TXmlVerySimple.Create;
  SS := TStringStream.Create(XMLStreamUri);
  StreamUri := default (TStreamUri);
  Result := False;
  try
    XML.LoadFromStream(SS);
    XmlNode := XML.DocumentElement.Find('Body');
    if Assigned(XmlNode) then
    begin
      XmlNode := XmlNode.Find('GetStreamUriResponse');
      if Assigned(XmlNode) then
      begin
        XmlNode := XmlNode.Find('MediaUri');
        if Assigned(XmlNode) then
        begin
          Node := XmlNode.Find('Uri');
          if Assigned(Node) then
          begin
            StreamUri.Uri := String(Node.Text);
            Result := True;
          end;

          Node := XmlNode.Find('InvalidAfterConnect');
          if Assigned(Node) then
          begin
            StreamUri.InvalidAfterConnect := string(Node.Text).ToBoolean;
            Result := True;
          end;

          Node := XmlNode.Find('InvalidAfterReboot');
          if Assigned(Node) then
          begin
            StreamUri.InvalidAfterReboot := string(Node.Text).ToBoolean;
            Result := True;
          end;

          Node := XmlNode.Find('Timeout');
          if Assigned(Node) then
          begin
            StreamUri.Timeout := Node.Text;
            Result := True;
          end;

        end;
      end;
    end;
  finally
    XML.Free;
    SS.Free;
  end;
end;

function GetSnapshot(const SnapshotUri: String; const Stream: TStream): Boolean;
Var
  idhtp1: TIdHTTP;
  Uri: TIdURI;
begin
  idhtp1 := TIdHTTP.Create;
  Uri := TIdURI.Create(SnapshotUri);
  try
    With idhtp1 do
    begin
      AllowCookies := True;
      HandleRedirects := True;
      Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
      Request.UserAgent := 'Mozilla/3.0 (compatible; Indy Library)';
      Request.Host := '';
      Request.Connection := '';
      Request.Accept := '';
      Request.UserAgent := '';
      Request.CustomHeaders.Clear;
      Request.ContentType := 'text/xml;charset=utf-8';
      Request.CustomHeaders.Add('Host: ' + Uri.Host);
      ProtocolVersion := pv1_1;
      HTTPOptions := [hoNoProtocolErrorException, hoWantProtocolErrorContent];
      Get(SnapshotUri, Stream);
    end;
  finally
    Uri.Free;
    idhtp1.Free;
  end;
end;

function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: String): String;
begin
  // Addr -> http://<host>/onvif/Media
  ONVIFRequest(Addr, PrepareGetSnapshotUriRequest(UserName, Password, ProfileToken), Result);
end;

function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: String; Var SnapshotUri: TSnapshotUri): Boolean;
var
  SS: TStringStream;
  XmlNode, Node: TXmlNode;
  XML: TXmlVerySimple;
begin
  XML := TXmlVerySimple.Create;
  SS := TStringStream.Create(XMLSnapshotUri);
  SnapshotUri := default (TSnapshotUri);
  Result := False;
  try
    XML.LoadFromStream(SS);
    XmlNode := XML.DocumentElement.Find('Body');
    if Assigned(XmlNode) then
    begin
      XmlNode := XmlNode.Find('GetSnapshotUriResponse');
      if Assigned(XmlNode) then
      begin
        XmlNode := XmlNode.Find('MediaUri');
        if Assigned(XmlNode) then
        begin
          Node := XmlNode.Find('Uri');
          if Assigned(Node) then
          begin
            SnapshotUri.Uri := String(Node.Text);
            Result := True;
          end;

          Node := XmlNode.Find('InvalidAfterConnect');
          if Assigned(Node) then
          begin
            SnapshotUri.InvalidAfterConnect := string(Node.Text).ToBoolean;
            Result := True;
          end;

          Node := XmlNode.Find('InvalidAfterReboot');
          if Assigned(Node) then
          begin
            SnapshotUri.InvalidAfterReboot := string(Node.Text).ToBoolean;
            Result := True;
          end;

          Node := XmlNode.Find('Timeout');
          if Assigned(Node) then
          begin
            SnapshotUri.Timeout := Node.Text;
            Result := True;
          end;

        end;
      end;
    end;
  finally
    XML.Free;
    SS.Free;
  end;
end;

function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: String): String;
const
  GetSnapshotUriFmt: String =  // PasswordDigest,Nonce,Created, ProfileToken
    '<?xml version="1.0"?> ' + //
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:wsdl="http://www.onvif.org/ver10/media/wsdl"> ' + //
    '<soap:Header>' + //
    '<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" s:mustUnderstand="1"> ' + //
    '<UsernameToken> ' +         //
    '<Username>%s</Username> ' + //
    '<Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">%s</Password> ' +
    '<Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">%s</Nonce> ' +
    '<Created xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">%s</Created> ' + //
    '</UsernameToken> ' + //
    '</Security> ' +                               //
    '</soap:Header>' +                             //
    '<soap:Body> ' +                               //
    '<wsdl:GetSnapshotUri> ' +                     //
    '<wsdl:ProfileToken>%s</wsdl:ProfileToken> ' + //
    '</wsdl:GetSnapshotUri> ' +                    //
    '</soap:Body> ' +                              //
    '</soap:Envelope>';
Var
  PasswordDigest, Nonce, Created: String;
begin
  GetONVIFPasswordDigest(UserName, Password, PasswordDigest, Nonce, Created);
  Result := Format(GetSnapshotUriFmt, [UserName, PasswordDigest, Nonce, Created, ProfileToken]);
end;

function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol, ProfileToken: String): String;
begin
  // Addr -> http://<host>/onvif/Media
  ONVIFRequest(Addr, PrepareGetStreamUriRequest(UserName, Password, Stream, Protocol, ProfileToken), Result);
end;

function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol, ProfileToken: String): String;
const
  GetStreamUriFmt: String =    // PasswordDigest,Nonce,Created,Stream,Protocol,ProfileToken // http://<host>/onvif/Media
    '<?xml version="1.0"?> ' + //
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ' + //
    'xmlns:wsdl="http://www.onvif.org/ver10/media/wsdl" xmlns:sch="http://www.onvif.org/ver10/schema"> ' + //
    '<soap:Header>' + //
    '<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" s:mustUnderstand="1"> ' + //
    '<UsernameToken> ' + //
    '<Username>%s</Username> ' + //
    '<Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">%s</Password> ' +
    '<Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">%s</Nonce> ' +
    '<Created xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">%s</Created> ' + //
    '</UsernameToken> ' + //
    '</Security> ' +                                     //
    '</soap:Header>' +                                   //
    '<soap:Body> ' +                                     //
    '<wsdl:GetStreamUri> ' +                             //
    '<wsdl:StreamSetup> ' +                              //
    '<sch:Stream>%s</sch:Stream> ' +                     //
    '<sch:Transport> ' +                                 //
    '<sch:Protocol>%s</sch:Protocol> ' +                 //
    '<!--Optional:--> ' +                                //
    '<sch:Tunnel/> ' +                                   //
    '</sch:Transport> ' +                                //
    '<!--You may enter ANY elements at this point--> ' + //
    '</wsdl:StreamSetup> ' +                             //
    '<wsdl:ProfileToken>%s</wsdl:ProfileToken> ' +       //
    '</wsdl:GetStreamUri> ' +                            //
    '</soap:Body> ' +                                    //
    '</soap:Envelope>';

Var
  PasswordDigest, Nonce, Created: String;
begin
  GetONVIFPasswordDigest(UserName, Password, PasswordDigest, Nonce, Created);
  Result := Format(GetStreamUriFmt, [UserName, PasswordDigest, Nonce, Created, Stream, Protocol, ProfileToken]);
end;

function SHA1(const Data: TBytes): TBytes;
Var
  IdHashSHA1: TIdHashSHA1;
  i, j: TIdBytes;
begin
  IdHashSHA1 := TIdHashSHA1.Create;
  try
    SetLength(i, Length(Data));
    Move(Data[0], i[0], Length(Data));
    j := IdHashSHA1.HashBytes(i);
    SetLength(Result, Length(j));
    Move(j[0], Result[0], Length(j));
  finally
    IdHashSHA1.Free;
  end;
end;

procedure GetONVIFPasswordDigest(const UserName, Password: String; Var PasswordDigest, Nonce, Created: String);
Var
  i: Integer;
  raw_nonce, bnonce, digest: TBytes;
  raw_digest: TBytes;
  CreatedByte, PasswordByte: TBytes;
begin
  SetLength(raw_nonce, 20);
  for i := 0 to High(raw_nonce) do
    raw_nonce[i] := Random(256);
  bnonce := TNetEncoding.Base64.Encode(raw_nonce);
  Nonce := BytesToString(bnonce);
  Created := GetONVIFDateTime(Now);
  SetLength(CreatedByte, Length(Created));
  Move(Created[1], CreatedByte[0], Length(Created));
  SetLength(PasswordByte, Length(Password));
  Move(Password[1], PasswordByte[0], Length(Password));
  raw_digest := SHA1(raw_nonce + CreatedByte + PasswordByte);
  digest := TNetEncoding.Base64.Encode(raw_digest);
  PasswordDigest := BytesToString(digest);
end;

function GetONVIFDateTime(const DateTime: TDateTime): String;
Var
  formattedDate, formattedTime: string;
begin
  DateTimeToString(formattedDate, 'yyyy-mm-dd', DateTime);
  DateTimeToString(formattedTime, 'hh:nn:ss.zzz', DateTime);
  Result := formattedDate + 'T' + formattedTime + 'Z';
end;

function UniqueProbeMatch(

  const ProbeMatch: TProbeMatchArray): TProbeMatchArray;
Var
  ProbeMatchDic: TDictionary<string, TProbeMatch>;
  PM: TProbeMatch;
  comparer: IComparer<TProbeMatch>;
begin
  ProbeMatchDic := TDictionary<string, TProbeMatch>.Create;
  try
    for PM in ProbeMatch do
      if not ProbeMatchDic.ContainsKey(PM.XAddrs) then
        ProbeMatchDic.Add(PM.XAddrs, PM);
    Result := ProbeMatchDic.Values.ToArray;
    comparer := TDelegatedComparer<TProbeMatch>.Create(
      function(const Left, Right: TProbeMatch): Integer
      begin
        Result := AnsiCompareText(Left.XAddrs, Right.XAddrs);
      end);
    TArray.Sort<TProbeMatch>(Result, comparer);
  finally
    ProbeMatchDic.Free;
  end;
end;

function XMLToProbeMatch(const ProbeMatchXML: string; Var ProbeMatch: TProbeMatch): Boolean;
var
  SS: TStringStream;
  XmlNode, Node: TXmlNode;
  S: string;
  XML: TXmlVerySimple;
  i: Integer;
begin
  XML := TXmlVerySimple.Create;
  SS := TStringStream.Create(ProbeMatchXML);
  ProbeMatch := default (TProbeMatch);
  Result := False;
  try
    XML.LoadFromStream(SS);
    XmlNode := XML.DocumentElement.Find('Body');
    if Assigned(XmlNode) then
    begin
      XmlNode := XmlNode.Find('ProbeMatches');
      if Assigned(XmlNode) then
      begin
        XmlNode := XmlNode.Find('ProbeMatch');
        if Assigned(XmlNode) then
        begin
          Node := XmlNode.Find('Types');
          if Assigned(Node) then
          begin
            S := String(Node.Text);
            if Pos('NetworkVideoTransmitter', S) > 0 then
              ProbeMatch.Types := ProbeMatch.Types + [ptNetworkVideoTransmitter];
            if Pos('Device', S) > 0 then
              ProbeMatch.Types := ProbeMatch.Types + [ptDevice];
            if Pos('NetworkVideoDisplay', S) > 0 then
              ProbeMatch.Types := ProbeMatch.Types + [ptNetworkVideoDisplay];
            Result := True;
          end;

          Node := XmlNode.Find('Scopes');
          if Assigned(Node) then
          begin
            S := Trim(string(Node.Text));
            While Length(S) > 0 do
            begin
              SetLength(ProbeMatch.Scopes, Length(ProbeMatch.Scopes) + 1);
              i := Pos(' ', S);
              if i > 0 then
              begin
                ProbeMatch.Scopes[High(ProbeMatch.Scopes)] := Copy(S, 1, i - 1);
                Delete(S, 1, i);
              end
              else
              begin
                ProbeMatch.Scopes[High(ProbeMatch.Scopes)] := S;
                Break;
              end;
            end;

            ProbeMatch.XML := ProbeMatchXML;

            Result := True;
          end;

          Node := XmlNode.Find('XAddrs');
          if Assigned(Node) then
          begin
            S := string(Node.Text);
            if Pos(' ', S) <> 0 then
            begin
              ProbeMatch.XAddrs := Copy(S, 1, Pos(' ', S) - 1);
              ProbeMatch.XAddrsV6 := Copy(S, Pos(' ', S) + 1, Length(S));
            end
            else
              ProbeMatch.XAddrs := S;
            Result := True;
          end;

          Node := XmlNode.Find('MetadataVersion');
          if Assigned(Node) then
          begin
            ProbeMatch.MetadataVersion := StrToInt(Node.Text);
            Result := True;
          end;

        end;
      end;
    end;
  finally
    XML.Free;
    SS.Free;
  end;
end;

{$IFDEF MSWINDOWS}

function GetIPFromHost(var IPaddr: String): Boolean;
var
  WSAErr: String;
type
  Name = array [0 .. 100] of AnsiChar;
  PName = ^Name;
var
  HEnt: pHostEnt;
  HName: PName;
  WSAData: TWSAData;
  i: Integer;
begin
  Result := False;
  if WSAStartup($0101, WSAData) <> 0 then
  begin
    ShowMessage('Winsock is not responding.');
    Exit;
  end;
  IPaddr := '';
  New(HName);
  if GetHostName(HName^, SizeOf(Name)) = 0 then
  begin
    // HostName := StrPas(HName^);
    HEnt := GetHostByName(HName^);
    for i := 0 to HEnt^.h_length - 1 do
      IPaddr := Concat(IPaddr, IntToStr(Ord(HEnt^.h_addr_list^[i])) + '.');
    SetLength(IPaddr, Length(IPaddr) - 1);
    Result := True;
  end
  else
  begin
    case WSAGetLastError of
      WSANOTINITIALISED:
        WSAErr := 'WSANotInitialised';
      WSAENETDOWN:
        WSAErr := 'WSAENetDown';
      WSAEINPROGRESS:
        WSAErr := 'WSAEInProgress';
    end;
    ShowMessage(WSAErr);
  end;
  Dispose(HName);
  WSACleanup;
end;
{$ENDIF MSWINDOWS}
{$IFDEF ANDROID}

function GetIPFromHost(var IPaddr: String): Boolean;
var
  WiFiManager: Androidapi.JNI.Net.JWifiManager;
  lock: JWifiManager_MulticastLock;
begin
  Result := False;
  WiFiManager := GetWiFiManager;
  lock := WiFiManager.createMulticastLock(StringToJString('mylock'));
  lock.acquire();
  // TODO chiedere di attivare wifi e riprovare (senza uscire)
  if not(WiFiManager.getWifiState = TJWifiManager.JavaClass.WIFI_STATE_ENABLED) then
  begin
    TSendMessageThread.Create(TLogMessage.Create('WiFi not enabled')).Start;
    ShowMessage('WiFi not enabled');
    Exit;
  end;
  with TIPv4(WiFiManager.getConnectionInfo.getIpAddress) do
    IPaddr := Format('%d.%d.%d.%d', [a, b, c, d]);
  TSendMessageThread.Create(TLogMessage.Create(IPaddr)).Start;
  // with TIPv4(WifiManager.getDhcpInfo.netmask) do
  // LocalMask := Format('%d.%d.%d.%d', [a, b, c, d]);
  Result := True;
end;

function GetWiFiManager: JWifiManager;
var
  ConnectivityServiceNative: JObject;
begin
  ConnectivityServiceNative := TAndroidHelper.Context.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
  if not Assigned(ConnectivityServiceNative) then
    raise Exception.Create('Could not locate Connectivity Service');
  Result := TJWifiManager.Wrap((ConnectivityServiceNative as ILocalObject).GetObjectID);
  if not Assigned(Result) then
    raise Exception.Create('Could not access Connectivity Manager');
end;

{$ENDIF ANDROID}

procedure TSendMessageThread.Execute;
begin
  Synchronize(nil,
    procedure
    begin
      TMessageManager.DefaultManager.SendMessage(self, msg);
    end);
end;

constructor TSendMessageThread.Create(msg: TMessage);
begin
  inherited Create(True);
  self.FreeOnTerminate := True;
  self.msg := msg;
end;

constructor TLogMessage.Create(msg: String);
begin
  self.msg := msg;
end;

{ TONVIFProbeThread }

constructor TONVIFProbeThread.Create(const ProbeMathNotify: TProbeMathNotify; const ProbeMathXMLNotify: TProbeMathXMLNotify; const ProbeTypeSet: TProbeTypeSet;
const BindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet; const Timeout: Cardinal);
begin
  inherited Create(True);
  FProbeTypeSet := ProbeTypeSet;
  FBindToAllAvailableLocalIPsTypeSet := BindToAllAvailableLocalIPsTypeSet;
  FTimeout := Timeout;
  FProbeMathNotify := ProbeMathNotify;
  FProbeMathXMLNotify := ProbeMathXMLNotify;
  Resume;
end;

procedure TONVIFProbeThread.Execute;

const
  NetworkVideoTransmitter: String = //
    '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"><s:Header><a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</a:Action>'
    + '<a:MessageID>uuid:683b9488-db0b-44d6-9d40-a735d8483f8a</a:MessageID><a:ReplyTo><a:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous'
    + '</a:Address></a:ReplyTo><a:To s:mustUnderstand="1">urn:schemas-xmlsoap-org:ws:2005:04:discovery</a:To></s:Header><s:Body><Probe xmlns="http://schemas.xmlsoap.org/ws/2005/04/discovery">'
    + '<d:Types xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dp0="http://www.onvif.org/ver10/network/wsdl">dp0:NetworkVideoTransmitter</d:Types></Probe></s:Body></s:Envelope>';

  Device: String = //
    '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"><s:Header><a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</a:Action>'
    + '<a:MessageID>uuid:ad3ceb1c-17a4-424c-ab82-1e227f808cf8</a:MessageID><a:ReplyTo><a:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous'
    + '</a:Address></a:ReplyTo><a:To s:mustUnderstand="1">urn:schemas-xmlsoap-org:ws:2005:04:discovery</a:To></s:Header><s:Body><Probe xmlns="http://schemas.xmlsoap.org/ws/2005/04/discovery">'
    + '<d:Types xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dp0="http://www.onvif.org/ver10/device/wsdl">dp0:Device</d:Types></Probe></s:Body></s:Envelope>';

  NetworkVideoDisplay: String = //
    '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"><s:Header><a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</a:Action>'
    + '<a:MessageID>uuid:37c8b349-37d7-4d0e-be66-134af54b65cb</a:MessageID><a:ReplyTo><a:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous'
    + '</a:Address></a:ReplyTo><a:To s:mustUnderstand="1">urn:schemas-xmlsoap-org:ws:2005:04:discovery</a:To></s:Header><s:Body><Probe xmlns="http://schemas.xmlsoap.org/ws/2005/04/discovery">'
    + '<d:Types xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dp0="http://www.onvif.org/ver10/network/wsdl">dp0:NetworkVideoDisplay</d:Types></Probe></s:Body></s:Envelope>';

Var
  UDPServer: TIdUDPServer;
  IPaddr: String;
  locTimeout, locTimeoutDeltha: Cardinal;
begin
  if FProbeTypeSet = [] then
    Exit;
  UDPServer := TIdUDPServer.Create(nil);
  // E := TEvent.Create;
  try
    UDPServer.BroadcastEnabled := True;
    // E.ResetEvent;
    UDPServer.OnUDPRead := UDPServerUDPRead;
    with UDPServer.Bindings.Add do
    begin
      if ptBindToAllAvailableLocalIPs in FBindToAllAvailableLocalIPsTypeSet then
        IP := '0.0.0.0' // bind to all available local IPs
      else
      begin
        if GetIPFromHost(IPaddr) = False then
          Exit;
        IP := IPaddr;
      end;
      Port := 0; // let the OS pick a port
    end;
    UDPServer.Active := True;
    if UDPServer.Active then
    begin
      if ptNetworkVideoTransmitter in FProbeTypeSet then
      begin
        UDPServer.SendBuffer('239.255.255.250', 3702, ToBytes(NetworkVideoTransmitter));
        TInterlocked.Increment(FUDPCounter);
      end;

      if ptDevice in FProbeTypeSet then
      begin
        UDPServer.SendBuffer('239.255.255.250', 3702, ToBytes(Device));
        TInterlocked.Increment(FUDPCounter);
      end;

      if ptNetworkVideoDisplay in FProbeTypeSet then
      begin
        UDPServer.SendBuffer('239.255.255.250', 3702, ToBytes(NetworkVideoDisplay));
        TInterlocked.Increment(FUDPCounter);
      end;

      locTimeout := FTimeout;
      While (not Terminated) and (TInterlocked.Read(FUDPCounter) > 0) and (locTimeout > 0) do
      begin
        if locTimeout > 100 then
          locTimeoutDeltha := 100
        else
          locTimeoutDeltha := locTimeout;

        if locTimeout <> INFINITE then
          locTimeout := locTimeout - locTimeoutDeltha;

        Sleep(locTimeoutDeltha);
      end;

      // While (E.WaitFor(FTimeout) = wrSignaled) and (not Terminated) do
      // E.ResetEvent;

    end;
  finally
    UDPServer.Active := False;
    UDPServer.Free;
    // E.Free;
  end;
end;

procedure TONVIFProbeThread.UDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
Var
  ProbeMatch: TProbeMatch;
  ProbeMatchStr: string;
begin
  // E.SetEvent;

  ProbeMatchStr := IdGlobal.BytesToString(AData);

  SetLength(FProbeMatchXML, Length(FProbeMatchXML) + 1);
  FProbeMatchXML[High(FProbeMatchXML)] := ProbeMatchStr;
  if Assigned(FProbeMathXMLNotify) then
    FProbeMathXMLNotify(FProbeMatchXML[High(FProbeMatchXML)]);

  if XMLToProbeMatch(ProbeMatchStr, ProbeMatch) then
  begin
    SetLength(FProbeMatch, Length(FProbeMatch) + 1);
    FProbeMatch[High(FProbeMatch)] := ProbeMatch;
    if Assigned(FProbeMathNotify) then
      FProbeMathNotify(FProbeMatch[High(FProbeMatch)]);
  end;
  TInterlocked.Decrement(FUDPCounter);
end;

{ TONVIFProbe }

constructor TONVIFProbe.Create(AOwner: TComponent);
begin
  inherited;
  FTimeout := 1000;
  FProbeType := [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay];
  FBindToAllAvailableLocalIPsType := [ptBindToAllAvailableLocalIPs];

  MessageListener := self.ProcessMessage;
  TMessageManager.DefaultManager.SubscribeToMessage(TLogMessage, MessageListener);
end;

destructor TONVIFProbe.Destroy;
begin
  if Assigned(FONVIFProbeThread) then
    FreeAndNil(FONVIFProbeThread);
  TMessageManager.DefaultManager.Unsubscribe(TLogMessage, MessageListener);
  inherited;
end;

function TONVIFProbe.Execute: Boolean;
begin
  if Assigned(FONVIFProbeThread) then
    FreeAndNil(FONVIFProbeThread);
  FONVIFProbeThread := TONVIFProbeThread.Create(nil, nil, ProbeType, BindToAllAvailableLocalIPsType, Timeout);
  FONVIFProbeThread.WaitFor;
  Result := Length(FONVIFProbeThread.ProbeMatchXML) > 0;
end;

function TONVIFProbe.ExecuteAsync: Boolean;
begin
  if Assigned(FONVIFProbeThread) then
    FreeAndNil(FONVIFProbeThread);
  FONVIFProbeThread := TONVIFProbeThread.Create(OnProbeMath, OnProbeMathXML, ProbeType, BindToAllAvailableLocalIPsType, Timeout);
  FONVIFProbeThread.OnTerminate := OnCompleted;
  Result := True;
end;

function TONVIFProbe.GetCount: Integer;
begin
  if Assigned(FONVIFProbeThread) then
    Result := Length(FONVIFProbeThread.ProbeMatch)
  else
    Result := 0;
end;

function TONVIFProbe.GetProbeMatch(const Index: Integer): TProbeMatch;
begin
  if Assigned(FONVIFProbeThread) then
    Result := FONVIFProbeThread.ProbeMatch[Index]
  else
    Result := default (TProbeMatch)
end;

function TONVIFProbe.GetProbeMatchArray: TProbeMatchArray;
begin
  if Assigned(FONVIFProbeThread) then
    Result := FONVIFProbeThread.ProbeMatch
  else
    Result := default (TProbeMatchArray);
end;

function TONVIFProbe.GetProbeMatchXML(const Index: Integer): String;
begin
  if Assigned(FONVIFProbeThread) then
    Result := FONVIFProbeThread.ProbeMatchXML[Index]
  else
    Result := default (String);
end;

procedure TONVIFProbe.ProcessMessage(const Sender: TObject; const M: TMessage);
begin
  if M is TLogMessage then
  begin
    if Assigned(OnLogMessage) then
      OnLogMessage((M as TLogMessage).msg);
  end;
end;

end.
