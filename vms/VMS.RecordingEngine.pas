unit VMS.RecordingEngine;

{
  Server-side RTSP recording placeholder.
  Actual capture uses FFmpeg/OpenCV — integrate at application level.
}

interface

uses
  System.SysUtils,
  System.Classes;

type
  TVMSRecordingSession = record
    CameraId: string;
    StreamUri: string;
    OutputPath: string;
    Active: Boolean;
  end;

  TVMSRecordingEngine = class
  private
    FSessions: TArray<TVMSRecordingSession>;
  public
    function StartRecording(const CameraId, StreamUri, OutputPath: string): Boolean;
    function StopRecording(const CameraId: string): Boolean;
    function IsRecording(const CameraId: string): Boolean;
    property Sessions: TArray<TVMSRecordingSession> read FSessions;
  end;

implementation

function TVMSRecordingEngine.StartRecording(const CameraId, StreamUri, OutputPath: string): Boolean;
var
  S: TVMSRecordingSession;
  I: Integer;
begin
  Result := (CameraId <> '') and (StreamUri <> '') and (OutputPath <> '');
  if not Result then
    Exit;
  for I := 0 to High(FSessions) do
    if SameText(FSessions[I].CameraId, CameraId) then
      Exit(False);
  S.CameraId := CameraId;
  S.StreamUri := StreamUri;
  S.OutputPath := OutputPath;
  S.Active := True;
  SetLength(FSessions, Length(FSessions) + 1);
  FSessions[High(FSessions)] := S;
end;

function TVMSRecordingEngine.StopRecording(const CameraId: string): Boolean;
var
  I, J: Integer;
  NewSessions: TArray<TVMSRecordingSession>;
begin
  Result := False;
  J := 0;
  for I := 0 to High(FSessions) do
    if SameText(FSessions[I].CameraId, CameraId) then
      Result := True
    else
    begin
      SetLength(NewSessions, J + 1);
      NewSessions[J] := FSessions[I];
      Inc(J);
    end;
  FSessions := NewSessions;
end;

function TVMSRecordingEngine.IsRecording(const CameraId: string): Boolean;
var
  S: TVMSRecordingSession;
begin
  for S in FSessions do
    if SameText(S.CameraId, CameraId) and S.Active then
      Exit(True);
  Result := False;
end;

end.
