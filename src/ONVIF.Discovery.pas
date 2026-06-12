unit ONVIF.Discovery;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Messaging,
  IdUDPServer,
  IdGlobal,
  IdSocketHandle,
  ONVIF.Types,
  ONVIF.Core,
  ONVIF.Platform;

type
  TONVIFProbeThread = class;

  TONVIFProbe = class(TComponent)
  private
    FONVIFProbeThread: TONVIFProbeThread;
    FOnProbeMatchXML: TProbeMatchXMLNotify;
    FOnCompleted: TNotifyEvent;
    FOnProbeMatch: TProbeMatchNotify;
    FProbeType: TProbeTypeSet;
    FBindToAllAvailableLocalIPsType: TBindToAllAvailableLocalIPsTypeSet;
    FTimeout: Cardinal;
    FMessageListener: TMessageListenerMethod;
    FOnLogMessage: TLogMessageNotify;
    procedure ReleaseProbeThread;
    procedure ProbeThreadTerminated(Sender: TObject);
    function StartProbeThread(const AMode: TONVIFProbeMode;
      const ATargetHosts: TArray<string>): Boolean;
    function GetCount: Integer;
    function GetProbeMatch(const Index: Integer): TProbeMatch;
    function GetProbeMatchXML(const Index: Integer): string;
    function GetProbeMatchArray: TProbeMatchArray;
    procedure ProcessMessage(const Sender: TObject; const M: TMessage);
    function GetOnProbeMath: TProbeMatchNotify;
    procedure SetOnProbeMath(const Value: TProbeMatchNotify);
    function GetOnProbeMathXML: TProbeMatchXMLNotify;
    procedure SetOnProbeMathXML(const Value: TProbeMatchXMLNotify);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute: Boolean;
    function ExecuteAsync: Boolean;
    function ExecuteUnicast(const AHost: string): TProbeMatchArray;
    function ExecuteUnicastAsync(const AHost: string): Boolean;
    function ExecuteSubnet(const AOptions: TONVIFSubnetProbeOptions): TProbeMatchArray;
    function ExecuteSubnetAsync(const AOptions: TONVIFSubnetProbeOptions): Boolean;
    property Count: Integer read GetCount;
    property ProbeMatchXML[const Index: Integer]: string read GetProbeMatchXML;
    property ProbeMatch[const Index: Integer]: TProbeMatch read GetProbeMatch;
    property ProbeMatchArray: TProbeMatchArray read GetProbeMatchArray;
  published
    property OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
    property OnProbeMatch: TProbeMatchNotify read FOnProbeMatch write FOnProbeMatch;
    property OnProbeMatchXML: TProbeMatchXMLNotify read FOnProbeMatchXML write FOnProbeMatchXML;
    property OnProbeMath: TProbeMatchNotify read GetOnProbeMath write SetOnProbeMath;
    property OnProbeMathXML: TProbeMatchXMLNotify read GetOnProbeMathXML write SetOnProbeMathXML;
    property ProbeType: TProbeTypeSet read FProbeType write FProbeType
      default [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay];
    property Timeout: Cardinal read FTimeout write FTimeout default 1000;
    property OnLogMessage: TLogMessageNotify read FOnLogMessage write FOnLogMessage;
    property BindToAllAvailableLocalIPsType: TBindToAllAvailableLocalIPsTypeSet
      read FBindToAllAvailableLocalIPsType write FBindToAllAvailableLocalIPsType
      default [ptBindToAllAvailableLocalIPs];
  end;

  TONVIFProbeThread = class(TThread)
  private
    FProbeMatchXML: TProbeMatchXMLArray;
    FProbeTypeSet: TProbeTypeSet;
    FBindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet;
    FTimeout: Cardinal;
    FUDPCounter: Int64;
    FProbeMatch: TProbeMatchArray;
    FProbeMatchNotify: TProbeMatchNotify;
    FProbeMatchXMLNotify: TProbeMatchXMLNotify;
    FProbeMode: TONVIFProbeMode;
    FTargetHosts: TArray<string>;
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes;
      ABinding: TIdSocketHandle);
    procedure SendProbeBuffer(UDPServer: TIdUDPServer; const TargetHost, Payload: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const AProbeMatchNotify: TProbeMatchNotify = nil;
      const AProbeMatchXMLNotify: TProbeMatchXMLNotify = nil;
      const AProbeTypeSet: TProbeTypeSet = [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay];
      const ABindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet = [ptBindToAllAvailableLocalIPs];
      const ATimeout: Cardinal = 1000;
      const AProbeMode: TONVIFProbeMode = pmMulticast;
      const ATargetHosts: TArray<string> = nil);
    property ProbeMatchXML: TProbeMatchXMLArray read FProbeMatchXML;
    property ProbeMatch: TProbeMatchArray read FProbeMatch;
  end;

function ONVIFProbe: TProbeMatchArray;
function ONVIFUnicastProbe(const Host: string; Timeout: Cardinal = 1000): TProbeMatchArray;
function ONVIFSubnetProbe(const Options: TONVIFSubnetProbeOptions;
  Timeout: Cardinal = 3000): TProbeMatchArray;
function DefaultSubnetProbeOptions: TONVIFSubnetProbeOptions;
function ParseSubnetSpec(const Spec: string; out Options: TONVIFSubnetProbeOptions): Boolean;
function EnumerateSubnetHosts(const Options: TONVIFSubnetProbeOptions): TArray<string>;

implementation

const
  WSDiscoveryPort = 3702;
  WSDiscoveryMulticast = '239.255.255.250';

function DefaultSubnetProbeOptions: TONVIFSubnetProbeOptions;
begin
  Result.NetworkAddress := '192.168.1.0';
  Result.PrefixLength := 24;
  Result.FirstHost := 1;
  Result.LastHost := 254;
end;

function ParseSubnetSpec(const Spec: string; out Options: TONVIFSubnetProbeOptions): Boolean;
var
  S, NetPart, PrefixPart: string;
  P, PrefixLen: Integer;
  A, B, C, D: Byte;
  Octets: TArray<string>;
begin
  Options := DefaultSubnetProbeOptions;
  S := Trim(Spec);
  if S = '' then
    Exit(False);
  P := Pos('/', S);
  if P > 0 then
  begin
    NetPart := Trim(Copy(S, 1, P - 1));
    PrefixPart := Trim(Copy(S, P + 1, MaxInt));
    if not TryStrToInt(PrefixPart, PrefixLen) or (PrefixLen < 8) or (PrefixLen > 30) then
      Exit(False);
    Options.PrefixLength := Byte(PrefixLen);
  end
  else
    NetPart := S;

  Octets := NetPart.Split(['.']);
  if Length(Octets) = 3 then
    Options.NetworkAddress := NetPart + '.0'
  else if Length(Octets) = 4 then
    Options.NetworkAddress := NetPart
  else
    Exit(False);
  if not ParseIPv4Address(Options.NetworkAddress, A, B, C, D) then
    Exit(False);
  Result := True;
end;

function EnumerateSubnetHosts(const Options: TONVIFSubnetProbeOptions): TArray<string>;
var
  A, B, C, D: Byte;
  HostCount, I, HostIdx: Cardinal;
  FirstHost, LastHost: Byte;
begin
  Result := nil;
  if not ParseIPv4Address(Options.NetworkAddress, A, B, C, D) then
    Exit;
  if Options.PrefixLength <> 24 then
    Exit;

  FirstHost := Options.FirstHost;
  LastHost := Options.LastHost;
  if FirstHost = 0 then
    FirstHost := 1;
  if LastHost = 0 then
    LastHost := 254;
  if FirstHost > LastHost then
    Exit;

  HostCount := LastHost - FirstHost + 1;
  SetLength(Result, HostCount);
  HostIdx := 0;
  for I := FirstHost to LastHost do
  begin
    Result[HostIdx] := Format('%d.%d.%d.%d', [A, B, C, I]);
    Inc(HostIdx);
  end;
end;

function RunProbeThread(const AProbeMatchNotify: TProbeMatchNotify;
  const AProbeMatchXMLNotify: TProbeMatchXMLNotify; const AProbeTypeSet: TProbeTypeSet;
  const ABindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet;
  const ATimeout: Cardinal; const AProbeMode: TONVIFProbeMode;
  const ATargetHosts: TArray<string>): TProbeMatchArray;
var
  Thread: TONVIFProbeThread;
begin
  Thread := TONVIFProbeThread.Create(AProbeMatchNotify, AProbeMatchXMLNotify, AProbeTypeSet,
    ABindToAllAvailableLocalIPsTypeSet, ATimeout, AProbeMode, ATargetHosts);
  try
    Thread.Start;
    Thread.WaitFor;
    Result := Thread.ProbeMatch;
  finally
    Thread.Free;
  end;
end;

function ONVIFProbe: TProbeMatchArray;
begin
  Result := RunProbeThread(nil, nil,
    [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay],
    [ptBindToAllAvailableLocalIPs], 1000, pmMulticast, nil);
end;

function ONVIFUnicastProbe(const Host: string; Timeout: Cardinal): TProbeMatchArray;
var
  Target: string;
begin
  Target := Trim(Host);
  if Target = '' then
    Exit(nil);
  Result := RunProbeThread(nil, nil, [ptDevice], [ptBindToAllAvailableLocalIPs],
    Timeout, pmUnicast, [Target]);
end;

function ONVIFSubnetProbe(const Options: TONVIFSubnetProbeOptions;
  Timeout: Cardinal): TProbeMatchArray;
var
  Hosts: TArray<string>;
begin
  Hosts := EnumerateSubnetHosts(Options);
  if Length(Hosts) = 0 then
    Exit(nil);
  Result := RunProbeThread(nil, nil, [ptDevice], [ptBindToAllAvailableLocalIPs],
    Timeout, pmSubnet, Hosts);
end;

function TONVIFProbe.GetOnProbeMath: TProbeMatchNotify;
begin
  Result := FOnProbeMatch;
end;

procedure TONVIFProbe.SetOnProbeMath(const Value: TProbeMatchNotify);
begin
  FOnProbeMatch := Value;
end;

function TONVIFProbe.GetOnProbeMathXML: TProbeMatchXMLNotify;
begin
  Result := FOnProbeMatchXML;
end;

procedure TONVIFProbe.SetOnProbeMathXML(const Value: TProbeMatchXMLNotify);
begin
  FOnProbeMatchXML := Value;
end;

constructor TONVIFProbeThread.Create(const AProbeMatchNotify: TProbeMatchNotify;
  const AProbeMatchXMLNotify: TProbeMatchXMLNotify; const AProbeTypeSet: TProbeTypeSet;
  const ABindToAllAvailableLocalIPsTypeSet: TBindToAllAvailableLocalIPsTypeSet;
  const ATimeout: Cardinal; const AProbeMode: TONVIFProbeMode;
  const ATargetHosts: TArray<string>);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FProbeTypeSet := AProbeTypeSet;
  FBindToAllAvailableLocalIPsTypeSet := ABindToAllAvailableLocalIPsTypeSet;
  FTimeout := ATimeout;
  FProbeMatchNotify := AProbeMatchNotify;
  FProbeMatchXMLNotify := AProbeMatchXMLNotify;
  FProbeMode := AProbeMode;
  FTargetHosts := ATargetHosts;
end;

function NewProbeMessageId: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := 'uuid:' + GUIDToString(G).Trim(['{', '}']);
end;

function BuildProbeEnvelope(const TypesXml, MessageId: string): string;
begin
  Result :=
    '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing">' +
    '<s:Header><a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</a:Action>' +
    '<a:MessageID>' + MessageId + '</a:MessageID>' +
    '<a:ReplyTo><a:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:Address></a:ReplyTo>' +
    '<a:To s:mustUnderstand="1">urn:schemas-xmlsoap-org:ws:2005:04:discovery</a:To></s:Header>' +
    '<s:Body><Probe xmlns="http://schemas.xmlsoap.org/ws/2005/04/discovery">' +
    TypesXml +
    '</Probe></s:Body></s:Envelope>';
end;

procedure TONVIFProbeThread.SendProbeBuffer(UDPServer: TIdUDPServer;
  const TargetHost, Payload: string);
begin
  if TargetHost = '' then
    UDPServer.SendBuffer(WSDiscoveryMulticast, WSDiscoveryPort, ToBytes(Payload))
  else
    UDPServer.SendBuffer(TargetHost, WSDiscoveryPort, ToBytes(Payload));
  if FProbeMode = pmMulticast then
    TInterlocked.Increment(FUDPCounter);
end;

procedure TONVIFProbeThread.Execute;
const
  NetworkVideoTransmitterTypes =
    '<d:Types xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dp0="http://www.onvif.org/ver10/network/wsdl">dp0:NetworkVideoTransmitter</d:Types>';
  DeviceTypes =
    '<d:Types xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dp0="http://www.onvif.org/ver10/device/wsdl">dp0:Device</d:Types>';
  NetworkVideoDisplayTypes =
    '<d:Types xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dp0="http://www.onvif.org/ver10/network/wsdl">dp0:NetworkVideoDisplay</d:Types>';
var
  NetworkVideoTransmitter, Device, NetworkVideoDisplay: string;
  UDPServer: TIdUDPServer;
  IPaddr: string;
  RemainingTimeout, SleepDelta: Cardinal;
  Host: string;
  Targets: TArray<string>;
  ProbeTypes: TProbeTypeSet;
begin
  if FProbeMode = pmMulticast then
  begin
    SetLength(Targets, 1);
    Targets[0] := '';
    ProbeTypes := FProbeTypeSet;
  end
  else
  begin
    Targets := FTargetHosts;
    ProbeTypes := [ptNetworkVideoTransmitter, ptDevice];
    if Length(Targets) = 0 then
      Exit;
  end;

  if ProbeTypes = [] then
    Exit;

  UDPServer := TIdUDPServer.Create(nil);
  try
    UDPServer.BroadcastEnabled := True;
    UDPServer.OnUDPRead := UDPServerUDPRead;
    with UDPServer.Bindings.Add do
    begin
      if ptBindToAllAvailableLocalIPs in FBindToAllAvailableLocalIPsTypeSet then
        IP := '0.0.0.0'
      else
      begin
        if not GetIPFromHost(IPaddr) then
          Exit;
        IP := IPaddr;
      end;
      Port := 0;
    end;
    UDPServer.Active := True;
    if not UDPServer.Active then
      Exit;

    for Host in Targets do
    begin
      if ptNetworkVideoTransmitter in ProbeTypes then
      begin
        NetworkVideoTransmitter := BuildProbeEnvelope(NetworkVideoTransmitterTypes, NewProbeMessageId);
        SendProbeBuffer(UDPServer, Host, NetworkVideoTransmitter);
      end;
      if ptDevice in ProbeTypes then
      begin
        Device := BuildProbeEnvelope(DeviceTypes, NewProbeMessageId);
        SendProbeBuffer(UDPServer, Host, Device);
      end;
      if ptNetworkVideoDisplay in ProbeTypes then
      begin
        NetworkVideoDisplay := BuildProbeEnvelope(NetworkVideoDisplayTypes, NewProbeMessageId);
        SendProbeBuffer(UDPServer, Host, NetworkVideoDisplay);
      end;
    end;

    if FProbeMode = pmMulticast then
    begin
      RemainingTimeout := FTimeout;
      while (not Terminated) and (TInterlocked.Read(FUDPCounter) > 0) and (RemainingTimeout > 0) do
      begin
        if RemainingTimeout > 100 then
          SleepDelta := 100
        else
          SleepDelta := RemainingTimeout;
        if RemainingTimeout <> INFINITE then
          RemainingTimeout := RemainingTimeout - SleepDelta;
        Sleep(SleepDelta);
      end;
    end
    else
      Sleep(FTimeout);
  finally
    UDPServer.Active := False;
    UDPServer.Free;
  end;
end;

procedure TONVIFProbeThread.UDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  ProbeMatch: TProbeMatch;
  ProbeMatches: TProbeMatchArray;
  ProbeMatchStr: string;
  I: Integer;
begin
  ProbeMatchStr := IdGlobal.BytesToString(AData);
  SetLength(FProbeMatchXML, Length(FProbeMatchXML) + 1);
  FProbeMatchXML[High(FProbeMatchXML)] := ProbeMatchStr;
  if Assigned(FProbeMatchXMLNotify) then
    FProbeMatchXMLNotify(FProbeMatchXML[High(FProbeMatchXML)]);
  ProbeMatches := XMLToProbeMatches(ProbeMatchStr);
  if Length(ProbeMatches) = 0 then
  begin
    if XMLToProbeMatch(ProbeMatchStr, ProbeMatch) then
    begin
      SetLength(ProbeMatches, 1);
      ProbeMatches[0] := ProbeMatch;
    end;
  end;
  if Length(ProbeMatches) > 0 then
  begin
    for I := 0 to High(ProbeMatches) do
    begin
      SetLength(FProbeMatch, Length(FProbeMatch) + 1);
      FProbeMatch[High(FProbeMatch)] := ProbeMatches[I];
      if Assigned(FProbeMatchNotify) then
        FProbeMatchNotify(ProbeMatches[I]);
    end;
    if FProbeMode = pmMulticast then
      TInterlocked.Decrement(FUDPCounter);
  end;
end;

constructor TONVIFProbe.Create(AOwner: TComponent);
begin
  inherited;
  FTimeout := 1000;
  FProbeType := [ptNetworkVideoTransmitter, ptDevice, ptNetworkVideoDisplay];
  FBindToAllAvailableLocalIPsType := [ptBindToAllAvailableLocalIPs];
  FMessageListener := ProcessMessage;
  TMessageManager.DefaultManager.SubscribeToMessage(TLogMessage, FMessageListener);
end;

destructor TONVIFProbe.Destroy;
begin
  ReleaseProbeThread;
  TMessageManager.DefaultManager.Unsubscribe(TLogMessage, FMessageListener);
  inherited;
end;

procedure TONVIFProbe.ReleaseProbeThread;
begin
  if not Assigned(FONVIFProbeThread) then
    Exit;
  FONVIFProbeThread.OnTerminate := nil;
  if not FONVIFProbeThread.Finished then
    FONVIFProbeThread.Terminate;
  FONVIFProbeThread.WaitFor;
  FreeAndNil(FONVIFProbeThread);
end;

procedure TONVIFProbe.ProbeThreadTerminated(Sender: TObject);
begin
  if Assigned(FOnCompleted) then
    FOnCompleted(Self);
end;

function TONVIFProbe.StartProbeThread(const AMode: TONVIFProbeMode;
  const ATargetHosts: TArray<string>): Boolean;
begin
  if Assigned(FONVIFProbeThread) and not FONVIFProbeThread.Finished then
    Exit(False);
  ReleaseProbeThread;
  FONVIFProbeThread := TONVIFProbeThread.Create(OnProbeMatch, OnProbeMatchXML,
    ProbeType, BindToAllAvailableLocalIPsType, Timeout, AMode, ATargetHosts);
  FONVIFProbeThread.OnTerminate := ProbeThreadTerminated;
  FONVIFProbeThread.Start;
  Result := True;
end;

function TONVIFProbe.Execute: Boolean;
begin
  ReleaseProbeThread;
  FONVIFProbeThread := TONVIFProbeThread.Create(nil, nil, ProbeType,
    BindToAllAvailableLocalIPsType, Timeout, pmMulticast, nil);
  FONVIFProbeThread.Start;
  FONVIFProbeThread.WaitFor;
  try
    Result := Length(FONVIFProbeThread.ProbeMatchXML) > 0;
  finally
    ReleaseProbeThread;
  end;
end;

function TONVIFProbe.ExecuteAsync: Boolean;
begin
  Result := StartProbeThread(pmMulticast, nil);
end;

function TONVIFProbe.ExecuteUnicast(const AHost: string): TProbeMatchArray;
begin
  Result := ONVIFUnicastProbe(AHost, Timeout);
end;

function TONVIFProbe.ExecuteUnicastAsync(const AHost: string): Boolean;
var
  Host: string;
begin
  Host := Trim(AHost);
  if Host = '' then
    Exit(False);
  Result := StartProbeThread(pmUnicast, [Host]);
end;

function TONVIFProbe.ExecuteSubnet(const AOptions: TONVIFSubnetProbeOptions): TProbeMatchArray;
begin
  Result := ONVIFSubnetProbe(AOptions, Timeout);
end;

function TONVIFProbe.ExecuteSubnetAsync(const AOptions: TONVIFSubnetProbeOptions): Boolean;
var
  Hosts: TArray<string>;
begin
  Hosts := EnumerateSubnetHosts(AOptions);
  if Length(Hosts) = 0 then
    Exit(False);
  Result := StartProbeThread(pmSubnet, Hosts);
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
    Result := default (TProbeMatch);
end;

function TONVIFProbe.GetProbeMatchArray: TProbeMatchArray;
begin
  if Assigned(FONVIFProbeThread) then
    Result := FONVIFProbeThread.ProbeMatch
  else
    Result := default (TProbeMatchArray);
end;

function TONVIFProbe.GetProbeMatchXML(const Index: Integer): string;
begin
  if Assigned(FONVIFProbeThread) then
    Result := FONVIFProbeThread.ProbeMatchXML[Index]
  else
    Result := default (string);
end;

procedure TONVIFProbe.ProcessMessage(const Sender: TObject; const M: TMessage);
begin
  if M is TLogMessage then
    if Assigned(OnLogMessage) then
      OnLogMessage(TLogMessage(M).Msg);
end;

end.
