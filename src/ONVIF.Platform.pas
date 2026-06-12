unit ONVIF.Platform;

interface

uses
  ONVIF.Types
{$IFDEF ANDROID}
  , Androidapi.JNI.Net
{$ENDIF ANDROID}
  ;

function GetIPFromHost(var IPaddr: string): Boolean;

{$IFDEF ANDROID}
function GetWiFiManager: JWifiManager;
{$ENDIF ANDROID}

implementation

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Messaging
{$IFDEF MSWINDOWS}
  , Winapi.Winsock
{$ENDIF MSWINDOWS}
{$IFDEF ANDROID}
  , Androidapi.Helpers, Androidapi.JNIBridge, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes, Androidapi.JNI
{$ENDIF ANDROID}
{$IFDEF LINUX}
  , Posix.SysSocket, Posix.NetDB, Posix.NetinetIn, Posix.ArpaInet, Posix.Unistd
{$ENDIF LINUX}
  ;

type
  TSendMessageThread = class(TThread)
  private
    FMsg: TMessage;
    procedure DoSendMessage;
  protected
    procedure Execute; override;
  public
    constructor Create(AMsg: TMessage); reintroduce;
  end;

constructor TSendMessageThread.Create(AMsg: TMessage);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FMsg := AMsg;
end;

procedure TSendMessageThread.DoSendMessage;
begin
  TMessageManager.DefaultManager.SendMessage(Self, FMsg);
end;

procedure TSendMessageThread.Execute;
begin
  Synchronize(DoSendMessage);
end;

{$IFDEF MSWINDOWS}

function GetIPFromHost(var IPaddr: string): Boolean;
type
  THostName = array [0 .. 100] of AnsiChar;
  PHostName = ^THostName;
var
  HEnt: PHostEnt;
  HName: PHostName;
  WSAData: TWSAData;
  I: Integer;
begin
  Result := False;
  if WSAStartup($0101, WSAData) <> 0 then
    Exit;
  IPaddr := '';
  New(HName);
  try
    if GetHostName(HName^, SizeOf(THostName)) = 0 then
    begin
      HEnt := GetHostByName(HName^);
      for I := 0 to HEnt^.h_length - 1 do
        IPaddr := Concat(IPaddr, IntToStr(Ord(HEnt^.h_addr_list^[I])) + '.');
      SetLength(IPaddr, Length(IPaddr) - 1);
      Result := True;
    end;
  finally
    Dispose(HName);
    WSACleanup;
  end;
end;

{$ENDIF MSWINDOWS}

{$IFDEF ANDROID}

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

function GetIPFromHost(var IPaddr: string): Boolean;
var
  WiFiManager: JWifiManager;
  Lock: JWifiManager_MulticastLock;
begin
  Result := False;
  WiFiManager := GetWiFiManager;
  Lock := WiFiManager.createMulticastLock(StringToJString('onvif_probe'));
  Lock.acquire();
  try
    if WiFiManager.getWifiState <> TJWifiManager.JavaClass.WIFI_STATE_ENABLED then
    begin
      TSendMessageThread.Create(TLogMessage.Create('WiFi not enabled')).Start;
      Exit;
    end;
    with TIPv4(WiFiManager.getConnectionInfo.getIpAddress) do
      IPaddr := Format('%d.%d.%d.%d', [a, b, c, d]);
    TSendMessageThread.Create(TLogMessage.Create(IPaddr)).Start;
    Result := True;
  finally
    Lock.release();
  end;
end;

{$ENDIF ANDROID}

{$IFDEF LINUX}

function GetIPFromHost(var IPaddr: string): Boolean;
var
  HostBuf: array [0 .. 255] of AnsiChar;
  Hint: addrinfo;
  HostInfo: Paddrinfo;
  Addr: in_addr;
  Res: Integer;
begin
  Result := False;
  IPaddr := '';
  if gethostname(@HostBuf[0], SizeOf(HostBuf)) <> 0 then
    Exit;
  FillChar(Hint, SizeOf(Hint), 0);
  Hint.ai_family := AF_INET;
  Hint.ai_flags := AI_IDN;
  Hint.ai_socktype := SOCK_STREAM;
  HostInfo := nil;
  Res := getaddrinfo(@HostBuf[0], nil, Hint, HostInfo);
  if (Res <> 0) or (HostInfo = nil) or (HostInfo^.ai_addr = nil) then
    Exit;
  try
    Addr := Psockaddr_in(HostInfo^.ai_addr)^.sin_addr;
    IPaddr := string(AnsiString(inet_ntoa(Addr)));
    Result := IPaddr <> '';
  finally
    freeaddrinfo(HostInfo^);
  end;
end;

{$ENDIF LINUX}

{$IFNDEF MSWINDOWS}
{$IFNDEF ANDROID}
{$IFNDEF LINUX}
function GetIPFromHost(var IPaddr: string): Boolean;
begin
  IPaddr := '';
  Result := False;
end;
{$ENDIF LINUX}
{$ENDIF ANDROID}
{$ENDIF MSWINDOWS}

end.
