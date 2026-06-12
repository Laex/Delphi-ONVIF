unit VMS.EventHub;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  ONVIF.Types,
  ONVIF.Client;

type
  TVMSAlarmNotify = procedure(const Event: TVMSAlarmEvent) of object;
  TVMSMonitoringErrorNotify = procedure(const CameraId, ErrorMessage: string) of object;

  TVMSCameraEventThread = class(TThread)
  private
    FCameraId: string;
    FDevice: TONVIFDevice;
    FSubscription: TONVIFSubscription;
    FOnAlarm: TVMSAlarmNotify;
    FOnMonitoringError: TVMSMonitoringErrorNotify;
    FPendingMsg: TONVIFEventMessage;
    procedure DoNotifyAlarm;
    procedure NotifyError(const Msg: string);
  protected
    procedure Execute; override;
    procedure NotifyAlarm(const Msg: TONVIFEventMessage);
  public
    constructor Create(const ACameraId: string; ADevice: TONVIFDevice;
      const AOnAlarm: TVMSAlarmNotify;
      const AOnMonitoringError: TVMSMonitoringErrorNotify = nil);
  end;

  TVMSEventHub = class
  private
    FThreads: TDictionary<string, TVMSCameraEventThread>;
    FOnAlarm: TVMSAlarmNotify;
    FOnMonitoringError: TVMSMonitoringErrorNotify;
  public
    constructor Create(const AOnAlarm: TVMSAlarmNotify;
      const AOnMonitoringError: TVMSMonitoringErrorNotify = nil);
    destructor Destroy; override;
    procedure StartMonitoring(const CameraId: string; ADevice: TONVIFDevice);
    procedure StopMonitoring(const CameraId: string);
    procedure StopAll;
  end;

implementation

uses
  ONVIF.Events;

procedure TVMSCameraEventThread.DoNotifyAlarm;
begin
  NotifyAlarm(FPendingMsg);
end;

procedure TVMSCameraEventThread.NotifyError(const Msg: string);
begin
  if Assigned(FOnMonitoringError) then
    FOnMonitoringError(FCameraId, Msg);
end;

constructor TVMSCameraEventThread.Create(const ACameraId: string; ADevice: TONVIFDevice;
  const AOnAlarm: TVMSAlarmNotify; const AOnMonitoringError: TVMSMonitoringErrorNotify);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCameraId := ACameraId;
  FDevice := ADevice;
  FOnAlarm := AOnAlarm;
  FOnMonitoringError := AOnMonitoringError;
end;

procedure TVMSCameraEventThread.NotifyAlarm(const Msg: TONVIFEventMessage);
var
  E: TVMSAlarmEvent;
begin
  if not Assigned(FOnAlarm) then
    Exit;
  E.CameraId := FCameraId;
  E.Topic := Msg.Topic;
  E.Timestamp := Msg.UtcTime;
  E.Payload := Msg.Data;
  E.Source := Msg.Source;
  FOnAlarm(E);
end;

procedure TVMSCameraEventThread.Execute;
var
  Messages: TONVIFEventMessages;
  M: TONVIFEventMessage;
  RenewCounter: Integer;
  RenewResult: TONVIFRequestResult;
begin
  if not FDevice.CreateEventSubscription(FSubscription) then
  begin
    NotifyError('CreateEventSubscription failed');
    Exit;
  end;
  RenewCounter := 0;
  while not Terminated do
  begin
    Inc(RenewCounter);
    if RenewCounter mod 12 = 0 then
    begin
      RenewResult := ONVIFRenewSubscription(FSubscription.Reference, FDevice.UserName,
        FDevice.Password, 'PT60S');
      if not RenewResult.Success then
      begin
        NotifyError('Renew subscription failed: ' + RenewResult.ErrorMessage);
        Break;
      end;
    end;
    if FDevice.PullEvents(FSubscription.Reference, Messages) then
      for M in Messages do
      begin
        FPendingMsg := M;
        Synchronize(DoNotifyAlarm);
      end
    else
      Sleep(1000);
  end;
  if FSubscription.Reference <> '' then
    ONVIFUnsubscribe(FSubscription.Reference, FDevice.UserName, FDevice.Password);
end;

constructor TVMSEventHub.Create(const AOnAlarm: TVMSAlarmNotify;
  const AOnMonitoringError: TVMSMonitoringErrorNotify);
begin
  inherited Create;
  FOnAlarm := AOnAlarm;
  FOnMonitoringError := AOnMonitoringError;
  FThreads := TDictionary<string, TVMSCameraEventThread>.Create;
end;

destructor TVMSEventHub.Destroy;
begin
  StopAll;
  FThreads.Free;
  inherited;
end;

procedure TVMSEventHub.StartMonitoring(const CameraId: string; ADevice: TONVIFDevice);
var
  T: TVMSCameraEventThread;
begin
  StopMonitoring(CameraId);
  T := TVMSCameraEventThread.Create(CameraId, ADevice, FOnAlarm, FOnMonitoringError);
  FThreads.Add(CameraId, T);
  T.Start;
end;

procedure TVMSEventHub.StopMonitoring(const CameraId: string);
var
  T: TVMSCameraEventThread;
begin
  if FThreads.TryGetValue(CameraId, T) then
  begin
    T.Terminate;
    T.WaitFor;
    T.Free;
    FThreads.Remove(CameraId);
  end;
end;

procedure TVMSEventHub.StopAll;
var
  Id: string;
begin
  for Id in FThreads.Keys.ToArray do
    StopMonitoring(Id);
end;

end.
