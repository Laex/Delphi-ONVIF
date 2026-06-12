unit ONVIF.Analytics;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_ANALYTICS = 'xmlns:tan="http://www.onvif.org/ver10/analytics/wsdl"';
  ONVIF_NS_ANALYTICS_SCHEMA = 'xmlns:tt="http://www.onvif.org/ver10/schema"';

function PrepareGetAnalyticsModulesRequest(const UserName, Password, ConfigurationToken: string): string;
function ONVIFGetAnalyticsModules(const Addr, UserName, Password, ConfigurationToken: string): string;
function XMLAnalyticsModulesToModules(const AXml: string; var Modules: TArray<TAnalyticsModule>): Boolean;

function PrepareGetRulesRequest(const UserName, Password, ConfigurationToken: string): string;
function ONVIFGetRules(const Addr, UserName, Password, ConfigurationToken: string): string;
function XMLRulesToRules(const AXml: string; var Rules: TArray<TRule>): Boolean;

function PrepareModifyAnalyticsModulesRequest(const UserName, Password, ConfigurationToken: string;
  const Modules: TArray<TAnalyticsModule>): string;
function ONVIFModifyAnalyticsModules(const Addr, UserName, Password, ConfigurationToken: string;
  const Modules: TArray<TAnalyticsModule>): TONVIFRequestResult;

function PrepareModifyRulesRequest(const UserName, Password, ConfigurationToken: string;
  const Rules: TArray<TRule>): string;
function ONVIFModifyRules(const Addr, UserName, Password, ConfigurationToken: string;
  const Rules: TArray<TRule>): TONVIFRequestResult;

implementation

uses
  System.SysUtils,
  ONVIF.Core,
  ONVIF.Xml;

function PrepareGetAnalyticsModulesRequest(const UserName, Password, ConfigurationToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_ANALYTICS,
    Format('<tan:GetAnalyticsModules><tan:ConfigurationToken>%s</tan:ConfigurationToken></tan:GetAnalyticsModules>',
      [ConfigurationToken]), UserName, Password);
end;

function ONVIFGetAnalyticsModules(const Addr, UserName, Password, ConfigurationToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetAnalyticsModulesRequest(UserName, Password, ConfigurationToken), Result);
end;

function XMLAnalyticsModulesToModules(const AXml: string; var Modules: TArray<TAnalyticsModule>): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  A: TAnalyticsModule;
begin
  SetLength(Modules, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetAnalyticsModulesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'AnalyticsModule') then
      Continue;
    A := default(TAnalyticsModule);
    A.Type_ := Node.Attr['Type'];
    A.Name := Node.Attr['Name'];
    SetLength(Modules, Length(Modules) + 1);
    Modules[High(Modules)] := A;
  end;
  Result := Length(Modules) > 0;
end;

function PrepareGetRulesRequest(const UserName, Password, ConfigurationToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_ANALYTICS,
    Format('<tan:GetRules><tan:ConfigurationToken>%s</tan:ConfigurationToken></tan:GetRules>',
      [ConfigurationToken]), UserName, Password);
end;

function ONVIFGetRules(const Addr, UserName, Password, ConfigurationToken: string): string;
begin
  ONVIFRequest(Addr, PrepareGetRulesRequest(UserName, Password, ConfigurationToken), Result);
end;

function XMLRulesToRules(const AXml: string; var Rules: TArray<TRule>): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  R: TRule;
begin
  SetLength(Rules, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetRulesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'Rule') then
      Continue;
    R := default(TRule);
    R.Type_ := Node.Attr['Type'];
    R.Name := Node.Attr['Name'];
    SetLength(Rules, Length(Rules) + 1);
    Rules[High(Rules)] := R;
  end;
  Result := Length(Rules) > 0;
end;

function PrepareModifyAnalyticsModulesRequest(const UserName, Password, ConfigurationToken: string;
  const Modules: TArray<TAnalyticsModule>): string;
var
  Body, ModXml: string;
  A: TAnalyticsModule;
begin
  Body := Format('<tan:ModifyAnalyticsModules><tan:ConfigurationToken>%s</tan:ConfigurationToken>',
    [ConfigurationToken]);
  for A in Modules do
    ModXml := ModXml + Format('<tan:AnalyticsModule Name="%s" Type="%s"/>', [A.Name, A.Type_]);
  Result := Body + ModXml + '</tan:ModifyAnalyticsModules>';
end;

function ONVIFModifyAnalyticsModules(const Addr, UserName, Password, ConfigurationToken: string;
  const Modules: TArray<TAnalyticsModule>): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_ANALYTICS + ' ' + ONVIF_NS_ANALYTICS_SCHEMA,
    PrepareModifyAnalyticsModulesRequest(UserName, Password, ConfigurationToken, Modules),
    UserName, Password);
end;

function PrepareModifyRulesRequest(const UserName, Password, ConfigurationToken: string;
  const Rules: TArray<TRule>): string;
var
  Body, RuleXml: string;
  R: TRule;
begin
  Body := Format('<tan:ModifyRules><tan:ConfigurationToken>%s</tan:ConfigurationToken>',
    [ConfigurationToken]);
  for R in Rules do
    RuleXml := RuleXml + Format('<tan:Rule Name="%s" Type="%s"/>', [R.Name, R.Type_]);
  Result := Body + RuleXml + '</tan:ModifyRules>';
end;

function ONVIFModifyRules(const Addr, UserName, Password, ConfigurationToken: string;
  const Rules: TArray<TRule>): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(Addr, ONVIF_NS_ANALYTICS + ' ' + ONVIF_NS_ANALYTICS_SCHEMA,
    PrepareModifyRulesRequest(UserName, Password, ConfigurationToken, Rules),
    UserName, Password);
end;

end.
