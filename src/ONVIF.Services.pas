unit ONVIF.Services;

{
  Backward-compatible facade. New code should use ONVIF.Device and ONVIF.Media directly.
}

interface

uses
  ONVIF.Types;

function ONVIFGetDeviceInformation(const Addr, UserName, Password: string): string;
function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: string;
  var DeviceInformation: TDeviceInformation): Boolean;
function PrepareGetDeviceInformationRequest(const UserName, Password: string): string;

function ONVIFGetProfiles(const Addr, UserName, Password: string): string;
function XMLProfilesToProfiles(const XMLProfiles: string; var Profiles: TProfiles): Boolean;
function PrepareGetProfilesRequest(const UserName, Password: string): string;

function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol,
  ProfileToken: string): string;
function XMLStreamUriToStreamUri(const XMLStreamUri: string; var StreamUri: TStreamUri): Boolean;
function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol,
  ProfileToken: string): string;

function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: string;
  var SnapshotUri: TSnapshotUri): Boolean;
function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;

implementation

uses
  ONVIF.Device,
  ONVIF.Media;

function PrepareGetDeviceInformationRequest(const UserName, Password: string): string;
begin
  Result := ONVIF.Device.PrepareGetDeviceInformationRequest(UserName, Password);
end;

function ONVIFGetDeviceInformation(const Addr, UserName, Password: string): string;
begin
  Result := ONVIF.Device.ONVIFGetDeviceInformation(Addr, UserName, Password);
end;

function XMLDeviceInformationToDeviceInformation(const XMLDeviceInformation: string;
  var DeviceInformation: TDeviceInformation): Boolean;
begin
  Result := ONVIF.Device.XMLDeviceInformationToDeviceInformation(XMLDeviceInformation, DeviceInformation);
end;

function PrepareGetProfilesRequest(const UserName, Password: string): string;
begin
  Result := ONVIF.Media.PrepareGetProfilesRequest(UserName, Password);
end;

function ONVIFGetProfiles(const Addr, UserName, Password: string): string;
begin
  Result := ONVIF.Media.ONVIFGetProfiles(Addr, UserName, Password);
end;

function XMLProfilesToProfiles(const XMLProfiles: string; var Profiles: TProfiles): Boolean;
begin
  Result := ONVIF.Media.XMLProfilesToProfiles(XMLProfiles, Profiles);
end;

function PrepareGetStreamUriRequest(const UserName, Password, Stream, Protocol,
  ProfileToken: string): string;
begin
  Result := ONVIF.Media.PrepareGetStreamUriRequest(UserName, Password, Stream, Protocol,
    ProfileToken, False);
end;

function ONVIFGetStreamUri(const Addr, UserName, Password, Stream, Protocol,
  ProfileToken: string): string;
begin
  Result := ONVIF.Media.ONVIFGetStreamUri(Addr, UserName, Password, Stream, Protocol,
    ProfileToken, False);
end;

function XMLStreamUriToStreamUri(const XMLStreamUri: string; var StreamUri: TStreamUri): Boolean;
begin
  Result := ONVIF.Media.XMLStreamUriToStreamUri(XMLStreamUri, StreamUri);
end;

function PrepareGetSnapshotUriRequest(const UserName, Password, ProfileToken: string): string;
begin
  Result := ONVIF.Media.PrepareGetSnapshotUriRequest(UserName, Password, ProfileToken);
end;

function ONVIFGetSnapshotUri(const Addr, UserName, Password, ProfileToken: string): string;
begin
  Result := ONVIF.Media.ONVIFGetSnapshotUri(Addr, UserName, Password, ProfileToken);
end;

function XMLSnapshotUriToSnapshotUri(const XMLSnapshotUri: string;
  var SnapshotUri: TSnapshotUri): Boolean;
begin
  Result := ONVIF.Media.XMLSnapshotUriToSnapshotUri(XMLSnapshotUri, SnapshotUri);
end;

end.
