unit ONVIF.Events;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_EVENTS = 'xmlns:tev="http://www.onvif.org/ver10/events/wsdl"';
  ONVIF_NS_WSNT = 'xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2"';
  ONVIF_NS_WSA = 'xmlns:wsa="http://www.w3.org/2005/08/addressing"';

function PrepareGetEventPropertiesRequest(const UserName, Password: string): string;
function ONVIFGetEventProperties(const Addr, UserName, Password: string): string;
function XMLEventPropertiesToProperties(const AXml: string; var Properties: TONVIFEventProperties): Boolean;

function PrepareCreatePullPointSubscriptionRequest(const UserName, Password: string;
  InitialTerminationTime: string = 'PT60S'): string;
function ONVIFCreatePullPointSubscription(const Addr, UserName, Password: string;
  InitialTerminationTime: string = 'PT60S'): string;
function XMLPullPointSubscriptionToSubscription(const AXml: string;
  var Subscription: TONVIFSubscription): Boolean;

function PreparePullMessagesRequest(const SubscriptionAddr, UserName, Password: string;
  Timeout: string; MessageLimit: Integer): string;
function ONVIFPullMessages(const SubscriptionAddr, UserName, Password: string;
  Timeout: string = 'PT5S'; MessageLimit: Integer = 10): string;
function XMLPullMessagesToMessages(const AXml: string; var Messages: TONVIFEventMessages): Boolean;

function PrepareRenewRequest(const SubscriptionAddr, UserName, Password: string;
  TerminationTime: string): string;
function ONVIFRenewSubscription(const SubscriptionAddr, UserName, Password: string;
  TerminationTime: string = 'PT60S'): TONVIFRequestResult;

function PrepareUnsubscribeRequest(const SubscriptionAddr, UserName, Password: string): string;
function ONVIFUnsubscribe(const SubscriptionAddr, UserName, Password: string): TONVIFRequestResult;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  ONVIF.Core,
  ONVIF.Xml;

function PrepareGetEventPropertiesRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_EVENTS,
    '<tev:GetEventProperties/>', UserName, Password);
end;

function ONVIFGetEventProperties(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetEventPropertiesRequest(UserName, Password), Result);
end;

procedure CollectTopicNames(const Node: IONVIFXmlNode; var Properties: TONVIFEventProperties);
var
  I: Integer;
  Child: IONVIFXmlNode;
  P: TONVIFEventProperty;
  TopicText: string;
begin
  if Node = nil then
    Exit;
  for I := 0 to Node.ChildCount - 1 do
  begin
    Child := Node.Children[I];
    if Child.ChildCount > 0 then
      CollectTopicNames(Child, Properties)
    else
    begin
      TopicText := Trim(Child.Text);
      if TopicText <> '' then
      begin
        P.Name := TopicText;
        SetLength(Properties, Length(Properties) + 1);
        Properties[High(Properties)] := P;
      end;
    end;
  end;
end;

function XMLEventPropertiesToProperties(const AXml: string;
  var Properties: TONVIFEventProperties): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, TopicSet: IONVIFXmlNode;
begin
  SetLength(Properties, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetEventPropertiesResponse');
  if Response = nil then
    Exit;
  TopicSet := Response.FindChild('TopicSet');
  if TopicSet <> nil then
    CollectTopicNames(TopicSet, Properties);
  Result := True;
end;

function PrepareCreatePullPointSubscriptionRequest(const UserName, Password: string;
  InitialTerminationTime: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_EVENTS + ' ' + ONVIF_NS_WSNT,
    Format('<tev:CreatePullPointSubscription><wsnt:InitialTerminationTime>%s</wsnt:InitialTerminationTime>' +
    '</tev:CreatePullPointSubscription>', [InitialTerminationTime]), UserName, Password);
end;

function ONVIFCreatePullPointSubscription(const Addr, UserName, Password: string;
  InitialTerminationTime: string): string;
begin
  ONVIFRequest(Addr, PrepareCreatePullPointSubscriptionRequest(UserName, Password,
    InitialTerminationTime), Result);
end;

function XMLPullPointSubscriptionToSubscription(const AXml: string;
  var Subscription: TONVIFSubscription): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Ref: IONVIFXmlNode;
begin
  Subscription := default(TONVIFSubscription);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('CreatePullPointSubscriptionResponse');
  if Response = nil then
    Exit;
  Ref := Response.FindChild('SubscriptionReference');
  if Ref <> nil then
    Subscription.Reference := Ref.FindChild('Address').Text;
  Subscription.TerminationTime := ISO8601ToDate(Response.FindChild('TerminationTime').Text, False);
  Result := Subscription.Reference <> '';
end;

function PreparePullMessagesRequest(const SubscriptionAddr, UserName, Password: string;
  Timeout: string; MessageLimit: Integer): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_EVENTS + ' ' + ONVIF_NS_WSNT,
    Format('<tev:PullMessages><tev:Timeout>%s</tev:Timeout><tev:MessageLimit>%d</tev:MessageLimit></tev:PullMessages>',
      [Timeout, MessageLimit]), UserName, Password);
end;

function ONVIFPullMessages(const SubscriptionAddr, UserName, Password: string;
  Timeout: string; MessageLimit: Integer): string;
begin
  ONVIFRequest(SubscriptionAddr, PreparePullMessagesRequest(SubscriptionAddr, UserName, Password,
    Timeout, MessageLimit), Result);
end;

function SimpleItemsToText(const Node: IONVIFXmlNode): string;
var
  I: Integer;
  Child: IONVIFXmlNode;
  Parts: TArray<string>;
  Name, Value: string;
begin
  Result := '';
  if Node = nil then
    Exit;
  for I := 0 to Node.ChildCount - 1 do
  begin
    Child := Node.Children[I];
    if not SameText(Child.LocalName, 'SimpleItem') then
      Continue;
    Name := Child.Attr['Name'];
    Value := Child.Attr['Value'];
    if Name <> '' then
      Parts := Parts + [Name + '=' + Value];
  end;
  if Length(Parts) > 0 then
  begin
    Result := Parts[0];
    for I := 1 to High(Parts) do
      Result := Result + '; ' + Parts[I];
  end
  else
    Result := Trim(Node.Text);
end;

function XMLPullMessagesToMessages(const AXml: string; var Messages: TONVIFEventMessages): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node, Topic, Data, SourceNode, DataNode, UtcNode: IONVIFXmlNode;
  I: Integer;
  M: TONVIFEventMessage;
begin
  SetLength(Messages, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('PullMessagesResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'NotificationMessage') then
      Continue;
    M := default(TONVIFEventMessage);
    Topic := Node.FindChild('Topic');
    if Topic <> nil then
      M.Topic := Topic.Text;
    Data := Node.FindChild('Message');
    if Data <> nil then
    begin
      SourceNode := Data.FindChild('Source');
      if SourceNode <> nil then
        M.Source := SimpleItemsToText(SourceNode);
      DataNode := Data.FindChild('Data');
      if DataNode <> nil then
        M.Data := SimpleItemsToText(DataNode);
      if Data.Attr['PropertyOperation'] <> '' then
        M.PropertyOperation := Data.Attr['PropertyOperation']
      else
      begin
        SourceNode := Data.FindChild('PropertyOperation');
        if SourceNode <> nil then
          M.PropertyOperation := SourceNode.Text;
      end;
      UtcNode := Data.FindChild('UtcTime');
      if UtcNode <> nil then
        M.UtcTime := ISO8601ToDate(UtcNode.Text, False)
      else if Data.Attr['UtcTime'] <> '' then
        M.UtcTime := ISO8601ToDate(Data.Attr['UtcTime'], False);
    end;
    SetLength(Messages, Length(Messages) + 1);
    Messages[High(Messages)] := M;
    Result := True;
  end;
end;

function PrepareRenewRequest(const SubscriptionAddr, UserName, Password: string;
  TerminationTime: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_WSNT,
    Format('<wsnt:Renew><wsnt:TerminationTime>%s</wsnt:TerminationTime></wsnt:Renew>',
      [TerminationTime]), UserName, Password);
end;

function ONVIFRenewSubscription(const SubscriptionAddr, UserName, Password: string;
  TerminationTime: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(SubscriptionAddr, ONVIF_NS_WSNT,
    Format('<wsnt:Renew><wsnt:TerminationTime>%s</wsnt:TerminationTime></wsnt:Renew>',
      [TerminationTime]), UserName, Password);
end;

function PrepareUnsubscribeRequest(const SubscriptionAddr, UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_WSNT,
    '<wsnt:Unsubscribe/>', UserName, Password);
end;

function ONVIFUnsubscribe(const SubscriptionAddr, UserName, Password: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(SubscriptionAddr, ONVIF_NS_WSNT,
    '<wsnt:Unsubscribe/>', UserName, Password);
end;

end.
