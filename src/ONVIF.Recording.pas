unit ONVIF.Recording;

interface

uses
  ONVIF.Types;

const
  ONVIF_NS_RECORDING = 'xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"';
  ONVIF_NS_SEARCH = 'xmlns:tse="http://www.onvif.org/ver10/search/wsdl"';
  ONVIF_NS_REPLAY = 'xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"';
  ONVIF_NS_REPLAY_SCHEMA = 'xmlns:tt="http://www.onvif.org/ver10/schema"';

function PrepareGetRecordingsRequest(const UserName, Password: string): string;
function ONVIFGetRecordings(const Addr, UserName, Password: string): string;
function XMLRecordingsToRecordings(const AXml: string; var Recordings: TONVIFRecordings): Boolean;

function PrepareGetRecordingSummaryRequest(const UserName, Password: string): string;
function ONVIFGetRecordingSummary(const Addr, UserName, Password: string): string;
function XMLRecordingSummaryToSummary(const AXml: string; var Summary: TONVIFRecordingSummary): Boolean;

function PrepareFindRecordingsRequest(const UserName, Password: string;
  StartTime, EndTime: TDateTime; MaxMatches: Integer): string;
function ONVIFFindRecordings(const SearchAddr, UserName, Password: string;
  StartTime, EndTime: TDateTime; MaxMatches: Integer = 100): string;
function XMLFindRecordingsToSearchToken(const AXml: string; out SearchToken: string): Boolean;

function PrepareGetRecordingSearchResultsRequest(const UserName, Password, SearchToken: string;
  MinResults, MaxResults: Integer; WaitTime: string): string;
function ONVIFGetRecordingSearchResults(const SearchAddr, UserName, Password, SearchToken: string;
  MinResults, MaxResults: Integer; WaitTime: string = 'PT5S'): string;
function XMLRecordingSearchResultsToResults(const AXml: string;
  var Results: TONVIFRecordingSearchResults): Boolean;
function XMLRecordingSearchResultsCompleted(const AXml: string): Boolean;

function PrepareEndSearchRequest(const UserName, Password, SearchToken: string): string;
function ONVIFEndSearch(const SearchAddr, UserName, Password, SearchToken: string): TONVIFRequestResult;

function ONVIFFindRecordingsInRange(const SearchAddr, UserName, Password: string;
  StartTime, EndTime: TDateTime; MaxMatches: Integer;
  out Results: TONVIFRecordingSearchResults): Boolean;

function PrepareGetReplayUriRequest(const UserName, Password, RecordingToken, Stream,
  Protocol: string): string;
function ONVIFGetReplayUri(const ReplayAddr, UserName, Password, RecordingToken,
  Stream, Protocol: string): string;
function XMLReplayUriToStreamUri(const AXml: string; var StreamUri: TStreamUri): Boolean;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  ONVIF.Core,
  ONVIF.Xml;

function DateTimeToONVIF(const ADateTime: TDateTime): string;
begin
  Result := GetONVIFDateTime(ADateTime);
end;

function PrepareGetRecordingsRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_RECORDING,
    '<trc:GetRecordings/>', UserName, Password);
end;

function ONVIFGetRecordings(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetRecordingsRequest(UserName, Password), Result);
end;

function XMLRecordingsToRecordings(const AXml: string; var Recordings: TONVIFRecordings): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
  I: Integer;
  R: TONVIFRecording;
begin
  SetLength(Recordings, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetRecordingsResponse');
  if Response = nil then
    Exit;
  for I := 0 to Response.ChildCount - 1 do
  begin
    Node := Response.Children[I];
    if not SameText(Node.LocalName, 'RecordingItem') then
      Continue;
    R.token := Node.FindChild('RecordingToken').Text;
    R.Configuration := Node.FindChild('Configuration').Text;
    SetLength(Recordings, Length(Recordings) + 1);
    Recordings[High(Recordings)] := R;
  end;
  Result := True;
end;

function PrepareGetRecordingSummaryRequest(const UserName, Password: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_RECORDING,
    '<trc:GetRecordingSummary/>', UserName, Password);
end;

function ONVIFGetRecordingSummary(const Addr, UserName, Password: string): string;
begin
  ONVIFRequest(Addr, PrepareGetRecordingSummaryRequest(UserName, Password), Result);
end;

function XMLRecordingSummaryToSummary(const AXml: string; var Summary: TONVIFRecordingSummary): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, SummaryNode: IONVIFXmlNode;
begin
  Summary := default(TONVIFRecordingSummary);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetRecordingSummaryResponse');
  if Response = nil then
    Exit;
  SummaryNode := Response.FindChild('Summary');
  if SummaryNode = nil then
    Exit;
  Summary.DataFrom := ISO8601ToDate(SummaryNode.FindChild('DataFrom').Text, False);
  Summary.DataUntil := ISO8601ToDate(SummaryNode.FindChild('DataUntil').Text, False);
  Summary.NumberRecordings := SummaryNode.FindChild('NumberRecordings').Text.ToInteger;
  Result := True;
end;

function PrepareFindRecordingsRequest(const UserName, Password: string;
  StartTime, EndTime: TDateTime; MaxMatches: Integer): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_SEARCH,
    Format('<tse:FindRecordings><tse:Scope><tse:RecordingInformationFilter>' +
    '<tse:StartPoint>%s</tse:StartPoint><tse:EndPoint>%s</tse:EndPoint>' +
    '</tse:RecordingInformationFilter></tse:Scope>' +
    '<tse:MaxMatches>%d</tse:MaxMatches><tse:KeepAliveTime>PT60S</tse:KeepAliveTime></tse:FindRecordings>',
    [DateTimeToONVIF(StartTime), DateTimeToONVIF(EndTime), MaxMatches]),
    UserName, Password);
end;

function ONVIFFindRecordings(const SearchAddr, UserName, Password: string;
  StartTime, EndTime: TDateTime; MaxMatches: Integer): string;
begin
  ONVIFRequest(SearchAddr, PrepareFindRecordingsRequest(UserName, Password,
    StartTime, EndTime, MaxMatches), Result);
end;

function XMLFindRecordingsToSearchToken(const AXml: string; out SearchToken: string): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, Node: IONVIFXmlNode;
begin
  SearchToken := '';
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('FindRecordingsResponse');
  if Response = nil then
    Exit;
  Node := Response.FindChild('SearchToken');
  if Node = nil then
    Exit;
  SearchToken := Node.Text;
  Result := SearchToken <> '';
end;

function PrepareGetRecordingSearchResultsRequest(const UserName, Password, SearchToken: string;
  MinResults, MaxResults: Integer; WaitTime: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_SEARCH,
    Format('<tse:GetRecordingSearchResults><tse:SearchToken>%s</tse:SearchToken>' +
    '<tse:MinResults>%d</tse:MinResults><tse:MaxResults>%d</tse:MaxResults>' +
    '<tse:WaitTime>%s</tse:WaitTime></tse:GetRecordingSearchResults>',
    [SearchToken, MinResults, MaxResults, WaitTime]),
    UserName, Password);
end;

function ONVIFGetRecordingSearchResults(const SearchAddr, UserName, Password, SearchToken: string;
  MinResults, MaxResults: Integer; WaitTime: string): string;
begin
  ONVIFRequest(SearchAddr, PrepareGetRecordingSearchResultsRequest(UserName, Password,
    SearchToken, MinResults, MaxResults, WaitTime), Result);
end;

procedure AppendRecordingInformation(const InfoNode: IONVIFXmlNode;
  var Results: TONVIFRecordingSearchResults);
var
  R: TONVIFRecordingSearchResult;
  StartNode, EndNode: IONVIFXmlNode;
begin
  if InfoNode = nil then
    Exit;
  R.RecordingToken := InfoNode.FindChild('RecordingToken').Text;
  R.TrackToken := InfoNode.FindChild('TrackToken').Text;
  StartNode := InfoNode.FindChild('EarliestRecording');
  if StartNode = nil then
    StartNode := InfoNode.FindChild('StartTime');
  EndNode := InfoNode.FindChild('LatestRecording');
  if EndNode = nil then
    EndNode := InfoNode.FindChild('EndTime');
  if StartNode <> nil then
    R.TimeSpanStart := ISO8601ToDate(StartNode.Text, False);
  if EndNode <> nil then
    R.TimeSpanEnd := ISO8601ToDate(EndNode.Text, False);
  SetLength(Results, Length(Results) + 1);
  Results[High(Results)] := R;
end;

procedure CollectRecordingInformation(const Container: IONVIFXmlNode;
  var Results: TONVIFRecordingSearchResults);
var
  I: Integer;
  Node: IONVIFXmlNode;
begin
  if Container = nil then
    Exit;
  for I := 0 to Container.ChildCount - 1 do
  begin
    Node := Container.Children[I];
    if SameText(Node.LocalName, 'RecordingInformation') then
      AppendRecordingInformation(Node, Results)
    else if SameText(Node.LocalName, 'ResultList') then
      CollectRecordingInformation(Node, Results);
  end;
end;

function XMLRecordingSearchResultsToResults(const AXml: string;
  var Results: TONVIFRecordingSearchResults): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response: IONVIFXmlNode;
begin
  SetLength(Results, 0);
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetRecordingSearchResultsResponse');
  if Response = nil then
    Exit;
  CollectRecordingInformation(Response, Results);
  Result := True;
end;

function XMLRecordingSearchResultsCompleted(const AXml: string): Boolean;
var
  Doc: IONVIFXmlDocument;
  Body, Response, StateNode: IONVIFXmlNode;
  State: string;
begin
  Result := False;
  Doc := LoadONVIFXml(AXml);
  Body := Doc.SoapBody;
  if Body = nil then
    Exit;
  Response := Body.FindChild('GetRecordingSearchResultsResponse');
  if Response = nil then
    Exit;
  StateNode := Response.FindChild('SearchState');
  if StateNode = nil then
    Exit(True);
  State := Trim(StateNode.Text);
  Result := SameText(State, 'Completed') or SameText(State, 'Complete');
end;

function PrepareEndSearchRequest(const UserName, Password, SearchToken: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_SEARCH,
    Format('<tse:EndSearch><tse:SearchToken>%s</tse:SearchToken></tse:EndSearch>',
      [SearchToken]), UserName, Password);
end;

function ONVIFEndSearch(const SearchAddr, UserName, Password, SearchToken: string): TONVIFRequestResult;
begin
  Result := ExecuteSoapRequest(SearchAddr, ONVIF_NS_SEARCH,
    Format('<tse:EndSearch><tse:SearchToken>%s</tse:SearchToken></tse:EndSearch>',
      [SearchToken]), UserName, Password);
end;

function ONVIFFindRecordingsInRange(const SearchAddr, UserName, Password: string;
  StartTime, EndTime: TDateTime; MaxMatches: Integer;
  out Results: TONVIFRecordingSearchResults): Boolean;
const
  MaxSearchPolls = 12;
var
  Xml, SearchToken: string;
  Poll: Integer;
  PollResults: TONVIFRecordingSearchResults;
begin
  SetLength(Results, 0);
  Xml := ONVIFFindRecordings(SearchAddr, UserName, Password, StartTime, EndTime, MaxMatches);
  if SoapHasFault(Xml) or not XMLFindRecordingsToSearchToken(Xml, SearchToken) then
    Exit(False);
  Result := False;
  try
    for Poll := 1 to MaxSearchPolls do
    begin
      Xml := ONVIFGetRecordingSearchResults(SearchAddr, UserName, Password, SearchToken,
        1, MaxMatches, 'PT5S');
      if SoapHasFault(Xml) then
        Exit;
      if not XMLRecordingSearchResultsToResults(Xml, PollResults) then
        Exit;
      Results := PollResults;
      if XMLRecordingSearchResultsCompleted(Xml) or (Length(Results) > 0) then
      begin
        Result := True;
        Break;
      end;
    end;
  finally
    ONVIFEndSearch(SearchAddr, UserName, Password, SearchToken);
  end;
end;

function PrepareGetReplayUriRequest(const UserName, Password, RecordingToken, Stream,
  Protocol: string): string;
begin
  Result := BuildAuthenticatedSoapEnvelope(ONVIF_NS_REPLAY + ' ' + ONVIF_NS_REPLAY_SCHEMA,
    Format('<trp:GetReplayUri><trp:StreamSetup><tt:Stream>%s</tt:Stream>' +
    '<tt:Transport><tt:Protocol>%s</tt:Protocol></tt:Transport></trp:StreamSetup>' +
    '<trp:RecordingToken>%s</trp:RecordingToken></trp:GetReplayUri>',
    [Stream, Protocol, RecordingToken]), UserName, Password);
end;

function ONVIFGetReplayUri(const ReplayAddr, UserName, Password, RecordingToken,
  Stream, Protocol: string): string;
begin
  ONVIFRequest(ReplayAddr, PrepareGetReplayUriRequest(UserName, Password, RecordingToken,
    Stream, Protocol), Result);
end;

function XMLReplayUriToStreamUri(const AXml: string; var StreamUri: TStreamUri): Boolean;
begin
  Result := ParseMediaUriResponse(AXml, 'GetReplayUriResponse', StreamUri);
end;

end.
