unit VMS.CameraRegistry;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  ONVIF.Types,
  ONVIF.Client;

type
  TVMSCameraRegistry = class
  private
    FEntries: TDictionary<string, TVMSCameraEntry>;
    FDevices: TDictionary<string, TONVIFDevice>;
    FLock: TCriticalSection;
    function MakeId(const XAddr: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function AddOrUpdate(const XAddr, UserName, Password: string): TVMSCameraEntry;
    function GetDevice(const CameraId: string): TONVIFDevice;
    function HealthCheck(const CameraId: string): Boolean;
    function GetAll: TVMSCameraEntries;
    procedure Remove(const CameraId: string);
  end;

implementation

function TVMSCameraRegistry.MakeId(const XAddr: string): string;
begin
  Result := XAddr.Trim.ToLower;
end;

constructor TVMSCameraRegistry.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FEntries := TDictionary<string, TVMSCameraEntry>.Create;
  FDevices := TDictionary<string, TONVIFDevice>.Create;
end;

destructor TVMSCameraRegistry.Destroy;
var
  D: TONVIFDevice;
begin
  for D in FDevices.Values do
    D.Free;
  FDevices.Free;
  FEntries.Free;
  FLock.Free;
  inherited;
end;

function TVMSCameraRegistry.AddOrUpdate(const XAddr, UserName, Password: string): TVMSCameraEntry;
var
  Id: string;
  Dev: TONVIFDevice;
  Entry: TVMSCameraEntry;
begin
  Id := MakeId(XAddr);
  FLock.Enter;
  try
    if not FDevices.TryGetValue(Id, Dev) then
    begin
      Dev := TONVIFDevice.Create;
      FDevices.Add(Id, Dev);
    end;
    Dev.Connect(XAddr, UserName, Password);
    Entry.Id := Id;
    Entry.XAddr := XAddr;
    Entry.UserName := UserName;
    Entry.Password := Password;
    Entry.Manufacturer := Dev.DeviceInfo.Manufacturer;
    Entry.Model := Dev.DeviceInfo.Model;
    Entry.LastSeen := Now;
    Entry.Online := Dev.Connected;
    Entry.Capabilities := Dev.Capabilities;
    FEntries.AddOrSetValue(Id, Entry);
    Result := Entry;
  finally
    FLock.Leave;
  end;
end;

function TVMSCameraRegistry.GetDevice(const CameraId: string): TONVIFDevice;
begin
  FLock.Enter;
  try
    if not FDevices.TryGetValue(CameraId, Result) then
      Result := nil;
  finally
    FLock.Leave;
  end;
end;

function TVMSCameraRegistry.HealthCheck(const CameraId: string): Boolean;
var
  Dev: TONVIFDevice;
  Entry: TVMSCameraEntry;
begin
  Result := False;
  FLock.Enter;
  try
    if not FDevices.TryGetValue(CameraId, Dev) then
      Exit;
    Result := Dev.HealthCheck;
    if FEntries.TryGetValue(CameraId, Entry) then
    begin
      Entry.LastSeen := Now;
      Entry.Online := Result;
      FEntries.AddOrSetValue(CameraId, Entry);
    end;
  finally
    FLock.Leave;
  end;
end;

function TVMSCameraRegistry.GetAll: TVMSCameraEntries;
begin
  FLock.Enter;
  try
    Result := FEntries.Values.ToArray;
  finally
    FLock.Leave;
  end;
end;

procedure TVMSCameraRegistry.Remove(const CameraId: string);
var
  Dev: TONVIFDevice;
begin
  FLock.Enter;
  try
    if FDevices.TryGetValue(CameraId, Dev) then
    begin
      Dev.Free;
      FDevices.Remove(CameraId);
    end;
    FEntries.Remove(CameraId);
  finally
    FLock.Leave;
  end;
end;

end.
