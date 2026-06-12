unit ONVIF.Core;

interface

uses
  System.SysUtils,
  System.Classes,
  ONVIF.Types;

procedure ONVIFRequest(const Addr: string; const InStream, OutStream: TStringStream); overload;
procedure ONVIFRequest(const Addr, Request: string; var Answer: string); overload;

procedure GetONVIFPasswordDigest(const UserName, Password: string;
  var PasswordDigest, Nonce, Created: string);
function GetONVIFDateTime(const DateTime: TDateTime): string;
function BytesToString(Data: TBytes): string;
function StringToBytes(const AData: string): TBytes;
function SHA1(const Data: TBytes): TBytes;

function BuildAuthenticatedSoapEnvelope(const AEnvelopeNs, ABodyXml: string;
  const UserName, Password: string): string;

function GetONVIFAddr(const XAddr: string; const ONVIFAddrType: TONVIFAddrType): string;
function NormalizeDeviceXAddr(const HostOrUrl: string): string;
function ParseIPv4Address(const S: string; out A, B, C, D: Byte): Boolean;

function GetSnapshot(const SnapshotUri: string; const Stream: TStream): Boolean; overload;
function GetSnapshot(const SnapshotUri, UserName, Password: string;
  const Stream: TStream; out ContentType: string): Boolean; overload;

function XMLToProbeMatch(const ProbeMatchXML: string; var ProbeMatch: TProbeMatch): Boolean;
function UniqueProbeMatch(const ProbeMatch: TProbeMatchArray): TProbeMatchArray;

function ParseMediaUriResponse(const AXml, AResponseTag: string;
  var MediaUri: TStreamUri): Boolean;

function ParseSoapFault(const AXml: string): TONVIFSoapFault;
function SoapHasFault(const AXml: string): Boolean;
function ParseSoapResponse(const AXml: string; out ABodyXml: string): Boolean;
function ExecuteSoapRequest(const Addr, EnvelopeNs, BodyXml, UserName, Password: string): TONVIFRequestResult;

function XMLToProbeMatches(const ProbeMatchXML: string): TProbeMatchArray;

var
  ONVIFDebugLogSoap: Boolean = False;

implementation

uses
  System.Generics.Defaults,
  System.Generics.Collections,
  System.NetEncoding,
  IdHashSHA,
  IdHTTP,
  IdURI,
  IdGlobal,
  IdAuthenticationDigest,
  ONVIF.Xml;

const
  onvifDeviceService = 'device_service';
  onvifMedia = 'media';

  SoapSecurityHeaderFmt =
    '<soap:Header>' +
    '<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" soap:mustUnderstand="1">' +
    '<UsernameToken>' +
    '<Username>%s</Username>' +
    '<Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">%s</Password>' +
    '<Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">%s</Nonce>' +
    '<Created xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">%s</Created>' +
    '</UsernameToken>' +
    '</Security>' +
    '</soap:Header>';

function BytesToString(Data: TBytes): string;
var
  S: AnsiString;
begin
  SetLength(S, Length(Data));
  if Length(Data) > 0 then
    Move(Data[0], S[1], Length(Data));
  Result := string(S);
end;

function StringToBytes(const AData: string): TBytes;
var
  S: AnsiString;
begin
  S := AnsiString(AData);
  SetLength(Result, Length(S));
  if Length(S) > 0 then
    Move(S[1], Result[0], Length(S));
end;

function SHA1(const Data: TBytes): TBytes;
var
  Hash: TIdHashSHA1;
  Input, Output: TIdBytes;
begin
  Hash := TIdHashSHA1.Create;
  try
    SetLength(Input, Length(Data));
    if Length(Data) > 0 then
      Move(Data[0], Input[0], Length(Data));
    Output := Hash.HashBytes(Input);
    SetLength(Result, Length(Output));
    if Length(Output) > 0 then
      Move(Output[0], Result[0], Length(Output));
  finally
    Hash.Free;
  end;
end;

procedure GetONVIFPasswordDigest(const UserName, Password: string;
  var PasswordDigest, Nonce, Created: string);
var
  I: Integer;
  RawNonce, EncodedNonce, Digest: TBytes;
  RawDigest: TBytes;
begin
  SetLength(RawNonce, 20);
  for I := 0 to High(RawNonce) do
    RawNonce[I] := Random(256);
  EncodedNonce := TNetEncoding.Base64.Encode(RawNonce);
  Nonce := BytesToString(EncodedNonce);
  Created := GetONVIFDateTime(Now);
  RawDigest := SHA1(RawNonce + StringToBytes(Created) + StringToBytes(Password));
  Digest := TNetEncoding.Base64.Encode(RawDigest);
  PasswordDigest := BytesToString(Digest);
end;

function GetONVIFDateTime(const DateTime: TDateTime): string;
var
  FormattedDate, FormattedTime: string;
begin
  DateTimeToString(FormattedDate, 'yyyy-mm-dd', DateTime);
  DateTimeToString(FormattedTime, 'hh:nn:ss.zzz', DateTime);
  Result := FormattedDate + 'T' + FormattedTime + 'Z';
end;

function BuildAuthenticatedSoapEnvelope(const AEnvelopeNs, ABodyXml: string;
  const UserName, Password: string): string;
var
  PasswordDigest, Nonce, Created: string;
  Header: string;
begin
  GetONVIFPasswordDigest(UserName, Password, PasswordDigest, Nonce, Created);
  Header := Format(SoapSecurityHeaderFmt, [UserName, PasswordDigest, Nonce, Created]);
  Result :=
    '<?xml version="1.0"?>' +
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ' + AEnvelopeNs + '>' +
    Header +
    '<soap:Body>' + ABodyXml + '</soap:Body>' +
    '</soap:Envelope>';
end;

function GetONVIFAddr(const XAddr: string; const ONVIFAddrType: TONVIFAddrType): string;
var
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

function ParseIPv4Address(const S: string; out A, B, C, D: Byte): Boolean;
var
  Parts: TArray<string>;
  I, V: Integer;
begin
  Result := False;
  Parts := S.Split(['.']);
  if Length(Parts) <> 4 then
    Exit;
  for I := 0 to 3 do
  begin
    if not TryStrToInt(Trim(Parts[I]), V) or (V < 0) or (V > 255) then
      Exit;
    case I of
      0: A := Byte(V);
      1: B := Byte(V);
      2: C := Byte(V);
      3: D := Byte(V);
    end;
  end;
  Result := True;
end;

function NormalizeDeviceXAddr(const HostOrUrl: string): string;
var
  S: string;
  A, B, C, D: Byte;
begin
  S := Trim(HostOrUrl);
  if S = '' then
    Exit('');
  if S.StartsWith('http://', True) or S.StartsWith('https://', True) then
  begin
    if S.Contains('/onvif', True) or S.Contains('device_service', True) then
      Exit(S);
    Result := GetONVIFAddr(S, atDeviceService);
    Exit;
  end;
  if ParseIPv4Address(S, A, B, C, D) then
    Result := Format('http://%d.%d.%d.%d/onvif/device_service', [A, B, C, D])
  else
    Result := GetONVIFAddr('http://' + S, atDeviceService);
end;

procedure ConfigureIdHttp(AHttp: TIdHTTP; const AUri: TIdURI);
begin
  AHttp.AllowCookies := True;
  AHttp.HandleRedirects := True;
  AHttp.Request.Accept := '';
  AHttp.Request.UserAgent := '';
  AHttp.Request.Host := '';
  AHttp.Request.Connection := '';
  AHttp.Request.CustomHeaders.Clear;
  AHttp.Request.ContentType := 'text/xml;charset=utf-8';
  AHttp.Request.CustomHeaders.Add('Host: ' + AUri.Host);
  AHttp.ProtocolVersion := pv1_1;
  AHttp.HTTPOptions := [hoNoProtocolErrorException, hoWantProtocolErrorContent];
end;

procedure ONVIFRequest(const Addr: string; const InStream, OutStream: TStringStream);
var
  Http: TIdHTTP;
  Uri: TIdURI;
begin
  Http := TIdHTTP.Create;
  Uri := TIdURI.Create(Addr);
  try
    ConfigureIdHttp(Http, Uri);
    if ONVIFDebugLogSoap then
      InStream.Position := 0;
    Http.Post(Addr, InStream, OutStream);
  finally
    Uri.Free;
    Http.Free;
  end;
end;

function ParseSoapFault(const AXml: string): TONVIFSoapFault;
var
  Doc: IONVIFXmlDocument;
  Body, FaultNode, Node: IONVIFXmlNode;
begin
  Result := default(TONVIFSoapFault);
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  FaultNode := Body.FindChild('Fault');
  if FaultNode = nil then
    Exit;
  Node := FaultNode.FindChild('Code');
  if Node <> nil then
  begin
    Result.Code := Node.FindChild('Value').Text;
    Node := Node.FindChild('Subcode');
    if Node <> nil then
      Result.Subcode := Node.FindChild('Value').Text;
  end;
  Node := FaultNode.FindChild('Reason');
  if Node <> nil then
    Result.Reason := Node.FindChild('Text').Text;
  Node := FaultNode.FindChild('Detail');
  if Node <> nil then
    Result.Detail := Node.Text;
end;

function SoapHasFault(const AXml: string): Boolean;
begin
  Result := ParseSoapFault(AXml).HasFault;
end;

function ParseSoapResponse(const AXml: string; out ABodyXml: string): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body: IONVIFXmlNode;
begin
  ABodyXml := '';
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  if Body.FindChild('Fault') <> nil then
    Exit;
  ABodyXml := AXml;
  Result := True;
end;

function ExecuteSoapRequest(const Addr, EnvelopeNs, BodyXml, UserName, Password: string): TONVIFRequestResult;
var
  Request, Answer: string;
  Http: TIdHTTP;
  Uri: TIdURI;
  InStream, OutStream: TStringStream;
begin
  Result := default(TONVIFRequestResult);
  Request := BuildAuthenticatedSoapEnvelope(EnvelopeNs, BodyXml, UserName, Password);
  InStream := TStringStream.Create(Request, TEncoding.UTF8);
  OutStream := TStringStream.Create('', TEncoding.UTF8);
  Http := TIdHTTP.Create;
  Uri := TIdURI.Create(Addr);
  try
    ConfigureIdHttp(Http, Uri);
    Http.Post(Addr, InStream, OutStream);
    Result.HttpCode := Http.ResponseCode;
    Result.RawXml := OutStream.DataString;
    Result.Fault := ParseSoapFault(Result.RawXml);
    Result.Success := (Result.HttpCode = 200) and not Result.Fault.HasFault
      and ParseSoapResponse(Result.RawXml, Result.BodyXml);
  finally
    Uri.Free;
    Http.Free;
    InStream.Free;
    OutStream.Free;
  end;
end;

procedure ONVIFRequest(const Addr, Request: string; var Answer: string);
var
  InStream, OutStream: TStringStream;
begin
  InStream := TStringStream.Create(Request, TEncoding.UTF8);
  OutStream := TStringStream.Create('', TEncoding.UTF8);
  try
    ONVIFRequest(Addr, InStream, OutStream);
    Answer := OutStream.DataString;
  finally
    InStream.Free;
    OutStream.Free;
  end;
end;

function GetSnapshot(const SnapshotUri: string; const Stream: TStream): Boolean;
var
  Http: TIdHTTP;
  Uri: TIdURI;
begin
  Http := TIdHTTP.Create;
  Uri := TIdURI.Create(SnapshotUri);
  try
    ConfigureIdHttp(Http, Uri);
    Http.Get(SnapshotUri, Stream);
    Result := Http.ResponseCode = 200;
  finally
    Uri.Free;
    Http.Free;
  end;
end;

function GetSnapshot(const SnapshotUri, UserName, Password: string;
  const Stream: TStream; out ContentType: string): Boolean;
var
  Http: TIdHTTP;
  Uri: TIdURI;
  Auth: TIdDigestAuthentication;
begin
  Auth := TIdDigestAuthentication.Create;
  Http := TIdHTTP.Create;
  Uri := TIdURI.Create(SnapshotUri);
  try
    Http.Request.Authentication := Auth;
    Auth := nil;
    Http.Request.Username := UserName;
    Http.Request.Password := Password;
    ConfigureIdHttp(Http, Uri);
    Http.Get(Uri.URI, Stream);
    ContentType := Http.Response.ContentType;
    Result := Http.ResponseCode = 200;
  finally
    Auth.Free;
    Uri.Free;
    Http.Free;
  end;
end;

function ParseMediaUriResponse(const AXml, AResponseTag: string;
  var MediaUri: TStreamUri): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, MediaUriNode, Node: IONVIFXmlNode;
begin
  MediaUri := default(TStreamUri);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild(AResponseTag);
  if Response = nil then
    Exit;
  MediaUriNode := Response.FindChild('MediaUri');
  if MediaUriNode = nil then
    Exit;
  Node := MediaUriNode.FindChild('Uri');
  if Node <> nil then
  begin
    MediaUri.Uri := Node.Text;
    Result := True;
  end;
  Node := MediaUriNode.FindChild('InvalidAfterConnect');
  if Node <> nil then
  begin
    MediaUri.InvalidAfterConnect := Node.Text.ToBoolean;
    Result := True;
  end;
  Node := MediaUriNode.FindChild('InvalidAfterReboot');
  if Node <> nil then
  begin
    MediaUri.InvalidAfterReboot := Node.Text.ToBoolean;
    Result := True;
  end;
  Node := MediaUriNode.FindChild('Timeout');
  if Node <> nil then
  begin
    MediaUri.Timeout := Node.Text;
    Result := True;
  end;
end;

function ParseProbeMatchNode(const ProbeMatchNode: IONVIFXmlNode;
  const ProbeMatchXML: string; var ProbeMatch: TProbeMatch): Boolean;
var
  Node: IONVIFXmlNode;
  S, Token, LocalName: string;
  I, P: Integer;

  procedure IncludeTypeToken(const AToken: string);
  begin
    LocalName := AToken;
    P := Pos(':', LocalName);
    if P > 0 then
      LocalName := Copy(LocalName, P + 1, MaxInt);
    if SameText(LocalName, 'NetworkVideoTransmitter') then
      Include(ProbeMatch.Types, ptNetworkVideoTransmitter)
    else if SameText(LocalName, 'Device') then
      Include(ProbeMatch.Types, ptDevice)
    else if SameText(LocalName, 'NetworkVideoDisplay') then
      Include(ProbeMatch.Types, ptNetworkVideoDisplay);
  end;

begin
  ProbeMatch := default(TProbeMatch);
  Result := False;
  if ProbeMatchNode = nil then
    Exit;

  Node := ProbeMatchNode.FindChild('Types');
  if Node <> nil then
  begin
    S := Trim(Node.Text);
    while S <> '' do
    begin
      I := Pos(' ', S);
      if I > 0 then
      begin
        Token := Copy(S, 1, I - 1);
        Delete(S, 1, I);
        S := Trim(S);
      end
      else
      begin
        Token := S;
        S := '';
      end;
      IncludeTypeToken(Token);
    end;
    Result := True;
  end;

  Node := ProbeMatchNode.FindChild('Scopes');
  if Node <> nil then
  begin
    S := Trim(Node.Text);
    while Length(S) > 0 do
    begin
      SetLength(ProbeMatch.Scopes, Length(ProbeMatch.Scopes) + 1);
      I := Pos(' ', S);
      if I > 0 then
      begin
        ProbeMatch.Scopes[High(ProbeMatch.Scopes)] := Copy(S, 1, I - 1);
        Delete(S, 1, I);
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

  Node := ProbeMatchNode.FindChild('XAddrs');
  if Node <> nil then
  begin
    S := Trim(Node.Text);
    while (S <> '') and (S[1] = ' ') do
      Delete(S, 1, 1);
    I := Pos(' ', S);
    if I > 0 then
    begin
      ProbeMatch.XAddrs := Copy(S, 1, I - 1);
      ProbeMatch.XAddrsV6 := Trim(Copy(S, I + 1, MaxInt));
      if ProbeMatch.XAddrsV6.StartsWith('http', True) and
         ProbeMatch.XAddrs.StartsWith('http', True) then
      begin
        if ProbeMatch.XAddrs.Contains(':') and ProbeMatch.XAddrsV6.Contains('.') then
        begin
          if Length(ProbeMatch.XAddrs) < Length(ProbeMatch.XAddrsV6) then
          begin
            S := ProbeMatch.XAddrs;
            ProbeMatch.XAddrs := ProbeMatch.XAddrsV6;
            ProbeMatch.XAddrsV6 := S;
          end;
        end;
      end;
    end
    else
      ProbeMatch.XAddrs := S;
    Result := True;
  end;

  Node := ProbeMatchNode.FindChild('MetadataVersion');
  if Node <> nil then
  begin
    ProbeMatch.MetadataVersion := StrToIntDef(Node.Text, 0);
    Result := True;
  end;
end;

function XMLToProbeMatch(const ProbeMatchXML: string; var ProbeMatch: TProbeMatch): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, ProbeMatches, ProbeMatchNode: IONVIFXmlNode;
begin
  Result := False;
  ProbeMatch := default(TProbeMatch);
  Doc := LoadONVIFXml(ProbeMatchXML);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  ProbeMatches := Body.FindChild('ProbeMatches');
  if ProbeMatches = nil then
    Exit;
  ProbeMatchNode := ProbeMatches.FindChild('ProbeMatch');
  Result := ParseProbeMatchNode(ProbeMatchNode, ProbeMatchXML, ProbeMatch);
end;

function XMLToProbeMatches(const ProbeMatchXML: string): TProbeMatchArray;
var
  Doc: IONVIFXmlDocument;
  Body, ProbeMatches, ProbeMatchNode: IONVIFXmlNode;
  I: Integer;
  PM: TProbeMatch;
begin
  SetLength(Result, 0);
  Doc := LoadONVIFXml(ProbeMatchXML);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  ProbeMatches := Body.FindChild('ProbeMatches');
  if ProbeMatches = nil then
  begin
    if XMLToProbeMatch(ProbeMatchXML, PM) then
    begin
      SetLength(Result, 1);
      Result[0] := PM;
    end;
    Exit;
  end;
  for I := 0 to ProbeMatches.ChildCount - 1 do
  begin
    ProbeMatchNode := ProbeMatches.Children[I];
    if not SameText(ProbeMatchNode.LocalName, 'ProbeMatch') then
      Continue;
    if ParseProbeMatchNode(ProbeMatchNode, ProbeMatchXML, PM) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := PM;
    end;
  end;
end;

function UniqueProbeMatch(const ProbeMatch: TProbeMatchArray): TProbeMatchArray;
var
  ProbeMatchDic: TDictionary<string, TProbeMatch>;
  PM: TProbeMatch;
  Comparer: IComparer<TProbeMatch>;
begin
  ProbeMatchDic := TDictionary<string, TProbeMatch>.Create;
  try
    for PM in ProbeMatch do
      if not ProbeMatchDic.ContainsKey(PM.XAddrs) then
        ProbeMatchDic.Add(PM.XAddrs, PM);
    Result := ProbeMatchDic.Values.ToArray;
    Comparer := TDelegatedComparer<TProbeMatch>.Create(
      function(const Left, Right: TProbeMatch): Integer
      begin
        Result := AnsiCompareText(Left.XAddrs, Right.XAddrs);
      end);
    TArray.Sort<TProbeMatch>(Result, Comparer);
  finally
    ProbeMatchDic.Free;
  end;
end;

end.
