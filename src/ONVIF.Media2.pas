unit ONVIF.Media2;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_MEDIA2 = 'xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"';
  ONVIF_NS_SCHEMA2 = 'xmlns:tt="http://www.onvif.org/ver10/schema"';

function PrepareMedia2GetProfilesRequest(const UserName, Password: string): string;
function ONVIFMedia2GetProfiles(const Addr, UserName, Password: string): string;
function XMLMedia2ProfilesToProfiles(const AXml: string; var Profiles: TProfiles): Boolean;

function PrepareMedia2GetStreamUriRequest(const UserName, Password, Protocol,
  ProfileToken: string): string;
function ONVIFMedia2GetStreamUri(const Addr, UserName, Password, Protocol,
  ProfileToken: string): string;
function XMLMedia2StreamUriToStreamUri(const AXml: string; var StreamUri: TStreamUri): Boolean;

function PrepareMedia2GetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;
function ONVIFMedia2GetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
function XMLMedia2SnapshotUriToSnapshotUri(const AXml: string; var SnapshotUri: TSnapshotUri): Boolean;

function Media2GetProfilesWorks(const Addr, UserName, Password: string): Boolean;

implementation

uses
  System.SysUtils,
  ONVIF.Core,
  ONVIF.Media,
  ONVIF.Xml;

function PrepareMedia2GetProfilesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA2,
    '<tr2:GetProfiles/>', UserName, Password);
end;

function ONVIFMedia2GetProfiles(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareMedia2GetProfilesRequest(UserName, Password), Result);
end;

function XMLMedia2ProfilesToProfiles(const AXml: string; var Profiles: TProfiles): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  Profile: TProfile;
begin
  SetLength(Profiles, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  if Body.FindChild('Fault') <> nil then
    Exit;
  Response := Body.FindChild('GetProfilesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'Profiles') then
      Continue;
    Profile := default(TProfile);
    Profile.token := Node.Attr['token'];
    Profile.Name := Node.FindChild('Name').Text;
    Profile.fixed := Node.Attr['fixed'].ToBoolean;
    SetLength(Profiles, Length(Profiles) + 1);
    Profiles[High(Profiles)] := Profile;
  end;
  Result := True;
end;

function PrepareMedia2GetStreamUriRequest(const UserName, Password, Protocol,
  ProfileToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA2 + ' ' + ONVIF_NS_SCHEMA2,
    Format('<tr2:GetStreamUri><tr2:Protocol>%s</tr2:Protocol><tr2:ProfileToken>%s</tr2:ProfileToken></tr2:GetStreamUri>',
      [Protocol, ProfileToken]), UserName, Password);
end;

function ONVIFMedia2GetStreamUri(const Addr, UserName, Password, Protocol,
  ProfileToken: string): string;
begin
  ONVIFRequest(Addr, PrepareMedia2GetStreamUriRequest(UserName, Password, Protocol, ProfileToken), Result);
end;

function XMLMedia2StreamUriToStreamUri(const AXml: string; var StreamUri: TStreamUri): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
begin
  StreamUri := default(TStreamUri);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetStreamUriResponse');
  if Response = nil then
    Exit;
  Node := Response.FindChild('Uri');
  if Node <> nil then
  begin
    StreamUri.Uri := Node.Text;
    Result := True;
  end;
end;

function PrepareMedia2GetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_MEDIA2,
    Format('<tr2:GetSnapshotUri><tr2:ProfileToken>%s</tr2:ProfileToken></tr2:GetSnapshotUri>',
      [ProfileToken]), UserName, Password);
end;

function ONVIFMedia2GetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
begin
  ONVIFRequest(Addr, PrepareMedia2GetSnapshotUriRequest(UserName, Password, ProfileToken), Result);
end;

function XMLMedia2SnapshotUriToSnapshotUri(const AXml: string; var SnapshotUri: TSnapshotUri): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
begin
  SnapshotUri := default(TSnapshotUri);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetSnapshotUriResponse');
  if Response = nil then
    Exit;
  Node := Response.FindChild('Uri');
  if Node <> nil then
  begin
    SnapshotUri.Uri := Node.Text;
    Result := True;
  end;
end;

function Media2GetProfilesWorks(const Addr, UserName, Password: string): Boolean;
var
  Xml: string;
  Profiles: TProfiles;
begin
  Xml := ONVIFMedia2GetProfiles(Addr, UserName, Password);
  if SoapHasFault(Xml) then
    Exit(False);
  Result := XMLMedia2ProfilesToProfiles(Xml, Profiles);
end;

end.
