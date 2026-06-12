unit ONVIF.PTZ;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_PTZ = 'xmlns:tptz="http://www.onvif.org/ver10/ptz/wsdl"';
  ONVIF_NS_PTZ_SCHEMA = 'xmlns:tt="http://www.onvif.org/ver10/schema"';

function PrepareGetConfigurationsRequest(const UserName, Password: string): string;
function ONVIFPTZGetConfigurations(const Addr, UserName, Password: string): string;
function XMLPTZConfigurationsToConfigurations(const AXml: string;
  var Configurations: TPTZConfigurations): Boolean;

function PrepareContinuousMoveRequest(const UserName, Password, ProfileToken: string;
  const Velocity: TPTZVector; ATimeout: string): string;
function ONVIFPTZContinuousMove(const Addr, UserName, Password, ProfileToken: string;
  const Velocity: TPTZVector; ATimeout: string = 'PT5S'): TONVIFRequestResult;

function PrepareStopRequest(const UserName, Password, ProfileToken: string;
  PanTilt, Zoom: Boolean): string;
function ONVIFPTZStop(const Addr, UserName, Password, ProfileToken: string;
  PanTilt: Boolean = True; Zoom: Boolean = True): TONVIFRequestResult;

function PrepareGetStatusRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFPTZGetStatus(const Addr, UserName, Password, ProfileToken: string): string;
function XMLPTZStatusToStatus(const AXml: string; var Status: TPTZStatus): Boolean;

function PrepareGetPresetsRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFPTZGetPresets(const Addr, UserName, Password, ProfileToken: string): string;
function XMLPTZPresetsToPresets(const AXml: string; var Presets: TPTZPresets): Boolean;

function PrepareSetPresetRequest(const UserName, Password, ProfileToken, PresetName: string): string;
function ONVIFPTZSetPreset(const Addr, UserName, Password, ProfileToken, PresetName: string;
  out PresetToken: string): TONVIFRequestResult;

function PrepareGotoPresetRequest(const UserName, Password, ProfileToken, PresetToken: string): string;
function ONVIFPTZGotoPreset(const Addr, UserName, Password, ProfileToken,
  PresetToken: string): TONVIFRequestResult;

function PrepareGotoHomePositionRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFPTZGotoHomePosition(const Addr, UserName, Password,
  ProfileToken: string): TONVIFRequestResult;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  ONVIF.Core,
  ONVIF.Xml;

function PrepareGetConfigurationsRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_PTZ,
    '<tptz:GetConfigurations/>', UserName, Password);
end;

function ONVIFPTZGetConfigurations(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetConfigurationsRequest(UserName, Password), Result);
end;

function XMLPTZConfigurationsToConfigurations(const AXml: string;
  var Configurations: TPTZConfigurations): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  C: TPTZConfiguration;
begin
  SetLength(Configurations, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetConfigurationsResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'PTZConfiguration') then
      Continue;
    C.token := Node.Attr['token'];
    C.Name := Node.FindChild('Name').Text;
    C.NodeToken := Node.FindChild('NodeToken').Text;
    SetLength(Configurations, Length(Configurations) + 1);
    Configurations[High(Configurations)] := C;
  end;
  Result := Length(Configurations) > 0;
end;

function PrepareContinuousMoveRequest(const UserName, Password, ProfileToken: string;
  const Velocity: TPTZVector; ATimeout: string): string;
begin
  Result := Format('<tptz:ContinuousMove><tptz:ProfileToken>%s</tptz:ProfileToken>' +
    '<tptz:Velocity><tt:PanTilt x="%.4f" y="%.4f"/><tt:Zoom x="%.4f"/></tptz:Velocity>' +
    '<tptz:Timeout>%s</tptz:Timeout></tptz:ContinuousMove>',
    [ProfileToken, Velocity.Pan, Velocity.Tilt, Velocity.Zoom, ATimeout]);
end;

function ONVIFPTZContinuousMove(const Addr, UserName, Password, ProfileToken: string;
  const Velocity: TPTZVector; ATimeout: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_PTZ + ' ' + ONVIF_NS_PTZ_SCHEMA,
    PrepareContinuousMoveRequest(UserName, Password, ProfileToken, Velocity, ATimeout),
    UserName, Password);
end;

function XmlBoolean(const Value: Boolean): string;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;

function PrepareStopRequest(const UserName, Password, ProfileToken: string;
  PanTilt, Zoom: Boolean): string;
begin
  Result := Format('<tptz:Stop><tptz:ProfileToken>%s</tptz:ProfileToken>' +
    '<tptz:PanTilt>%s</tptz:PanTilt><tptz:Zoom>%s</tptz:Zoom></tptz:Stop>',
    [ProfileToken, XmlBoolean(PanTilt), XmlBoolean(Zoom)]);
end;

function ONVIFPTZStop(const Addr, UserName, Password, ProfileToken: string;
  PanTilt, Zoom: Boolean): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_PTZ + ' ' + ONVIF_NS_PTZ_SCHEMA,
    PrepareStopRequest(UserName, Password, ProfileToken, PanTilt, Zoom),
    UserName, Password);
end;

function PrepareGetStatusRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_PTZ,
    Format('<tptz:GetStatus><tptz:ProfileToken>%s</tptz:ProfileToken></tptz:GetStatus>',
      [ProfileToken]), UserName, Password);
end;

function ONVIFPTZGetStatus(const Addr, UserName, Password, ProfileToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetStatusRequest(UserName, Password, ProfileToken), Result);
end;

function XMLPTZStatusToStatus(const AXml: string; var Status: TPTZStatus): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, PosNode, PT, Z, Node: IONVIFXmlNode;
  FormatSettings: TFormatSettings;
begin
  Status := default(TPTZStatus);
  Result := False;
  FormatSettings := TFormatSettings.Invariant;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetStatusResponse');
  if Response = nil then
    Exit;
  Response := Response.FindChild('PTZStatus');
  if Response = nil then
    Exit;
  PosNode := Response.FindChild('Position');
  if PosNode <> nil then
  begin
    PT := PosNode.FindChild('PanTilt');
    if PT <> nil then
    begin
      Status.Position.Pan := StrToFloatDef(PT.Attr['x'], 0, FormatSettings);
      Status.Position.Tilt := StrToFloatDef(PT.Attr['y'], 0, FormatSettings);
    end;
    Z := PosNode.FindChild('Zoom');
    if Z <> nil then
      Status.Position.Zoom := StrToFloatDef(Z.Attr['x'], 0, FormatSettings);
  end;
  Node := Response.FindChild('MoveStatus');
  if Node <> nil then
  begin
    Node := Node.FindChild('PanTilt');
    if Node <> nil then
      Status.MoveStatus := Node.Text;
  end;
  Status.UtcTime := Now;
  Result := True;
end;

function PrepareGetPresetsRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_PTZ,
    Format('<tptz:GetPresets><tptz:ProfileToken>%s</tptz:ProfileToken></tptz:GetPresets>',
      [ProfileToken]), UserName, Password);
end;

function ONVIFPTZGetPresets(const Addr, UserName, Password, ProfileToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetPresetsRequest(UserName, Password, ProfileToken), Result);
end;

function XMLPTZPresetsToPresets(const AXml: string; var Presets: TPTZPresets): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  P: TPTZPreset;
begin
  SetLength(Presets, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetPresetsResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'Preset') then
      Continue;
    P.token := Node.Attr['token'];
    P.Name := Node.FindChild('Name').Text;
    SetLength(Presets, Length(Presets) + 1);
    Presets[High(Presets)] := P;
  end;
  Result := Length(Presets) > 0;
end;

function PrepareSetPresetRequest(const UserName, Password, ProfileToken, PresetName: string): string;
begin
  Result := Format('<tptz:SetPreset><tptz:ProfileToken>%s</tptz:ProfileToken><tptz:PresetName>%s</tptz:PresetName></tptz:SetPreset>',
    [ProfileToken, PresetName]);
end;

function ONVIFPTZSetPreset(const Addr, UserName, Password, ProfileToken, PresetName: string;
  out PresetToken: string): TONVIFRequestResult;
var
  Doc: IONVIFXmlDocument;
  Body, Response: IONVIFXmlNode;
begin
  PresetToken := '';
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_PTZ + ' ' + ONVIF_NS_PTZ_SCHEMA,
    PrepareSetPresetRequest(UserName, Password, ProfileToken, PresetName),
    UserName, Password);
  if not Result.Success then
    Exit;
  Doc := LoadONVIFXml(Result.RawXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('SetPresetResponse');
  if Response <> nil then
    PresetToken := Response.FindChild('PresetToken').Text;
end;

function PrepareGotoPresetRequest(const UserName, Password, ProfileToken, PresetToken: string): string;
begin
  Result := Format('<tptz:GotoPreset><tptz:ProfileToken>%s</tptz:ProfileToken>' +
    '<tptz:PresetToken>%s</tptz:PresetToken></tptz:GotoPreset>',
    [ProfileToken, PresetToken]);
end;

function ONVIFPTZGotoPreset(const Addr, UserName, Password, ProfileToken,
  PresetToken: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_PTZ + ' ' + ONVIF_NS_PTZ_SCHEMA,
    PrepareGotoPresetRequest(UserName, Password, ProfileToken, PresetToken),
    UserName, Password);
end;

function PrepareGotoHomePositionRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := Format('<tptz:GotoHomePosition><tptz:ProfileToken>%s</tptz:ProfileToken></tptz:GotoHomePosition>',
    [ProfileToken]);
end;

function ONVIFPTZGotoHomePosition(const Addr, UserName, Password,
  ProfileToken: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_PTZ + ' ' + ONVIF_NS_PTZ_SCHEMA,
    PrepareGotoHomePositionRequest(UserName, Password, ProfileToken),
    UserName, Password);
end;

end.
