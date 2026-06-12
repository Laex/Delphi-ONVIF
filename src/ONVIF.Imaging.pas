unit ONVIF.Imaging;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_IMAGING = 'xmlns:timg="http://www.onvif.org/ver10/imaging/wsdl"';
  ONVIF_NS_IMAGING_SCHEMA = 'xmlns:tt="http://www.onvif.org/ver10/schema"';

function PrepareGetImagingSettingsRequest(const UserName, Password, VideoSourceToken: string): string;
function ONVIFGetImagingSettings(const Addr, UserName, Password, VideoSourceToken: string): string;
function XMLImagingSettingsToSettings(const AXml: string; var Settings: TImagingSettings): Boolean;

function PrepareSetImagingSettingsRequest(const UserName, Password, VideoSourceToken: string;
  const Settings: TImagingSettings; ForcePersistence: Boolean): string;
function ONVIFSetImagingSettings(const Addr, UserName, Password, VideoSourceToken: string;
  const Settings: TImagingSettings; ForcePersistence: Boolean = True): TONVIFRequestResult;

function PrepareGetOptionsRequest(const UserName, Password, VideoSourceToken: string): string;
function ONVIFGetImagingOptions(const Addr, UserName, Password, VideoSourceToken: string): string;
function XMLImagingOptionsToOptions(const AXml: string; var Options: TImagingOptions): Boolean;

function PrepareImagingMoveRequest(const UserName, Password, VideoSourceToken: string;
  Focus: Real): string;
function ONVIFImagingMove(const Addr, UserName, Password, VideoSourceToken: string;
  Focus: Real): TONVIFRequestResult;

function PrepareImagingStopRequest(const UserName, Password, VideoSourceToken: string): string;
function ONVIFImagingStop(const Addr, UserName, Password, VideoSourceToken: string): TONVIFRequestResult;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  ONVIF.Core,
  ONVIF.Xml;

function PrepareGetImagingSettingsRequest(const UserName, Password, VideoSourceToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_IMAGING,
    Format('<timg:GetImagingSettings><timg:VideoSourceToken>%s</timg:VideoSourceToken></timg:GetImagingSettings>',
      [VideoSourceToken]), UserName, Password);
end;

function ONVIFGetImagingSettings(const Addr, UserName, Password, VideoSourceToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetImagingSettingsRequest(UserName, Password, VideoSourceToken), Result);
end;

function XMLImagingSettingsToSettings(const AXml: string; var Settings: TImagingSettings): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Img: IONVIFXmlNode;
  FormatSettings: TFormatSettings;
begin
  Settings := default(TImagingSettings);
  Result := False;
  FormatSettings := TFormatSettings.Invariant;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetImagingSettingsResponse');
  if Response = nil then
    Exit;
  Img := Response.FindChild('ImagingSettings');
  if Img = nil then
    Exit;
  Settings.Brightness := StrToFloatDef(Img.FindChild('Brightness').Text, 0, FormatSettings);
  Settings.Contrast := StrToFloatDef(Img.FindChild('Contrast').Text, 0, FormatSettings);
  Settings.ColorSaturation := StrToFloatDef(Img.FindChild('ColorSaturation').Text, 0, FormatSettings);
  Settings.Sharpness := StrToFloatDef(Img.FindChild('Sharpness').Text, 0, FormatSettings);
  Result := True;
end;

function PrepareSetImagingSettingsRequest(const UserName, Password, VideoSourceToken: string;
  const Settings: TImagingSettings; ForcePersistence: Boolean): string;
begin
  Result := Format('<timg:SetImagingSettings><timg:VideoSourceToken>%s</timg:VideoSourceToken>' +
    '<timg:ImagingSettings><tt:Brightness>%.2f</tt:Brightness><tt:ColorSaturation>%.2f</tt:ColorSaturation>' +
    '<tt:Contrast>%.2f</tt:Contrast><tt:Sharpness>%.2f</tt:Sharpness></timg:ImagingSettings>' +
    '<timg:ForcePersistence>%s</timg:ForcePersistence></timg:SetImagingSettings>',
    [VideoSourceToken, Settings.Brightness, Settings.ColorSaturation, Settings.Contrast,
     Settings.Sharpness, IfThen(ForcePersistence, 'true', 'false')]);
end;

function ONVIFSetImagingSettings(const Addr, UserName, Password, VideoSourceToken: string;
  const Settings: TImagingSettings; ForcePersistence: Boolean): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_IMAGING + ' ' + ONVIF_NS_IMAGING_SCHEMA,
    PrepareSetImagingSettingsRequest(UserName, Password, VideoSourceToken, Settings, ForcePersistence),
    UserName, Password);
end;

function PrepareGetOptionsRequest(const UserName, Password, VideoSourceToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_IMAGING,
    Format('<timg:GetOptions><timg:VideoSourceToken>%s</timg:VideoSourceToken></timg:GetOptions>',
      [VideoSourceToken]), UserName, Password);
end;

function ONVIFGetImagingOptions(const Addr, UserName, Password, VideoSourceToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetOptionsRequest(UserName, Password, VideoSourceToken), Result);
end;

function XMLImagingOptionsToOptions(const AXml: string; var Options: TImagingOptions): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Brightness: IONVIFXmlNode;
  FormatSettings: TFormatSettings;
begin
  Options := default(TImagingOptions);
  Result := False;
  FormatSettings := TFormatSettings.Invariant;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetOptionsResponse');
  if Response = nil then
    Exit;
  Brightness := Response.FindChild('ImagingOptions').FindChild('Brightness');
  if Brightness <> nil then
  begin
    Options.BrightnessMin := StrToFloatDef(Brightness.FindChild('Min').Text, 0, FormatSettings);
    Options.BrightnessMax := StrToFloatDef(Brightness.FindChild('Max').Text, 0, FormatSettings);
    Result := True;
  end;
end;

function PrepareImagingMoveRequest(const UserName, Password, VideoSourceToken: string;
  Focus: Real): string;
begin
  Result := Format('<timg:Move><timg:VideoSourceToken>%s</timg:VideoSourceToken>' +
    '<timg:Focus><tt:Absolute><tt:Position>%.4f</tt:Position></tt:Absolute></timg:Focus></timg:Move>',
    [VideoSourceToken, Focus]);
end;

function ONVIFImagingMove(const Addr, UserName, Password, VideoSourceToken: string;
  Focus: Real): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_IMAGING + ' ' + ONVIF_NS_IMAGING_SCHEMA,
    PrepareImagingMoveRequest(UserName, Password, VideoSourceToken, Focus),
    UserName, Password);
end;

function PrepareImagingStopRequest(const UserName, Password, VideoSourceToken: string): string;
begin
  Result := Format('<timg:Stop><timg:VideoSourceToken>%s</timg:VideoSourceToken></timg:Stop>',
    [VideoSourceToken]);
end;

function ONVIFImagingStop(const Addr, UserName, Password, VideoSourceToken: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_IMAGING + ' ' + ONVIF_NS_IMAGING_SCHEMA,
    PrepareImagingStopRequest(UserName, Password, VideoSourceToken),
    UserName, Password);
end;

end.
