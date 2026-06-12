unit ONVIF.Device;

interface

uses
  System.SysUtils,
  ONVIF.Types;

const
  ONVIF_NS_DEVICE = 'xmlns:tds="http://www.onvif.org/ver10/device/wsdl"';

function PrepareGetDeviceInformationRequest(const UserName, Password: string): string;
function ONVIFGetDeviceInformation(const Addr, UserName, Password: string): string;
function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: string;
  var DeviceInformation: TDeviceInformation): Boolean;

function PrepareGetCapabilitiesRequest(const UserName, Password: string): string;
function ONVIFGetCapabilities(const Addr, UserName, Password: string): string;
function XMLCapabilitiesToCapabilities(const AXml: string; var Capabilities: TONVIFCapabilities): Boolean;

function PrepareGetServicesRequest(const UserName, Password: string; IncludeCapability: Boolean): string;
function ONVIFGetServices(const Addr, UserName, Password: string;
  IncludeCapability: Boolean = True): string;
function XMLServicesToCapabilities(const AXml, DeviceXAddr: string;
  var Capabilities: TONVIFCapabilities): Boolean;

function PrepareGetSystemDateAndTimeRequest: string;
function ONVIFGetSystemDateAndTime(const Addr: string): string;
function XMLSystemDateAndTimeToDateTime(const AXml: string; var DateTime: TONVIFDateTime): Boolean;

function PrepareSetSystemDateAndTimeRequest(const DateTime: TONVIFDateTime): string;
function ONVIFSetSystemDateAndTime(const Addr, UserName, Password: string;
  const DateTime: TONVIFDateTime): TONVIFRequestResult;

function PrepareGetHostnameRequest(const UserName, Password: string): string;
function ONVIFGetHostname(const Addr, UserName, Password: string): string;
function XMLHostnameToHostname(const AXml: string; var Hostname: TONVIFHostnameInformation): Boolean;

function PrepareGetDNSRequest(const UserName, Password: string): string;
function ONVIFGetDNS(const Addr, UserName, Password: string): string;
function XMLDNSToDNS(const AXml: string; var DNS: TONVIFDNSInformation): Boolean;

function PrepareGetUsersRequest(const UserName, Password: string): string;
function ONVIFGetUsers(const Addr, UserName, Password: string): string;
function XMLUsersToUsers(const AXml: string; var Users: TONVIFUsers): Boolean;

function PrepareCreateUsersRequest(const UserName, Password: string; const Users: TONVIFUsers): string;
function ONVIFCreateUsers(const Addr, UserName, Password: string; const Users: TONVIFUsers): TONVIFRequestResult;

function PrepareDeleteUsersRequest(const UserName, Password: string; const UserNames: TArray<string>): string;
function ONVIFDeleteUsers(const Addr, UserName, Password: string;
  const UserNames: TArray<string>): TONVIFRequestResult;

function PrepareGetNetworkInterfacesRequest(const UserName, Password: string): string;
function ONVIFGetNetworkInterfaces(const Addr, UserName, Password: string): string;
function XMLNetworkInterfacesToInterfaces(const AXml: string;
  var Interfaces: TONVIFNetworkInterfaces): Boolean;

function PrepareGetScopesRequest(const UserName, Password: string): string;
function ONVIFGetScopes(const Addr, UserName, Password: string): string;
function XMLScopesToScopes(const AXml: string; var Scopes: TONVIFScopes): Boolean;

function PrepareSetScopesRequest(const UserName, Password: string; const Scopes: TONVIFScopes): string;
function ONVIFSetScopes(const Addr, UserName, Password: string;
  const Scopes: TONVIFScopes): TONVIFRequestResult;

function PrepareSystemRebootRequest(const UserName, Password: string): string;
function ONVIFSystemReboot(const Addr, UserName, Password: string): TONVIFRequestResult;

function ServiceTypeFromNamespace(const Namespace: string): TONVIFServiceType;
function DiscoverCapabilities(const DeviceXAddr, UserName, Password: string): TONVIFCapabilities;

implementation

uses
  System.DateUtils,
  System.StrUtils,
  ONVIF.Core,
  ONVIF.Xml;

function ServiceTypeFromNamespace(const Namespace: string): TONVIFServiceType;
begin
  if Pos('ver10/device/wsdl', Namespace) > 0 then
    Exit(stDevice);
  if Pos('ver20/media/wsdl', Namespace) > 0 then
    Exit(stMedia2);
  if Pos('ver10/media/wsdl', Namespace) > 0 then
    Exit(stMedia);
  if Pos('ver10/ptz/wsdl', Namespace) > 0 then
    Exit(stPTZ);
  if Pos('ver10/imaging/wsdl', Namespace) > 0 then
    Exit(stImaging);
  if Pos('ver10/events/wsdl', Namespace) > 0 then
    Exit(stEvents);
  if Pos('ver10/analytics/wsdl', Namespace) > 0 then
    Exit(stAnalytics);
  if Pos('ver10/recording/wsdl', Namespace) > 0 then
    Exit(stRecording);
  if Pos('ver10/search/wsdl', Namespace) > 0 then
    Exit(stSearch);
  if Pos('ver10/replay/wsdl', Namespace) > 0 then
    Exit(stReplay);
  if Pos('ver10/deviceIO/wsdl', Namespace) > 0 then
    Exit(stDeviceIO);
  Result := stUnknown;
end;

procedure AppendService(var Capabilities: TONVIFCapabilities;
  const Endpoint: TONVIFServiceEndpoint);
begin
  SetLength(Capabilities.Services, Length(Capabilities.Services) + 1);
  Capabilities.Services[High(Capabilities.Services)] := Endpoint;
end;

function PrepareGetDeviceInformationRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetDeviceInformation/>', UserName, Password);
end;

function ONVIFGetDeviceInformation(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetDeviceInformationRequest(UserName, Password), Result);
end;

function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: string;
  var DeviceInformation: TDeviceInformation): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
begin
  DeviceInformation := default(TDeviceInformation);
  Result := False;
  Doc := LoadONVIFXml(XMLDeviceInformation);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetDeviceInformationResponse');
  if Response = nil then
    Exit;
  Node := Response.FindChild('Manufacturer');
  if Node <> nil then
    DeviceInformation.Manufacturer := Node.Text;
  Node := Response.FindChild('Model');
  if Node <> nil then
    DeviceInformation.Model := Node.Text;
  Node := Response.FindChild('FirmwareVersion');
  if Node <> nil then
    DeviceInformation.FirmwareVersion := Node.Text;
  Node := Response.FindChild('SerialNumber');
  if Node <> nil then
    DeviceInformation.SerialNumber := Node.Text;
  Node := Response.FindChild('HardwareId');
  if Node <> nil then
    DeviceInformation.HardwareId := Node.Text;
  Result := True;
end;

function PrepareGetCapabilitiesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetCapabilities><tds:Category>All</tds:Category></tds:GetCapabilities>',
    UserName, Password);
end;

function ONVIFGetCapabilities(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetCapabilitiesRequest(UserName, Password), Result);
end;

function ParseCapabilityXAddr(const CapNode: IONVIFXmlNode; AType: TONVIFServiceType;
  const Namespace: string; var Capabilities: TONVIFCapabilities): Boolean;
var
  E: TONVIFServiceEndpoint;
  XAddr: string;
begin
  Result := False;
  if CapNode = nil then
    Exit;
  XAddr := CapNode.FindChild('XAddr').Text;
  if XAddr = '' then
    Exit;
  E.ServiceType := AType;
  E.Namespace := Namespace;
  E.XAddr := XAddr;
  E.MajorVersion := 1;
  E.MinorVersion := 0;
  AppendService(Capabilities, E);
  Result := True;
end;

function XMLCapabilitiesToCapabilities(const AXml: string;
  var Capabilities: TONVIFCapabilities): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Caps: IONVIFXmlNode;
begin
  Capabilities := default(TONVIFCapabilities);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetCapabilitiesResponse');
  if Response = nil then
    Exit;
  Caps := Response.FindChild('Capabilities');
  if Caps = nil then
    Exit;
  Capabilities.DeviceXAddr := Caps.FindChild('Device').FindChild('XAddr').Text;
  ParseCapabilityXAddr(Caps.FindChild('Media'), stMedia,
    'http://www.onvif.org/ver10/media/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('PTZ'), stPTZ,
    'http://www.onvif.org/ver10/ptz/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('Imaging'), stImaging,
    'http://www.onvif.org/ver10/imaging/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('Events'), stEvents,
    'http://www.onvif.org/ver10/events/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('Analytics'), stAnalytics,
    'http://www.onvif.org/ver10/analytics/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('Recording'), stRecording,
    'http://www.onvif.org/ver10/recording/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('Search'), stSearch,
    'http://www.onvif.org/ver10/search/wsdl', Capabilities);
  ParseCapabilityXAddr(Caps.FindChild('Replay'), stReplay,
    'http://www.onvif.org/ver10/replay/wsdl', Capabilities);
  Result := Capabilities.DeviceXAddr <> '';
end;

function PrepareGetServicesRequest(const UserName, Password: string;
  IncludeCapability: Boolean): string;
begin
  if IncludeCapability then
    Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
      '<tds:GetServices><tds:IncludeCapability>true</tds:IncludeCapability></tds:GetServices>',
      UserName, Password)
  else
    Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
      '<tds:GetServices><tds:IncludeCapability>false</tds:IncludeCapability></tds:GetServices>',
      UserName, Password);
end;

function ONVIFGetServices(const Addr, UserName, Password: string;
  IncludeCapability: Boolean): string;
begin
  ONVIFRequest(Addr, PrepareGetServicesRequest(UserName, Password, IncludeCapability), Result);
end;

function XMLServicesToCapabilities(const AXml, DeviceXAddr: string;
  var Capabilities: TONVIFCapabilities): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  E: TONVIFServiceEndpoint;
begin
  Capabilities := default(TONVIFCapabilities);
  Capabilities.DeviceXAddr := DeviceXAddr;
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetServicesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'Service') then
      Continue;
    E.Namespace := Node.FindChild('Namespace').Text;
    E.XAddr := Node.FindChild('XAddr').Text;
    E.ServiceType := ServiceTypeFromNamespace(E.Namespace);
    E.MajorVersion := 1;
    E.MinorVersion := 0;
    if E.XAddr <> '' then
      AppendService(Capabilities, E);
  end;
  Result := Length(Capabilities.Services) > 0;
end;

function PrepareGetSystemDateAndTimeRequest: string;
begin
  Result :=
    '<?xml version="1.0"?>' +
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ' + ONVIF_NS_DEVICE + '>' +
    '<soap:Body><tds:GetSystemDateAndTime/></soap:Body></soap:Envelope>';
end;

function ONVIFGetSystemDateAndTime(const Addr: string): string;
begin
  ONVIFRequest(Addr, PrepareGetSystemDateAndTimeRequest, Result);
end;

function XMLSystemDateAndTimeToDateTime(const AXml: string; var DateTime: TONVIFDateTime): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, UTC, T: IONVIFXmlNode;
begin
  DateTime := default(TONVIFDateTime);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetSystemDateAndTimeResponse');
  if Response = nil then
    Exit;
  Response := Response.FindChild('SystemDateAndTime');
  if Response = nil then
    Exit;
  DateTime.DateTimeType := Response.FindChild('DateTimeType').Text;
  DateTime.DaylightSavings := Response.FindChild('DaylightSavings').Text.ToBoolean;
  DateTime.TimeZone := Response.FindChild('TimeZone').FindChild('TZ').Text;
  UTC := Response.FindChild('UTCDateTime');
  if UTC <> nil then
  begin
    T := UTC.FindChild('Time');
    DateTime.UTCDateTime := EncodeDateTime(
      UTC.FindChild('Date').FindChild('Year').Text.ToInteger,
      UTC.FindChild('Date').FindChild('Month').Text.ToInteger,
      UTC.FindChild('Date').FindChild('Day').Text.ToInteger,
      T.FindChild('Hour').Text.ToInteger,
      T.FindChild('Minute').Text.ToInteger,
      T.FindChild('Second').Text.ToInteger, 0);
    Result := True;
  end;
end;

function PrepareSetSystemDateAndTimeRequest(const DateTime: TONVIFDateTime): string;
begin
  Result := Format(
    '<tds:SetSystemDateAndTime>' +
    '<tds:DateTimeType>%s</tds:DateTimeType>' +
    '<tds:DaylightSavings>%s</tds:DaylightSavings>' +
    '<tds:TimeZone><tt:TZ xmlns:tt="http://www.onvif.org/ver10/schema">%s</tt:TZ></tds:TimeZone>' +
    '<tds:UTCDateTime><tt:Time xmlns:tt="http://www.onvif.org/ver10/schema">' +
    '<tt:Hour>%d</tt:Hour><tt:Minute>%d</tt:Minute><tt:Second>%d</tt:Second></tt:Time>' +
    '<tt:Date><tt:Year>%d</tt:Year><tt:Month>%d</tt:Month><tt:Day>%d</tt:Day></tt:Date>' +
    '</tds:UTCDateTime></tds:SetSystemDateAndTime>',
    [DateTime.DateTimeType, IfThen(DateTime.DaylightSavings, 'true', 'false'),
     DateTime.TimeZone,
     HourOf(DateTime.UTCDateTime), MinuteOf(DateTime.UTCDateTime), SecondOf(DateTime.UTCDateTime),
     YearOf(DateTime.UTCDateTime), MonthOf(DateTime.UTCDateTime), DayOf(DateTime.UTCDateTime)]);
end;

function ONVIFSetSystemDateAndTime(const Addr, UserName, Password: string;
  const DateTime: TONVIFDateTime): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_DEVICE,
    PrepareSetSystemDateAndTimeRequest(DateTime), UserName, Password);
end;

function PrepareGetHostnameRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetHostname/>', UserName, Password);
end;

function ONVIFGetHostname(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetHostnameRequest(UserName, Password), Result);
end;

function XMLHostnameToHostname(const AXml: string; var Hostname: TONVIFHostnameInformation): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Info: IONVIFXmlNode;
begin
  Hostname := default(TONVIFHostnameInformation);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetHostnameResponse');
  if Response = nil then
    Exit;
  Info := Response.FindChild('HostnameInformation');
  if Info = nil then
    Exit;
  Hostname.FromDHCP := Info.FindChild('FromDHCP').Text.ToBoolean;
  Hostname.Name := Info.FindChild('Name').Text;
  Result := Hostname.Name <> '';
end;

function PrepareGetDNSRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetDNS/>', UserName, Password);
end;

function ONVIFGetDNS(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetDNSRequest(UserName, Password), Result);
end;

function XMLDNSToDNS(const AXml: string; var DNS: TONVIFDNSInformation): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Info, Node: IONVIFXmlNode;
  I: Integer;
begin
  DNS := default(TONVIFDNSInformation);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetDNSResponse');
  if Response = nil then
    Exit;
  Info := Response.FindChild('DNSInformation');
  if Info = nil then
    Exit;
  DNS.FromDHCP := Info.FindChild('FromDHCP').Text.ToBoolean;
  for I := 0 to Info.ChildCount - 1 do
  begin
    Node := Info.Children[I];
    if SameText(Node.LocalName, 'DNSManual') then
    begin
      SetLength(DNS.DNSManual, Length(DNS.DNSManual) + 1);
      DNS.DNSManual[High(DNS.DNSManual)] := Node.FindChild('IPv4Address').Text;
    end;
  end;
  Result := True;
end;

function PrepareGetUsersRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetUsers/>', UserName, Password);
end;

function ONVIFGetUsers(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetUsersRequest(UserName, Password), Result);
end;

function XMLUsersToUsers(const AXml: string; var Users: TONVIFUsers): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  U: TONVIFUser;
begin
  SetLength(Users, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetUsersResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'User') then
      Continue;
    U.Username := Node.FindChild('Username').Text;
    U.UserLevel := Node.FindChild('UserLevel').Text;
    SetLength(Users, Length(Users) + 1);
    Users[High(Users)] := U;
  end;
  Result := Length(Users) > 0;
end;

function PrepareCreateUsersRequest(const UserName, Password: string; const Users: TONVIFUsers): string;
var
  Body, UserXml: string;
  U: TONVIFUser;
begin
  Body := '<tds:CreateUsers>';
  for U in Users do
    UserXml := UserXml + Format(
      '<tds:User><tds:Username>%s</tds:Username><tds:Password>%s</tds:Password>' +
      '<tds:UserLevel>%s</tds:UserLevel></tds:User>',
      [U.Username, U.Password, U.UserLevel]);
  Result := Body + UserXml + '</tds:CreateUsers>';
end;

function ONVIFCreateUsers(const Addr, UserName, Password: string;
  const Users: TONVIFUsers): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_DEVICE,
    PrepareCreateUsersRequest(UserName, Password, Users), UserName, Password);
end;

function PrepareDeleteUsersRequest(const UserName, Password: string;
  const UserNames: TArray<string>): string;
var
  Body, Names: string;
  N: string;
begin
  Body := '<tds:DeleteUsers>';
  for N in UserNames do
    Names := Names + Format('<tds:Username>%s</tds:Username>', [N]);
  Result := Body + Names + '</tds:DeleteUsers>';
end;

function ONVIFDeleteUsers(const Addr, UserName, Password: string;
  const UserNames: TArray<string>): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_DEVICE,
    PrepareDeleteUsersRequest(UserName, Password, UserNames), UserName, Password);
end;

function PrepareGetNetworkInterfacesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetNetworkInterfaces/>', UserName, Password);
end;

function ONVIFGetNetworkInterfaces(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetNetworkInterfacesRequest(UserName, Password), Result);
end;

function XMLNetworkInterfacesToInterfaces(const AXml: string;
  var Interfaces: TONVIFNetworkInterfaces): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node, IPv4: IONVIFXmlNode;
  I: Integer;
  NI: TONVIFNetworkInterface;
begin
  SetLength(Interfaces, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetNetworkInterfacesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'NetworkInterfaces') then
      Continue;
    NI.token := Node.Attr['token'];
    NI.Enabled := Node.FindChild('Enabled').Text.ToBoolean;
    IPv4 := Node.FindChild('IPv4');
    if IPv4 <> nil then
    begin
      NI.FromDHCP := IPv4.FindChild('Config').FindChild('FromDHCP').Text.ToBoolean;
      NI.IPv4Address := IPv4.FindChild('Config').FindChild('Manual').FindChild('Address').Text;
      NI.IPv4PrefixLength := IPv4.FindChild('Config').FindChild('Manual').FindChild('PrefixLength').Text.ToInteger;
    end;
    SetLength(Interfaces, Length(Interfaces) + 1);
    Interfaces[High(Interfaces)] := NI;
  end;
  Result := Length(Interfaces) > 0;
end;

function PrepareGetScopesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_DEVICE,
    '<tds:GetScopes/>', UserName, Password);
end;

function ONVIFGetScopes(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetScopesRequest(UserName, Password), Result);
end;

function XMLScopesToScopes(const AXml: string; var Scopes: TONVIFScopes): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  S: TONVIFScope;
begin
  SetLength(Scopes, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetScopesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'Scopes') then
      Continue;
    S.ScopeDef := Node.FindChild('ScopeDef').Text;
    S.ScopeItem := Node.FindChild('ScopeItem').Text;
    SetLength(Scopes, Length(Scopes) + 1);
    Scopes[High(Scopes)] := S;
  end;
  Result := Length(Scopes) > 0;
end;

function PrepareSetScopesRequest(const UserName, Password: string; const Scopes: TONVIFScopes): string;
var
  Body, Items: string;
  S: TONVIFScope;
begin
  Body := '<tds:SetScopes>';
  for S in Scopes do
    Items := Items + Format('<tds:Scopes><tds:ScopeDef>%s</tds:ScopeDef><tds:ScopeItem>%s</tds:ScopeItem></tds:Scopes>',
      [S.ScopeDef, S.ScopeItem]);
  Result := Body + Items + '</tds:SetScopes>';
end;

function ONVIFSetScopes(const Addr, UserName, Password: string;
  const Scopes: TONVIFScopes): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_DEVICE,
    PrepareSetScopesRequest(UserName, Password, Scopes), UserName, Password);
end;

function PrepareSystemRebootRequest(const UserName, Password: string): string;
begin
  Result := '<tds:SystemReboot/>';
end;

function ONVIFSystemReboot(const Addr, UserName, Password: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_DEVICE,
    PrepareSystemRebootRequest(UserName, Password), UserName, Password);
end;

function DiscoverCapabilities(const DeviceXAddr, UserName, Password: string): TONVIFCapabilities;
var
  Xml: string;
  NormalizedAddr: string;
begin
  Result := default(TONVIFCapabilities);
  NormalizedAddr := NormalizeDeviceXAddr(DeviceXAddr);
  Result.DeviceXAddr := NormalizedAddr;
  Xml := ONVIFGetServices(NormalizedAddr, UserName, Password, False);
  if XMLServicesToCapabilities(Xml, NormalizedAddr, Result) then
    Exit;
  Xml := ONVIFGetCapabilities(NormalizedAddr, UserName, Password);
  XMLCapabilitiesToCapabilities(Xml, Result);
  if Result.DeviceXAddr = '' then
    Result.DeviceXAddr := NormalizedAddr;
end;

end.
