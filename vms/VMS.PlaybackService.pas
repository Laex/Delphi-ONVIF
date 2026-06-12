unit VMS.PlaybackService;

interface

uses
  System.SysUtils,
  ONVIF.Types,
  ONVIF.Client,
  ONVIF.Recording;

type
  TVMSPlaybackSource = (psLocalFile, psDeviceReplay);

  TVMSPlaybackRequest = record
    Source: TVMSPlaybackSource;
    CameraId: string;
    LocalFilePath: string;
    RecordingToken: string;
    StartTime: TDateTime;
    EndTime: TDateTime;
  end;

  TVMSPlaybackService = class
  public
  class function GetDeviceReplayUri(ADevice: TONVIFDevice; const RecordingToken: string;
      out StreamUri: TStreamUri): Boolean;
    class function ResolvePlaybackUri(const Request: TVMSPlaybackRequest;
      ADevice: TONVIFDevice): string;
  end;

implementation

class function TVMSPlaybackService.GetDeviceReplayUri(ADevice: TONVIFDevice;
  const RecordingToken: string; out StreamUri: TStreamUri): Boolean;
var
  Xml: string;
begin
  StreamUri := default(TStreamUri);
  if (ADevice = nil) or (ADevice.ReplayEndpoint = '') then
    Exit(False);
  Xml := ONVIFGetReplayUri(ADevice.ReplayEndpoint, ADevice.UserName, ADevice.Password,
    RecordingToken, 'RTP-Unicast', 'RTSP');
  Result := XMLReplayUriToStreamUri(Xml, StreamUri);
end;

class function TVMSPlaybackService.ResolvePlaybackUri(const Request: TVMSPlaybackRequest;
  ADevice: TONVIFDevice): string;
var
  Uri: TStreamUri;
begin
  case Request.Source of
    psLocalFile:
      Result := Request.LocalFilePath;
    psDeviceReplay:
      if GetDeviceReplayUri(ADevice, Request.RecordingToken, Uri) then
        Result := Uri.Uri
      else
        Result := '';
  else
    Result := '';
  end;
end;

end.
