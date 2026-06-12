unit ONVIF.Xml;

{
  Thin XML abstraction for ONVIF SOAP responses.
  Current backend: Xml.VerySimple (src/ThirdParty).
  Replace the implementation section to swap parsers without touching ONVIF.Core/Services.
}

interface

uses
  System.SysUtils;

type
  IONVIFXmlNode = interface
    ['{A7B3C2E1-4F5D-4A8B-9C0D-1E2F3A4B5C6D}']
    function FindChild(const ALocalName: string): IONVIFXmlNode;
    function GetChild(AIndex: Integer): IONVIFXmlNode;
    function GetChildCount: Integer;
    function GetText: string;
    function GetAttribute(const AName: string): string;
    function HasAttribute(const AName: string): Boolean;
    function GetLocalName: string;
    property LocalName: string read GetLocalName;
    property ChildCount: Integer read GetChildCount;
    property Children[AIndex: Integer]: IONVIFXmlNode read GetChild;
    property Text: string read GetText;
    property Attr[const AName: string]: string read GetAttribute;
  end;

  IONVIFXmlDocument = interface
    ['{B8C4D3F2-5E6A-4B9C-0D1E-2F3A4B5C6D7E}']
    function GetRoot: IONVIFXmlNode;
    function GetSoapBody: IONVIFXmlNode;
    property Root: IONVIFXmlNode read GetRoot;
    property SoapBody: IONVIFXmlNode read GetSoapBody;
  end;

function LoadONVIFXml(const AXml: string): IONVIFXmlDocument;

implementation

uses
  System.Classes,
  Xml.VerySimple;

type
  TVerySimpleXmlNode = class;

  TVerySimpleXmlDocument = class(TInterfacedObject, IONVIFXmlDocument)
  private
    FXml: TXmlVerySimple;
    FRoot: IONVIFXmlNode;
  public
    constructor Create(const AXml: string);
    destructor Destroy; override;
    function GetRoot: IONVIFXmlNode;
    function GetSoapBody: IONVIFXmlNode;
  end;

  TVerySimpleXmlNode = class(TInterfacedObject, IONVIFXmlNode)
  private
    FDocument: IONVIFXmlDocument;
    FNode: TXmlNode;
  public
    constructor Create(ADocument: IONVIFXmlDocument; ANode: TXmlNode);
    function FindChild(const ALocalName: string): IONVIFXmlNode;
    function GetChild(AIndex: Integer): IONVIFXmlNode;
    function GetChildCount: Integer;
    function GetText: string;
    function GetAttribute(const AName: string): string;
    function HasAttribute(const AName: string): Boolean;
    function GetLocalName: string;
  end;

constructor TVerySimpleXmlDocument.Create(const AXml: string);
var
  SS: TStringStream;
begin
  inherited Create;
  FXml := TXmlVerySimple.Create;
  SS := TStringStream.Create(AXml);
  try
    FXml.LoadFromStream(SS);
    if FXml.DocumentElement <> nil then
      FRoot := TVerySimpleXmlNode.Create(Self, FXml.DocumentElement)
    else
      FRoot := nil;
  finally
    SS.Free;
  end;
end;

destructor TVerySimpleXmlDocument.Destroy;
begin
  FRoot := nil;
  FXml.Free;
  inherited;
end;

function TVerySimpleXmlDocument.GetRoot: IONVIFXmlNode;
begin
  Result := FRoot;
end;

function TVerySimpleXmlDocument.GetSoapBody: IONVIFXmlNode;
begin
  if FRoot = nil then
    Result := nil
  else
    Result := FRoot.FindChild('Body');
end;

constructor TVerySimpleXmlNode.Create(ADocument: IONVIFXmlDocument; ANode: TXmlNode);
begin
  inherited Create;
  FDocument := ADocument;
  FNode := ANode;
end;

function TVerySimpleXmlNode.FindChild(const ALocalName: string): IONVIFXmlNode;
var
  Child: TXmlNode;
begin
  Result := nil;
  if FNode = nil then
    Exit;
  Child := FNode.Find(ALocalName);
  if Child <> nil then
    Result := TVerySimpleXmlNode.Create(FDocument, Child);
end;

function TVerySimpleXmlNode.GetChild(AIndex: Integer): IONVIFXmlNode;
begin
  Result := nil;
  if (FNode = nil) or (AIndex < 0) or (AIndex >= FNode.ChildNodes.Count) then
    Exit;
  Result := TVerySimpleXmlNode.Create(FDocument, FNode.ChildNodes[AIndex]);
end;

function TVerySimpleXmlNode.GetChildCount: Integer;
begin
  if FNode = nil then
    Result := 0
  else
    Result := FNode.ChildNodes.Count;
end;

function TVerySimpleXmlNode.GetText: string;
begin
  if FNode = nil then
    Result := ''
  else
    Result := FNode.Text;
end;

function TVerySimpleXmlNode.GetAttribute(const AName: string): string;
begin
  if FNode = nil then
    Result := ''
  else
    Result := FNode.Attributes[AName];
end;

function TVerySimpleXmlNode.HasAttribute(const AName: string): Boolean;
begin
  if FNode = nil then
    Result := False
  else
    Result := FNode.AttributeList.HasAttribute(AName);
end;

function TVerySimpleXmlNode.GetLocalName: string;
begin
  if FNode = nil then
    Result := ''
  else
    Result := FNode.Name;
end;

function LoadONVIFXml(const AXml: string): IONVIFXmlDocument;
begin
  Result := TVerySimpleXmlDocument.Create(AXml);
end;

end.
