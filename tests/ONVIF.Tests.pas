unit ONVIF.Tests;

{
  Manual regression helpers — run from a test host project or IDE snippet.
  Validates XML parsers against tests/fixtures/*.xml
}

interface

procedure RunONVIFParserTests;

implementation

uses
  System.SysUtils,
  System.Classes,
  ONVIF.Device,
  ONVIF.Media,
  ONVIF.Media2,
  ONVIF.Recording,
  ONVIF.Types;

function FixturePath(const AName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '..\tests\fixtures\' + AName;
end;

function LoadFixture(const AName: string): string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FixturePath(AName));
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure RunONVIFParserTests;
var
  Info: TDeviceInformation;
  Caps: TONVIFCapabilities;
  Profiles: TProfiles;
  Results: TONVIFRecordingSearchResults;
  Snapshot: TSnapshotUri;
begin
  if not XMLDeviceInformationToDeviceInformation(
    LoadFixture('GetDeviceInformationResponse.xml'), Info) then
    raise Exception.Create('GetDeviceInformation parser failed');
  if Info.Manufacturer <> 'TestManufacturer' then
    raise Exception.Create('Manufacturer mismatch');
  if not XMLServicesToCapabilities(LoadFixture('GetServicesResponse.xml'),
    'http://192.168.1.100/onvif/device_service', Caps) then
    raise Exception.Create('GetServices parser failed');
  if not Caps.HasService(stMedia) then
    raise Exception.Create('Media service not found');
  if not Caps.HasService(stMedia2) then
    raise Exception.Create('Media2 service not found');
  if not XMLMedia2ProfilesToProfiles(LoadFixture('GetMedia2ProfilesResponse.xml'), Profiles) then
    raise Exception.Create('Media2 profiles parser failed');
  if not XMLMedia2SnapshotUriToSnapshotUri(LoadFixture('GetMedia2SnapshotUriResponse.xml'), Snapshot) then
    raise Exception.Create('Media2 snapshot parser failed');
  if Snapshot.Uri <> 'http://192.168.1.100/snapshot.jpg' then
    raise Exception.Create('Media2 snapshot URI mismatch');
  if not XMLRecordingSearchResultsToResults(LoadFixture('GetRecordingSearchResultsResponse.xml'),
    Results) then
    raise Exception.Create('Recording search results parser failed');
  if Length(Results) <> 1 then
    raise Exception.Create('Recording search result count mismatch');
  if Results[0].RecordingToken <> 'rec001' then
    raise Exception.Create('Recording token mismatch');
  if not XMLRecordingSearchResultsCompleted(LoadFixture('GetRecordingSearchResultsResponse.xml')) then
    raise Exception.Create('Recording search state parser failed');
end;

end.
